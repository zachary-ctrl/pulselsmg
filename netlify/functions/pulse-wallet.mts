import { getDatabase } from "@netlify/database";

const rewards: Record<string, { cost: number; label: string }> = {
  "after-dark-pass": { cost: 100, label: "LEDGERA After Dark access badge" },
  "creator-boost": { cost: 250, label: "24-hour creator profile boost" },
  "issue-drop": { cost: 500, label: "LEDGERA digital issue drop" },
  "profile-review": { cost: 1000, label: "LSMG creative profile review request" }
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
  });
}

function cleanDeviceId(value: string | null) {
  const v = (value || "").trim();
  return /^[a-zA-Z0-9_-]{12,80}$/.test(v) ? v : null;
}

async function ensureSchema(db: ReturnType<typeof getDatabase>) {
  await db.pool.query("CREATE TABLE IF NOT EXISTS pulse_wallets (device_id TEXT PRIMARY KEY, pulse_bucks INTEGER NOT NULL DEFAULT 250, cash_cents INTEGER NOT NULL DEFAULT 0, last_daily_claim DATE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())");
  await db.pool.query("CREATE TABLE IF NOT EXISTS pulse_transactions (id BIGSERIAL PRIMARY KEY, device_id TEXT NOT NULL REFERENCES pulse_wallets(device_id) ON DELETE CASCADE, kind TEXT NOT NULL, currency TEXT NOT NULL, amount INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'complete', metadata JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())");
  await db.pool.query("CREATE INDEX IF NOT EXISTS pulse_transactions_device_created_idx ON pulse_transactions(device_id, created_at DESC)");
  await db.pool.query("CREATE TABLE IF NOT EXISTS pulse_redemptions (id BIGSERIAL PRIMARY KEY, device_id TEXT NOT NULL REFERENCES pulse_wallets(device_id) ON DELETE CASCADE, reward_key TEXT NOT NULL, cost INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'redeemed', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())");
}

async function ensureWallet(db: ReturnType<typeof getDatabase>, deviceId: string) {
  await db.pool.query(
    "INSERT INTO pulse_wallets (device_id) VALUES ($1) ON CONFLICT (device_id) DO NOTHING",
    [deviceId]
  );
  const result = await db.pool.query(
    "SELECT device_id, pulse_bucks, cash_cents, last_daily_claim, created_at, updated_at FROM pulse_wallets WHERE device_id = $1",
    [deviceId]
  );
  return result.rows[0];
}

export default async (req: Request) => {
  const deviceId = cleanDeviceId(req.headers.get("x-pulse-device"));
  if (!deviceId) return json({ error: "missing_device_id" }, 400);

  const db = getDatabase();
  await ensureSchema(db);
  const wallet = await ensureWallet(db, deviceId);

  if (req.method === "GET") {
    const transactions = await db.pool.query(
      "SELECT id, kind, currency, amount, status, metadata, created_at FROM pulse_transactions WHERE device_id = $1 ORDER BY created_at DESC LIMIT 30",
      [deviceId]
    );
    const redemptions = await db.pool.query(
      "SELECT id, reward_key, cost, status, created_at FROM pulse_redemptions WHERE device_id = $1 ORDER BY created_at DESC LIMIT 20",
      [deviceId]
    );
    return json({ wallet, transactions: transactions.rows, redemptions: redemptions.rows, rewards });
  }

  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: any = {};
  try { body = await req.json(); } catch {}
  const action = String(body.action || "");

  if (action === "claim_daily") {
    const client = await db.pool.connect();
    try {
      await client.query("BEGIN");
      const lock = await client.query(
        "SELECT pulse_bucks, last_daily_claim FROM pulse_wallets WHERE device_id = $1 FOR UPDATE",
        [deviceId]
      );
      const current = lock.rows[0];
      const today = new Date().toISOString().slice(0, 10);
      const last = current?.last_daily_claim ? String(current.last_daily_claim).slice(0, 10) : null;
      if (last === today) {
        await client.query("ROLLBACK");
        return json({ error: "already_claimed_today" }, 409);
      }
      await client.query(
        "UPDATE pulse_wallets SET pulse_bucks = pulse_bucks + 50, last_daily_claim = CURRENT_DATE, updated_at = NOW() WHERE device_id = $1",
        [deviceId]
      );
      await client.query(
        "INSERT INTO pulse_transactions (device_id, kind, currency, amount, metadata) VALUES ($1, 'daily_claim', 'PB', 50, $2::jsonb)",
        [deviceId, JSON.stringify({ source: "daily_check_in" })]
      );
      await client.query("COMMIT");
      return json({ ok: true, pulse_bucks_added: 50 });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  if (action === "redeem") {
    const rewardKey = String(body.reward_key || "");
    const reward = rewards[rewardKey];
    if (!reward) return json({ error: "invalid_reward" }, 400);

    const client = await db.pool.connect();
    try {
      await client.query("BEGIN");
      const lock = await client.query(
        "SELECT pulse_bucks FROM pulse_wallets WHERE device_id = $1 FOR UPDATE",
        [deviceId]
      );
      const balance = Number(lock.rows[0]?.pulse_bucks || 0);
      if (balance < reward.cost) {
        await client.query("ROLLBACK");
        return json({ error: "insufficient_pulse_bucks", needed: reward.cost, balance }, 409);
      }
      await client.query(
        "UPDATE pulse_wallets SET pulse_bucks = pulse_bucks - $1, updated_at = NOW() WHERE device_id = $2",
        [reward.cost, deviceId]
      );
      await client.query(
        "INSERT INTO pulse_redemptions (device_id, reward_key, cost) VALUES ($1, $2, $3)",
        [deviceId, rewardKey, reward.cost]
      );
      await client.query(
        "INSERT INTO pulse_transactions (device_id, kind, currency, amount, metadata) VALUES ($1, 'redeem', 'PB', $2, $3::jsonb)",
        [deviceId, -reward.cost, JSON.stringify({ reward_key: rewardKey, label: reward.label })]
      );
      await client.query("COMMIT");
      return json({ ok: true, reward_key: rewardKey, label: reward.label, cost: reward.cost });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  if (action === "deposit" || action === "withdraw") {
    return json({
      error: "payment_provider_required",
      message: "Cash movement is not enabled until a compatible licensed payment/settlement provider is connected and approved for the operator's exact wagering use case."
    }, 409);
  }

  return json({ error: "unknown_action" }, 400);
};

export const config = {
  path: "/api/wallet"
};
