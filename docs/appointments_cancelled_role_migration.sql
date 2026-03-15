-- Add cancelled_role while keeping cancelled_by as UUID.
-- Run this once on Supabase SQL editor.

ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS cancelled_role varchar;

-- Optional backfill for legacy rows where cancelled_by stored a role string
-- (if any bad legacy data exists):
-- UPDATE appointments
-- SET cancelled_role = cancelled_by::text,
--     cancelled_by = NULL
-- WHERE cancelled_by::text IN ('user', 'expert', 'admin');
