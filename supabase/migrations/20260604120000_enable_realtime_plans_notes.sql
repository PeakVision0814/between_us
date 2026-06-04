begin;

-- Enable Supabase Realtime for plans and notes tables.
-- This allows the Flutter app to subscribe to INSERT/UPDATE/DELETE events
-- and keep the plans & notes list in sync across couple members.

alter publication supabase_realtime add table public.plans;
alter publication supabase_realtime add table public.notes;

commit;
