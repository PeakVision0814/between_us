-- Cycle records RLS acceptance checks.
--
-- Run in a linked Supabase project after replacing the UUID placeholders below
-- with real auth.users/profile ids that belong to the same active couple space.
-- This script is intentionally written as a manual verification snippet because
-- auth.uid() is JWT-derived in normal client requests.
--
-- Required setup:
-- 1. female_user_id profile: gender = 'female', cycle_sharing_enabled = false
-- 2. male_user_id profile: gender = 'male'
-- 3. both users are active members of active_space_id

begin;

-- Replace these values before running.
select
  '00000000-0000-0000-0000-000000000001'::uuid as active_space_id,
  '00000000-0000-0000-0000-000000000002'::uuid as female_user_id,
  '00000000-0000-0000-0000-000000000003'::uuid as male_user_id;

-- Expected: false. Male profile cannot satisfy the database-side write helper,
-- even if a malicious client bypasses the Flutter UI.
select public.can_write_cycle_record(
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000003'::uuid,
  '00000000-0000-0000-0000-000000000003'::uuid
) as male_can_write_cycle_record;

-- Expected: true. Female owner in active couple space can write.
select public.can_write_cycle_record(
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid
) as female_can_write_cycle_record;

-- Expected: false while profiles.cycle_sharing_enabled is false, even if the
-- individual record has shared_with_partner = true.
select public.can_read_partner_cycle_record(
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid,
  '00000000-0000-0000-0000-000000000003'::uuid
) as partner_can_read_when_profile_switch_off;

rollback;
