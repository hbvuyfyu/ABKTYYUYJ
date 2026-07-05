-- ============================================================
-- VIP App - Complete Database Schema (Single SQL Command)
-- ============================================================
-- Run this entire script in your PostgreSQL database
-- It creates ALL tables, indexes, and constraints needed by the VIP app
-- ============================================================

-- Drop existing tables if they exist (clean slate)
DROP TABLE IF EXISTS "user_proxy_selections" CASCADE;
DROP TABLE IF EXISTS "proxies" CASCADE;
DROP TABLE IF EXISTS "sched_groups" CASCADE;
DROP TABLE IF EXISTS "game_events" CASCADE;
DROP TABLE IF EXISTS "games" CASCADE;
DROP TABLE IF EXISTS "used_txids" CASCADE;
DROP TABLE IF EXISTS "settings" CASCADE;
DROP TABLE IF EXISTS "admin_logs" CASCADE;
DROP TABLE IF EXISTS "daily_usages" CASCADE;
DROP TABLE IF EXISTS "payments" CASCADE;
DROP TABLE IF EXISTS "subscriptions" CASCADE;
DROP TABLE IF EXISTS "plans" CASCADE;
DROP TABLE IF EXISTS "users" CASCADE;

-- Drop existing enum types
DROP TYPE IF EXISTS "UserRole" CASCADE;
DROP TYPE IF EXISTS "PaymentStatus" CASCADE;
DROP TYPE IF EXISTS "PaymentMethod" CASCADE;
DROP TYPE IF EXISTS "SubscriptionStatus" CASCADE;

-- Create enum types
CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE "PaymentMethod" AS ENUM ('SHAM_CASH', 'SYRIATEL_CASH', 'USDT_BEP20');
CREATE TYPE "SubscriptionStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED');

-- Create users table
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "name" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- Create plans table
CREATE TABLE "plans" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT NOT NULL,
    "durationDays" INTEGER NOT NULL,
    "dailyOperations" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "plans_pkey" PRIMARY KEY ("id")
);

-- Create subscriptions table
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "startDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endDate" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- Create payments table
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "subscriptionId" TEXT,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DOUBLE PRECISION NOT NULL,
    "proofImageUrl" TEXT,
    "proofImageBase64" TEXT,
    "txid" TEXT,
    "txidVerified" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "adminNotes" TEXT,
    "reviewedBy" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- Create daily_usages table
CREATE TABLE "daily_usages" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "subscriptionId" TEXT NOT NULL,
    "date" DATE NOT NULL DEFAULT CURRENT_DATE,
    "operationsUsed" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "daily_usages_pkey" PRIMARY KEY ("id")
);

-- Create admin_logs table
CREATE TABLE "admin_logs" (
    "id" TEXT NOT NULL,
    "adminId" TEXT NOT NULL,
    "targetId" TEXT,
    "action" TEXT NOT NULL,
    "details" TEXT,
    "ipAddress" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "admin_logs_pkey" PRIMARY KEY ("id")
);

-- Create settings table
CREATE TABLE "settings" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "group" TEXT NOT NULL DEFAULT 'general',
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "settings_pkey" PRIMARY KEY ("id")
);

-- Create used_txids table
CREATE TABLE "used_txids" (
    "id" TEXT NOT NULL,
    "txid" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "used_txids_pkey" PRIMARY KEY ("id")
);

-- Create games table (dynamic games added by admin)
CREATE TABLE "games" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "name" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "package" TEXT,
    "devKey" TEXT,
    "appKey" TEXT,
    "appToken" TEXT,
    "emoji" TEXT NOT NULL DEFAULT '🎮',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "games_pkey" PRIMARY KEY ("id")
);

-- Create game_events table
CREATE TABLE "game_events" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "gameId" TEXT NOT NULL,
    "eventName" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "eventToken" TEXT,
    "isPurchase" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "game_events_pkey" PRIMARY KEY ("id")
);

-- Create sched_groups table (scheduling groups)
CREATE TABLE "sched_groups" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "gameId" TEXT,
    "gameName" TEXT NOT NULL,
    "gamePkg" TEXT,
    "gameKey" TEXT,
    "eventsOrder" TEXT NOT NULL,
    "intervalMinutes" INTEGER NOT NULL DEFAULT 0,
    "gaid" TEXT NOT NULL,
    "afUid" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "nextRun" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "sched_groups_pkey" PRIMARY KEY ("id")
);

-- Create proxies table
CREATE TABLE "proxies" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "host" TEXT NOT NULL,
    "port" INTEGER NOT NULL,
    "username" TEXT,
    "password" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isWorking" BOOLEAN NOT NULL DEFAULT false,
    "lastCheck" TIMESTAMP(3),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "proxies_pkey" PRIMARY KEY ("id")
);

-- Create user_proxy_selections table
CREATE TABLE "user_proxy_selections" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL,
    "proxyId" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "user_proxy_selections_pkey" PRIMARY KEY ("id")
);

-- Create indexes
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX "payments_txid_key" ON "payments"("txid");
CREATE UNIQUE INDEX "daily_usages_userId_subscriptionId_date_key" ON "daily_usages"("userId", "subscriptionId", "date");
CREATE UNIQUE INDEX "settings_key_key" ON "settings"("key");
CREATE UNIQUE INDEX "used_txids_txid_key" ON "used_txids"("txid");
CREATE INDEX "games_platform_idx" ON "games"("platform");
CREATE INDEX "games_package_idx" ON "games"("package");
CREATE INDEX "game_events_gameId_idx" ON "game_events"("gameId");
CREATE INDEX "sched_groups_userId_idx" ON "sched_groups"("userId");
CREATE INDEX "sched_groups_status_idx" ON "sched_groups"("status");
CREATE INDEX "proxies_userId_idx" ON "proxies"("userId");
CREATE UNIQUE INDEX "user_proxy_selections_userId_key" ON "user_proxy_selections"("userId");
CREATE UNIQUE INDEX "user_proxy_selections_proxyId_key" ON "user_proxy_selections"("proxyId");

-- Add foreign key constraints
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_planId_fkey" FOREIGN KEY ("planId") REFERENCES "plans"("id") ON UPDATE CASCADE;

ALTER TABLE "payments" ADD CONSTRAINT "payments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "payments" ADD CONSTRAINT "payments_planId_fkey" FOREIGN KEY ("planId") REFERENCES "plans"("id") ON UPDATE CASCADE;
ALTER TABLE "payments" ADD CONSTRAINT "payments_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON UPDATE CASCADE;

ALTER TABLE "daily_usages" ADD CONSTRAINT "daily_usages_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "daily_usages" ADD CONSTRAINT "daily_usages_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "admin_logs" ADD CONSTRAINT "admin_logs_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "users"("id") ON UPDATE CASCADE;
ALTER TABLE "admin_logs" ADD CONSTRAINT "admin_logs_targetId_fkey" FOREIGN KEY ("targetId") REFERENCES "users"("id") ON UPDATE CASCADE;

ALTER TABLE "game_events" ADD CONSTRAINT "game_events_gameId_fkey" FOREIGN KEY ("gameId") REFERENCES "games"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "sched_groups" ADD CONSTRAINT "sched_groups_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "proxies" ADD CONSTRAINT "proxies_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_proxy_selections" ADD CONSTRAINT "user_proxy_selections_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_proxy_selections" ADD CONSTRAINT "user_proxy_selections_proxyId_fkey" FOREIGN KEY ("proxyId") REFERENCES "proxies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================
-- Seed Data: Default Plans
-- ============================================================
INSERT INTO "plans" ("id", "name", "nameAr", "durationDays", "dailyOperations", "price", "isActive", "updatedAt") VALUES
(gen_random_uuid()::text, 'Daily', 'يومية', 1, 5, 5.0, true, CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'Weekly', 'أسبوعية', 7, 10, 10.0, true, CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'Monthly', 'شهرية', 30, 15, 20.0, true, CURRENT_TIMESTAMP);

-- ============================================================
-- Seed Data: Default Settings
-- ============================================================
INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt") VALUES
(gen_random_uuid()::text, 'sham_cash_number', '', 'payment', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'syriatel_cash_number', '', 'payment', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'usdt_bep20_address', '', 'payment', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'cloudinary_cloud_name', '', 'cloudinary', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'cloudinary_api_key', '', 'cloudinary', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'cloudinary_api_secret', '', 'cloudinary', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'bscscan_api_key', '', 'blockchain', CURRENT_TIMESTAMP),
(gen_random_uuid()::text, 'usdt_contract_address', '0x55d398326f99059fF775485246999027B3197955', 'blockchain', CURRENT_TIMESTAMP);

-- ============================================================
-- Seed Data: Admin User
-- ============================================================
-- Password: Admin@123456 (bcrypt hash)
INSERT INTO "users" ("id", "email", "password", "name", "role", "isActive", "updatedAt") VALUES
(gen_random_uuid()::text, 'admin@vip.app', '$2a$10$N9qo8uLOickgx2ZMRZoMy.MQDqoZ4Yzq1.8ZcQKQvKQRjYqWbH5Kq', 'Admin', 'ADMIN', true, CURRENT_TIMESTAMP);

-- ============================================================
-- Done! All tables created successfully.
-- ============================================================
