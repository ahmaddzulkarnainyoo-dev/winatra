const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const { defineSecret } = require("firebase-functions/params");

admin.initializeApp();

const DEEPSEEK_API_KEY = defineSecret("DEEPSEEK_API_KEY");

async function callDeepSeek(prompt, apiKey, maxTokens = 500) {
  const res = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      messages: [{ role: "user", content: prompt }],
      max_tokens: maxTokens,
    }),
  });
  const data = await res.json();
  return data.choices?.[0]?.message?.content ?? "";
}

exports.askWinatra = functions.https.onCall(
  { secrets: [DEEPSEEK_API_KEY] },
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
    }

    const { prompt, seriousMode } = data;
    if (!prompt) throw new functions.https.HttpsError("invalid-argument", "Prompt kosong.");

    const apiKey = DEEPSEEK_API_KEY.value();
    const firstAnswer = await callDeepSeek(prompt, apiKey);

    if (!seriousMode) {
      return { answer: firstAnswer, verified: false };
    }

    // Mode serius: generate lagi buat cross-check jawaban pertama
    const verifyPrompt = `Soal: ${prompt}\n\nJawaban kandidat: ${firstAnswer}\n\nPeriksa apakah jawaban ini benar. Kalau salah, kasih jawaban yang benar. Jawab singkat: "BENAR" atau "SALAH, jawaban benar: ..."`;
    const verification = await callDeepSeek(verifyPrompt, apiKey, 300);

    const isCorrect = verification.trim().toUpperCase().startsWith("BENAR");
    return {
      answer: isCorrect ? firstAnswer : verification,
      verified: true,
    };
  }
);

/**
 * Server-side referral logic.
 * Client tidak bisa menulis dokumen user lain karena Firestore rules,
 * jadi fungsi ini pakai admin SDK (bypass rules) untuk update field
 * 'referralSuccessCount' dan 'dailyQuota' milik inviter.
 */
exports.applyReferral = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
  }

  const { inviterUid } = data;
  if (!inviterUid) {
    throw new functions.https.HttpsError("invalid-argument", "inviterUid required.");
  }

  const db = admin.firestore();
  const inviterRef = db.collection("users").doc(inviterUid);

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(inviterRef);
      if (!snap.exists) return;

      const currentCount = (snap.data()?.referralSuccessCount ?? 0);
      const newCount = currentCount + 1;
      const updates = { referralSuccessCount: newCount };

      // Setiap 3 referral sukses, inviter dapat bonus 10 kuota
      if (newCount % 3 === 0) {
        const currentQuota = (snap.data()?.dailyQuota ?? 0);
        updates.dailyQuota = currentQuota + 10; // WinatraUser.referralInviterBonus == 10
      }

      tx.update(inviterRef, updates);
    });

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});