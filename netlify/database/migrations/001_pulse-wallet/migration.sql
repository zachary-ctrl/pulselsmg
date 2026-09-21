CREATE TABLE IF NOT EXISTS pulse_wallets (
  device_id TEXT PRIMARY KEY,
  pulse_bucks INTEGER NOT NULL DEFAULT 250,
  cash_cents INTEGER NOT NULL DEFAULT 0,
  last_daily_claim DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pulse_transactions (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES pulse_wallets(device_id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  currency TEXT NOT NULL,
  amount INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'complete',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS pulse_transactions_device_created_idx
  ON pulse_transactions(device_id, created_at DESC);

CREATE TABLE IF NOT EXISTS pulse_redemptions (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES pulse_wallets(device_id) ON DELETE CASCADE,
  reward_key TEXT NOT NULL,
  cost INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'redeemed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
