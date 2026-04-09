-- Migration 003: Update User Profile Fields
-- This migration updates the users table to support improved registration flow

-- ================================================
-- 1. Add new user profile fields
-- ================================================

-- Add separate name fields
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS patronymic TEXT;

-- Add new client profile fields
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS work_direction TEXT,
  ADD COLUMN IF NOT EXISTS social_network TEXT,
  ADD COLUMN IF NOT EXISTS work_format TEXT;

-- Comments for new fields
COMMENT ON COLUMN public.users.first_name IS 'Имя пользователя';
COMMENT ON COLUMN public.users.last_name IS 'Фамилия пользователя';
COMMENT ON COLUMN public.users.patronymic IS 'Отчество пользователя (опционально)';
COMMENT ON COLUMN public.users.work_direction IS 'Направление работы/подход (опционально)';
COMMENT ON COLUMN public.users.social_network IS 'Соц.сеть или сайт (опционально)';
COMMENT ON COLUMN public.users.work_format IS 'Формат работы: group или individual (опционально)';

-- ================================================
-- 2. Migrate existing data from 'name' to 'first_name'
-- ================================================

-- For existing users with 'name', split into first_name and last_name
-- This is a simple migration - assumes "FirstName LastName" format
-- More complex parsing would need to be done in application code
UPDATE public.users
SET 
  first_name = CASE 
    WHEN position(' ' IN name) > 0 THEN split_part(name, ' ', 1)
    ELSE name
  END,
  last_name = CASE 
    WHEN position(' ' IN name) > 0 THEN split_part(name, ' ', 2)
    ELSE ''
  END
WHERE name IS NOT NULL 
  AND (first_name IS NULL OR last_name IS NULL);

-- ================================================
-- 3. Remove rules_accepted field
-- ================================================

-- Drop the rules_accepted column as rules will be shown on every booking
ALTER TABLE public.users 
  DROP COLUMN IF EXISTS rules_accepted;

-- ================================================
-- 4. Update constraints (optional)
-- ================================================

-- Add constraint to work_format if needed
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_work_format_check;

ALTER TABLE public.users
  ADD CONSTRAINT users_work_format_check
  CHECK (work_format IS NULL OR work_format IN ('group', 'individual'));

-- Note: We keep the old 'name' column for now to avoid breaking changes
-- It can be removed later after confirming all data is migrated
-- To remove it, uncomment the following line:
-- ALTER TABLE public.users DROP COLUMN IF EXISTS name;

COMMENT ON TABLE public.users IS 'Обновлено: разделенные поля имени, дополнительные поля профиля клиента';
