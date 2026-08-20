CREATE TABLE IF NOT EXISTS support_messages (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  topic TEXT NOT NULL,
  message TEXT NOT NULL,
  ip TEXT NOT NULL DEFAULT '',
  user_agent TEXT NOT NULL DEFAULT '',
  access_token_hash TEXT,
  notified_at TEXT
);

CREATE INDEX IF NOT EXISTS support_messages_created_at
  ON support_messages (created_at DESC);
