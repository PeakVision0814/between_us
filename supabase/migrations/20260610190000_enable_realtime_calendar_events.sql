begin;

-- Enable Supabase Realtime for calendar_events table.
-- plans and notes were added in 20260604120000, but calendar_events
-- was missed.  This allows the Flutter app to subscribe to
-- INSERT/UPDATE/DELETE events and keep the calendar list in sync
-- across couple members without requiring a manual refresh.

do $$
begin
  if to_regclass('public.calendar_events') is not null
    and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'calendar_events'
    )
  then
    alter publication supabase_realtime add table public.calendar_events;
  end if;
end $$;

commit;
