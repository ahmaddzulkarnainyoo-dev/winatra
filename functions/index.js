const functions = require("firebase-functions");
const fetch = require("node-fetch");
const { defineSecret } = require("firebase-functions/params");

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