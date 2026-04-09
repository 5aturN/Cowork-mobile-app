-- Migration: Add date column to bookings table
-- Created at: 2026-01-11
-- Description: Adds 'date' column for slot-based booking system logic (removing dependency on timezone-shifted timestamps)

-- 1. Add the column
ALTER TABLE "public"."bookings" 
ADD COLUMN "date" date;

-- 2. Backfill existing data (Optional/Safe attempt)
-- Logic attempts to take the date part from created_at or start_time if available.
-- Adjust timezone if necessary (e.g. AT TIME ZONE 'Europe/Moscow')
UPDATE "public"."bookings"
SET "date" = ("created_at" AT TIME ZONE 'UTC')::date
WHERE "date" IS NULL;

-- 3. Make it required (Optional, only run if you are sure all rows have dates)
-- ALTER TABLE "public"."bookings" ALTER COLUMN "date" SET NOT NULL;
