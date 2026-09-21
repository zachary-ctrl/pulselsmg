import OpenAI from "openai";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
  });
}

function fallbackAnswer(prompt: string, context: any) {
  const q = prompt.toLowerCase();
  const markets = Array.isArray(context?.markets) ? context.markets : [];
  const news = Array.isArray(context?.news) ? context.news : [];
  const words = q.split(/\W+/).filter((w) => w.length > 3);
  const marketMatches = markets
    .map((m: any) => ({ ...m, score: words.filter((w) => String(m.title || "").toLowerCase().includes(w)).length }))
    .filter((m: any) => m.score > 0)
    .sort((a: any, b: any) => b.score - a.score)
    .slice(0, 3);
  const newsMatches = news
    .map((n: any) => ({ ...n, score: words.filter((w) => String(n.title || "").toLowerCase().includes(w)).length }))
    .filter((n: any) => n.score > 0)
    .sort((a: any, b: any) => b.score - a.score)
    .slice(0, 3);

  if (marketMatches.length) {
    const lines = marketMatches.map((m: any) =>
      String(m.source || "MARKET") + " currently shows " + Number(m.yes || 0) + "% YES on “" + String(m.title || "") + ".”"
    );
    return lines.join(" ") + " Treat market prices as changing crowd signals, not certainty.";
  }
  if (newsMatches.length) {
    return "The closest live headlines are: " + newsMatches.map((n: any) => String(n.title || "")).join(" · ") + ".";
  }
  return "PULSE Signal is online and tracking live culture headlines plus public prediction-market prices. Ask about a show, artist, film, fashion trend, wrestling story, or one of the markets on screen.";
}

export default async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: any = {};
  try { body = await req.json(); } catch {}
  const prompt = String(body.prompt || "").trim().slice(0, 1600);
  const context = body.context || {};
  if (!prompt) return json({ error: "missing_prompt" }, 400);

  const safeContext = JSON.stringify({
    markets: Array.isArray(context.markets) ? context.markets.slice(0, 12) : [],
    news: Array.isArray(context.news) ? context.news.slice(0, 12) : []
  }).slice(0, 12000);

  try {
    const client = new OpenAI();
    const response = await client.responses.create({
      model: "gpt-5",
      store: false,
      max_output_tokens: 450,
      instructions:
        "You are PULSE AI inside an LSMG x LEDGERA culture app. Be concise, energetic, and factual. Use the supplied live context when relevant. Clearly distinguish public prediction-market prices from facts or forecasts. Never tell users what cash wager to place, never promise profit, and never imply a crowd price guarantees an outcome. For politics or elections, stay neutral and factual and do not recommend candidates or outcomes.",
      input: "LIVE CONTEXT:\n" + safeContext + "\n\nUSER:\n" + prompt
    });

    return json({
      mode: "ai",
      connected: true,
      answer: response.output_text || fallbackAnswer(prompt, context)
    });
  } catch (error) {
    return json({
      mode: "signal",
      connected: false,
      answer: fallbackAnswer(prompt, context)
    });
  }
};

export const config = {
  path: "/api/ai"
};
