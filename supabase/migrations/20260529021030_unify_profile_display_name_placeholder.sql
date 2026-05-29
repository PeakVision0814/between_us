begin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
      '新的用户'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

insert into public.profiles (id, display_name)
select
  users.id,
  coalesce(
    nullif(btrim(users.raw_user_meta_data ->> 'display_name'), ''),
    '新的用户'
  )
from auth.users users
left join public.profiles profiles
  on profiles.id = users.id
where profiles.id is null;

comment on function public.handle_new_user() is
  'Creates a profile row for each auth user. Uses a trimmed explicit display_name when present, otherwise falls back to the fixed placeholder 新的用户.';

commit;
