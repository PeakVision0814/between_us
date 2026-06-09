begin;

do $$
begin
  if to_regclass('public.couple_spaces') is not null
    and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'couple_spaces'
    )
  then
    alter publication supabase_realtime add table public.couple_spaces;
  end if;

  if to_regclass('public.couple_memberships') is not null
    and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'couple_memberships'
    )
  then
    alter publication supabase_realtime add table public.couple_memberships;
  end if;

  if to_regclass('public.couple_space_exit_requests') is not null
    and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'couple_space_exit_requests'
    )
  then
    alter publication supabase_realtime add table public.couple_space_exit_requests;
  end if;
end $$;

commit;
