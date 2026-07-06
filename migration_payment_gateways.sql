-- ============================================================
-- Migration: Payment Gateway Integration (OxaPay + API Syria)
-- Run this after the main database_schema.sql
-- ============================================================

-- Add OxaPay fields to payments table
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "oxapayTrackId" TEXT;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "oxapayPaymentUrl" TEXT;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "oxapayTxId" TEXT;

-- Create index for OxaPay track ID
CREATE INDEX IF NOT EXISTS "payments_oxapayTrackId_idx" ON "payments"("oxapayTrackId");

-- Add API Syria settings
INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'oxapay_merchant_api_key', '', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'oxapay_merchant_api_key');

INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'api_syria_api_key', '', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'api_syria_api_key');

INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'api_syria_account_address', '', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'api_syria_account_address');

INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'syriatel_cash_gsm', '', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'syriatel_cash_gsm');

INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'syria_usd_to_sp_rate', '15000', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'syria_usd_to_sp_rate');

INSERT INTO "settings" ("id", "key", "value", "group", "updatedAt")
SELECT gen_random_uuid()::text, 'sham_cash_account_address', '', 'payment', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM "settings" WHERE "key" = 'sham_cash_account_address');

-- Update existing sham_cash_number key visibility
UPDATE "settings" SET "group" = 'payment' WHERE "key" = 'sham_cash_number';
UPDATE "settings" SET "group" = 'payment' WHERE "key" = 'syriatel_cash_number';
UPDATE "settings" SET "group" = 'payment' WHERE "key" = 'usdt_bep20_address';

-- Ensure all payment settings are in correct group
UPDATE "settings" SET "group" = 'payment' WHERE "key" IN (
  'oxapay_merchant_api_key',
  'api_syria_api_key',
  'api_syria_account_address',
  'syriatel_cash_gsm',
  'syria_usd_to_sp_rate',
  'sham_cash_account_address'
);

-- Add admin log action types comment
COMMENT ON TABLE "admin_logs" IS 'Admin action logs. action can be: USER_TOGGLED, PAYMENT_APPROVED, PAYMENT_REJECTED, PAYMENT_AUTO_APPROVED_OXAPAY, PAYMENT_AUTO_APPROVED_APISYRIA, SUBSCRIPTION_ACTIVATED, etc.';

-- ============================================================
-- Done! Payment gateway integration tables updated.
-- ============================================================
