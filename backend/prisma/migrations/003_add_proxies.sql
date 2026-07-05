-- Migration 003: Add proxies tables and payment proof base64 fallback

ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "proofImageBase64" TEXT;

CREATE TABLE IF NOT EXISTS "proxies" (
  "id"        TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "userId"    TEXT NOT NULL,
  "name"      TEXT NOT NULL,
  "type"      TEXT NOT NULL,
  "host"      TEXT NOT NULL,
  "port"      INTEGER NOT NULL,
  "username"  TEXT,
  "password"  TEXT,
  "isActive"  BOOLEAN NOT NULL DEFAULT true,
  "isWorking" BOOLEAN NOT NULL DEFAULT false,
  "lastCheck" TIMESTAMP(3),
  "lastError" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "proxies_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "proxies_userId_fkey" FOREIGN KEY ("userId")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "user_proxy_selections" (
  "id"        TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "userId"    TEXT NOT NULL,
  "proxyId"   TEXT,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "user_proxy_selections_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_proxy_selections_userId_fkey" FOREIGN KEY ("userId")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "user_proxy_selections_proxyId_fkey" FOREIGN KEY ("proxyId")
    REFERENCES "proxies"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "user_proxy_selections_userId_key" ON "user_proxy_selections"("userId");
CREATE INDEX IF NOT EXISTS "proxies_userId_idx" ON "proxies"("userId");
