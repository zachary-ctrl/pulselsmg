function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "public, max-age=30, s-maxage=45, stale-while-revalidate=120"
    }
  });
}

const cultureTerms = [
  "movie","film","box office","oscar","academy award","grammy","emmy","album","song","music",
  "artist","singer","rapper","concert","tour","billboard","spotify","netflix","hbo","disney","marvel",
  "celebrity","actor","actress","television","tv show","streaming","fashion","runway","designer",
  "wrestling","wwe","aew","tna","youtube","tiktok","creator","influencer","award show"
];

const blockedTerms = [
  "election","president","senate","congress","parliament","minister","governor","mayor","trump",
  "biden","democrat","republican","russia","ukraine","israel","iran","china","war","ceasefire"
];

function isCulture(text: string) {
  const t = (text || "").toLowerCase();
  return cultureTerms.some((term) => t.includes(term)) && !blockedTerms.some((term) => t.includes(term));
}

function number(value: any, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

async function fetchNews() {
  const q = encodeURIComponent("(fashion OR music OR movie OR television OR celebrity OR wrestling OR streaming) sourcelang:english");
  const url = "https://api.gdeltproject.org/api/v2/doc/doc?query=" + q + "&mode=artlist&maxrecords=18&format=json&sort=hybridrel&timespan=24h";
  const response = await fetch(url, { headers: { "user-agent": "PULSE-LSMG/1.0" } });
  if (!response.ok) return [];
  const data: any = await response.json();
  const articles = Array.isArray(data.articles) ? data.articles : [];
  return articles.slice(0, 14).map((a: any) => ({
    title: a.title || "Culture update",
    url: a.url || "#",
    domain: a.domain || "",
    image: typeof a.socialimage === "string" && a.socialimage.startsWith("https://") ? a.socialimage : "",
    seen: a.seendate || ""
  }));
}

async function fetchPolymarket() {
  const url = "https://gamma-api.polymarket.com/markets?active=true&closed=false&limit=250&order=volume24hr&ascending=false";
  const response = await fetch(url, { headers: { "user-agent": "PULSE-LSMG/1.0" } });
  if (!response.ok) return [];
  const data: any[] = await response.json();
  return data
    .filter((m: any) => isCulture((m.question || "") + " " + (m.events?.[0]?.title || "")))
    .map((m: any) => {
      let outcomes: string[] = [];
      let prices: string[] = [];
      try { outcomes = JSON.parse(m.outcomes || "[]"); } catch {}
      try { prices = JSON.parse(m.outcomePrices || "[]"); } catch {}
      const yesIndex = outcomes.findIndex((o) => String(o).toLowerCase() === "yes");
      if (yesIndex < 0) return null;
      const yes = Math.max(0, Math.min(100, Math.round(number(prices[yesIndex]) * 100)));
      return {
        id: "poly-" + m.id,
        source: "POLYMARKET",
        title: m.question,
        yes,
        no: 100 - yes,
        volume24h: number(m.volume24hr),
        liquidity: number(m.liquidity),
        change1h: number(m.oneHourPriceChange) * 100,
        change24h: number(m.oneDayPriceChange) * 100,
        endDate: m.endDate || m.endDateIso || "",
        image: m.image || m.icon || "",
        sourceUrl: "https://polymarket.com",
        updatedAt: m.updatedAt || ""
      };
    })
    .filter(Boolean)
    .slice(0, 12);
}

async function fetchKalshi() {
  const url = "https://api.elections.kalshi.com/trade-api/v2/markets?limit=300&status=open";
  const response = await fetch(url, { headers: { "user-agent": "PULSE-LSMG/1.0" } });
  if (!response.ok) return [];
  const data: any = await response.json();
  const markets = Array.isArray(data.markets) ? data.markets : [];
  return markets
    .filter((m: any) => isCulture((m.title || "") + " " + (m.yes_sub_title || "") + " " + (m.no_sub_title || "")))
    .map((m: any) => {
      const yesDollar = number(m.last_price_dollars, number(m.yes_ask_dollars, number(m.yes_bid_dollars)));
      if (yesDollar <= 0 || yesDollar >= 1) return null;
      const yes = Math.max(0, Math.min(100, Math.round(yesDollar * 100)));
      return {
        id: "kalshi-" + m.ticker,
        source: "KALSHI",
        title: m.title,
        yes,
        no: 100 - yes,
        volume24h: number(m.volume_24h_fp),
        liquidity: number(m.liquidity_dollars),
        change1h: 0,
        change24h: (yesDollar - number(m.previous_price_dollars, yesDollar)) * 100,
        endDate: m.close_time || m.expiration_time || "",
        image: "",
        sourceUrl: "https://kalshi.com",
        updatedAt: m.updated_time || ""
      };
    })
    .filter(Boolean)
    .slice(0, 12);
}

export default async () => {
  try {
    const [news, polymarket, kalshi] = await Promise.all([
      fetchNews().catch(() => []),
      fetchPolymarket().catch(() => []),
      fetchKalshi().catch(() => [])
    ]);

    const markets = [...polymarket, ...kalshi]
      .sort((a: any, b: any) => number(b.volume24h) - number(a.volume24h))
      .slice(0, 16);

    return json({
      generatedAt: new Date().toISOString(),
      news,
      markets,
      sources: ["GDELT", "Polymarket", "Kalshi"]
    });
  } catch (error) {
    return json({ error: "feed_unavailable", generatedAt: new Date().toISOString(), news: [], markets: [] }, 200);
  }
};

export const config = {
  path: "/api/pulse-feed"
};
