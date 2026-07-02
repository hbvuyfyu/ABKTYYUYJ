-- Migration 002: Add dynamic games tables

CREATE TABLE IF NOT EXISTS "games" (
  "id"          TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "name"        TEXT NOT NULL,
  "displayName" TEXT NOT NULL,
  "platform"    TEXT NOT NULL,
  "package"     TEXT,
  "devKey"      TEXT,
  "appKey"      TEXT,
  "appToken"    TEXT,
  "emoji"       TEXT NOT NULL DEFAULT '🎮',
  "isActive"    BOOLEAN NOT NULL DEFAULT true,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "games_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "game_events" (
  "id"          TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "gameId"      TEXT NOT NULL,
  "eventName"   TEXT NOT NULL,
  "displayName" TEXT NOT NULL,
  "eventToken"  TEXT,
  "isPurchase"  BOOLEAN NOT NULL DEFAULT false,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "game_events_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "game_events_gameId_fkey" FOREIGN KEY ("gameId")
    REFERENCES "games"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "games_platform_idx" ON "games"("platform");
CREATE INDEX IF NOT EXISTS "games_package_idx" ON "games"("package");
CREATE INDEX IF NOT EXISTS "game_events_gameId_idx" ON "game_events"("gameId");
