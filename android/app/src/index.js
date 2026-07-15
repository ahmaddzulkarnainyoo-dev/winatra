export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const { prompt, seriousMode } = await request.json();
    if (!prompt) return new Response("Prompt kosong", { status: 400 });

    const callDeepSeek = async (msg, maxTokens = 500) => {
      const res = await fetch("https://api.deepseek.com/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.DEEPSEEK_API_KEY}`,
        },
        body: JSON.stringify({
          model: "deepseek-chat",
          messages: [{ role: "user", content: msg }],
          max_tokens: maxTokens,
        }),
      });
      const data = await res.json();
      return data.choices?.[0]?.message?.content ?? "";
    };

    const firstAnswer = await callDeepSeek(prompt);
    if (!seriousMode) {
      return Response.json({ answer: firstAnswer, verified: false });
    }

    const verifyPrompt = `Soal: ${prompt}\n\nJawaban kandidat: ${firstAnswer}\n\nPeriksa benar/salah. Kalau salah kasih jawaban benar. Jawab: "BENAR" atau "SALAH, jawaban benar: ..."`;
    const verification = await callDeepSeek(verifyPrompt, 300);
    const isCorrect = verification.trim().toUpperCase().startsWith("BENAR");

    return Response.json({
      answer: isCorrect ? firstAnswer : verification,
      verified: true,
    });
  },
};