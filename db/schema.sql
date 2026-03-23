-- Run this against your Neon database to set up the schema.
-- Each app built from this template should extend this file with its own tables.

CREATE TABLE IF NOT EXISTS users (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT        NOT NULL,
  email        TEXT        UNIQUE NOT NULL,
  password_hash TEXT       NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- Add app-specific tables below this line.
