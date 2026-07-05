-- ============================================================
-- Migration: جدولة العمليات (Scheduling Groups)
-- ============================================================
-- Run this in your PostgreSQL/Supabase SQL editor to add the
-- sched_groups table required by the new scheduling feature.
-- Safe to run multiple times (idempotent).
-- ============================================================

CREATE TABLE IF NOT EXISTS "sched_groups" (
    "id"              TEXT NOT NULL,
    "userId"          TEXT NOT NULL,
    "platform"        TEXT NOT NULL,
    "gameId"          TEXT,
    "gameName"        TEXT NOT NULL,
    "gamePkg"         TEXT,
    "gameKey"         TEXT,
    "eventsOrder"     TEXT NOT NULL,
    "intervalMinutes" INTEGER NOT NULL DEFAULT 0,
    "gaid"            TEXT NOT NULL,
    "afUid"           TEXT,
    "status"          TEXT NOT NULL DEFAULT 'active',
    "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "nextRun"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"       TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sched_groups_pkey" PRIMARY KEY ("id")
);

-- Foreign key to users (cascade on delete)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'sched_groups_userId_fkey'
  ) THEN
    ALTER TABLE "sched_groups"
      ADD CONSTRAINT "sched_groups_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE;
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS "sched_groups_userId_idx" ON "sched_groups"("userId");
CREATE INDEX IF NOT EXISTS "sched_groups_status_idx" ON "sched_groups"("status");
