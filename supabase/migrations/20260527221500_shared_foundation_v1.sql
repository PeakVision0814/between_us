begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create type public.app_theme_preference as enum ('system', 'light', 'dark');
create type public.couple_space_status as enum ('pending_partner', 'active', 'closed');
create type public.couple_membership_role as enum ('owner', 'partner');
create type public.couple_membership_status as enum ('active', 'left', 'removed');
create type public.calendar_event_type as enum ('anniversary', 'date_plan', 'reminder');
create type public.calendar_event_recurrence as enum ('none', 'yearly');
create type public.plan_status as enum ('idea', 'discussing', 'scheduled', 'done', 'archived');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

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
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      '新的用户'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function public.is_active_member(
  p_couple_space_id uuid,
  p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couple_memberships memberships
    join public.couple_spaces spaces
      on spaces.id = memberships.couple_space_id
    where memberships.couple_space_id = p_couple_space_id
      and memberships.profile_id = p_profile_id
      and memberships.status = 'active'
      and memberships.left_at is null
      and spaces.closed_at is null
      and spaces.status in ('pending_partner', 'active')
  );
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  avatar_url text,
  timezone text not null default 'Asia/Shanghai',
  preferred_locale text not null default 'zh-CN',
  theme_preference public.app_theme_preference not null default 'system',
  notification_preview_enabled boolean not null default false,
  cycle_sharing_enabled boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_display_name_check
    check (char_length(btrim(display_name)) between 1 and 40),
  constraint profiles_preferred_locale_check
    check (preferred_locale in ('zh-CN', 'en'))
);

create table public.couple_spaces (
  id uuid primary key default extensions.gen_random_uuid(),
  created_by uuid not null references public.profiles (id) on delete restrict,
  space_name text,
  status public.couple_space_status not null default 'pending_partner',
  relationship_start_date date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  closed_at timestamptz,
  constraint couple_spaces_name_check
    check (space_name is null or char_length(btrim(space_name)) between 1 and 40),
  constraint couple_spaces_closed_state_check
    check (
      (status = 'closed' and closed_at is not null)
      or (status <> 'closed' and closed_at is null)
    )
);

create table public.couple_memberships (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  profile_id uuid not null references public.profiles (id) on delete restrict,
  role public.couple_membership_role not null,
  status public.couple_membership_status not null default 'active',
  joined_at timestamptz not null default timezone('utc', now()),
  left_at timestamptz,
  constraint couple_memberships_unique_member_per_space
    unique (couple_space_id, profile_id),
  constraint couple_memberships_status_check
    check (
      (status = 'active' and left_at is null)
      or (status in ('left', 'removed') and left_at is not null)
    )
);

create unique index couple_memberships_one_active_space_per_profile_idx
  on public.couple_memberships (profile_id)
  where status = 'active' and left_at is null;

create unique index couple_memberships_one_active_owner_per_space_idx
  on public.couple_memberships (couple_space_id)
  where role = 'owner' and status = 'active' and left_at is null;

create table public.couple_invites (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  created_by uuid not null references public.profiles (id) on delete restrict,
  code_hash text not null unique,
  expires_at timestamptz not null,
  accepted_by uuid references public.profiles (id) on delete restrict,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint couple_invites_code_hash_check
    check (char_length(code_hash) = 64),
  constraint couple_invites_accept_pair_check
    check (
      (accepted_by is null and accepted_at is null)
      or (accepted_by is not null and accepted_at is not null)
    ),
  constraint couple_invites_terminal_state_check
    check (not (accepted_at is not null and revoked_at is not null))
);

create table public.calendar_events (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  created_by uuid not null references public.profiles (id) on delete restrict,
  event_type public.calendar_event_type not null,
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  all_day boolean not null default true,
  recurrence public.calendar_event_recurrence not null default 'none',
  source_plan_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint calendar_events_id_space_unique unique (id, couple_space_id),
  constraint calendar_events_title_check
    check (char_length(btrim(title)) between 1 and 120),
  constraint calendar_events_time_check
    check (ends_at is null or ends_at >= starts_at),
  constraint calendar_events_recurrence_check
    check (
      recurrence = 'none'
      or (
        recurrence = 'yearly'
        and event_type = 'anniversary'
        and all_day = true
      )
    ),
  constraint calendar_events_source_plan_type_check
    check (source_plan_id is null or event_type = 'date_plan')
);

create table public.plans (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  created_by uuid not null references public.profiles (id) on delete restrict,
  title text not null,
  body text,
  status public.plan_status not null default 'idea',
  scheduled_event_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint plans_id_space_unique unique (id, couple_space_id),
  constraint plans_title_check
    check (char_length(btrim(title)) between 1 and 120),
  constraint plans_scheduled_status_check
    check (status <> 'scheduled' or scheduled_event_id is not null)
);

create table public.notes (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  author_profile_id uuid not null references public.profiles (id) on delete restrict,
  body text not null,
  authored_at timestamptz not null default timezone('utc', now()),
  author_local_date date not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint notes_body_check
    check (char_length(btrim(body)) between 1 and 4000)
);

alter table public.calendar_events
  add constraint calendar_events_source_plan_fk
  foreign key (source_plan_id, couple_space_id)
  references public.plans (id, couple_space_id)
  deferrable initially deferred;

alter table public.plans
  add constraint plans_scheduled_event_fk
  foreign key (scheduled_event_id, couple_space_id)
  references public.calendar_events (id, couple_space_id)
  deferrable initially deferred;

create unique index calendar_events_source_plan_idx
  on public.calendar_events (source_plan_id)
  where source_plan_id is not null and deleted_at is null;

create unique index plans_scheduled_event_idx
  on public.plans (scheduled_event_id)
  where scheduled_event_id is not null and deleted_at is null;

create or replace function public.protect_immutable_fields()
returns trigger
language plpgsql
as $$
begin
  if tg_table_name = 'profiles' then
    if new.id <> old.id or new.created_at <> old.created_at then
      raise exception 'profiles immutable fields cannot be changed';
    end if;
  elsif tg_table_name = 'couple_spaces' then
    if
      new.id <> old.id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
      or (
        current_user not in ('postgres', 'service_role')
        and (
          new.status <> old.status
          or new.closed_at is distinct from old.closed_at
        )
      )
    then
      raise exception 'couple_spaces lifecycle fields cannot be changed directly';
    end if;
  elsif tg_table_name = 'calendar_events' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
    then
      raise exception 'calendar_events ownership fields cannot be changed';
    end if;
  elsif tg_table_name = 'plans' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
    then
      raise exception 'plans ownership fields cannot be changed';
    end if;
  elsif tg_table_name = 'notes' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.author_profile_id <> old.author_profile_id
      or new.created_at <> old.created_at
    then
      raise exception 'notes ownership fields cannot be changed';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.enforce_membership_rules()
returns trigger
language plpgsql
as $$
declare
  v_active_space_members integer;
begin
  if new.status = 'active' and new.left_at is null then
    select count(*)
      into v_active_space_members
    from public.couple_memberships memberships
    where memberships.couple_space_id = new.couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
      and memberships.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);

    if v_active_space_members >= 2 then
      raise exception 'couple_space already has two active members';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.promote_space_when_second_member_joins()
returns trigger
language plpgsql
as $$
declare
  v_active_member_count integer;
begin
  if new.status = 'active' and new.left_at is null then
    select count(*)
      into v_active_member_count
    from public.couple_memberships memberships
    where memberships.couple_space_id = new.couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null;

    if v_active_member_count = 2 then
      update public.couple_spaces
      set status = 'active',
          updated_at = timezone('utc', now())
      where id = new.couple_space_id
        and status = 'pending_partner';
    end if;
  end if;

  return null;
end;
$$;

create or replace function public.create_couple_space(
  p_space_name text default null,
  p_relationship_start_date date default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if exists (
    select 1
    from public.couple_memberships memberships
    where memberships.profile_id = auth.uid()
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'user already belongs to an active couple_space';
  end if;

  insert into public.couple_spaces (
    created_by,
    space_name,
    relationship_start_date
  )
  values (
    auth.uid(),
    nullif(btrim(p_space_name), ''),
    p_relationship_start_date
  )
  returning id into v_space_id;

  insert into public.couple_memberships (
    couple_space_id,
    profile_id,
    role
  )
  values (
    v_space_id,
    auth.uid(),
    'owner'
  );

  return v_space_id;
end;
$$;

create or replace function public.create_couple_invite(
  p_couple_space_id uuid,
  p_plain_code text,
  p_expires_in interval default interval '7 days'
)
returns table (
  invite_id uuid,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if p_plain_code is null or char_length(btrim(p_plain_code)) < 8 then
    raise exception 'invite code must be at least 8 characters';
  end if;

  if p_expires_in <= interval '0 seconds' then
    raise exception 'invite expiration must be positive';
  end if;

  if not exists (
    select 1
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.profile_id = auth.uid()
      and memberships.role = 'owner'
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'only the active owner can create an invite';
  end if;

  if (
    select count(*)
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
  ) >= 2 then
    raise exception 'couple_space already has two active members';
  end if;

  if exists (
    select 1
    from public.couple_invites invites
    where invites.couple_space_id = p_couple_space_id
      and invites.accepted_at is null
      and invites.revoked_at is null
      and invites.expires_at > timezone('utc', now())
  ) then
    raise exception 'an active invite already exists for this couple_space';
  end if;

  return query
  insert into public.couple_invites (
    couple_space_id,
    created_by,
    code_hash,
    expires_at
  )
  values (
    p_couple_space_id,
    auth.uid(),
    encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex'),
    timezone('utc', now()) + p_expires_in
  )
  returning public.couple_invites.id, public.couple_invites.expires_at;
end;
$$;

create or replace function public.accept_couple_invite(
  p_plain_code text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.couple_invites%rowtype;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if p_plain_code is null or btrim(p_plain_code) = '' then
    raise exception 'invite code is required';
  end if;

  if exists (
    select 1
    from public.couple_memberships memberships
    where memberships.profile_id = auth.uid()
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'user already belongs to an active couple_space';
  end if;

  select invites.*
    into v_invite
  from public.couple_invites invites
  join public.couple_spaces spaces
    on spaces.id = invites.couple_space_id
  where invites.code_hash = encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex')
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now())
    and spaces.closed_at is null
    and spaces.status in ('pending_partner', 'active')
  for update;

  if not found then
    raise exception 'invite is invalid, expired, or already used';
  end if;

  if (
    select count(*)
    from public.couple_memberships memberships
    where memberships.couple_space_id = v_invite.couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
  ) >= 2 then
    raise exception 'couple_space already has two active members';
  end if;

  insert into public.couple_memberships (
    couple_space_id,
    profile_id,
    role
  )
  values (
    v_invite.couple_space_id,
    auth.uid(),
    'partner'
  );

  update public.couple_invites
  set accepted_by = auth.uid(),
      accepted_at = timezone('utc', now())
  where id = v_invite.id;

  update public.couple_spaces
  set status = 'active',
      updated_at = timezone('utc', now())
  where id = v_invite.couple_space_id
    and status = 'pending_partner';

  return v_invite.couple_space_id;
end;
$$;

create or replace function public.revoke_couple_invite(
  p_invite_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  select invites.couple_space_id
    into v_space_id
  from public.couple_invites invites
  join public.couple_memberships memberships
    on memberships.couple_space_id = invites.couple_space_id
  where invites.id = p_invite_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and memberships.profile_id = auth.uid()
    and memberships.role = 'owner'
    and memberships.status = 'active'
    and memberships.left_at is null
  for update;

  if not found then
    raise exception 'invite cannot be revoked';
  end if;

  update public.couple_invites
  set revoked_at = timezone('utc', now())
  where id = p_invite_id;

  return v_space_id;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger couple_spaces_set_updated_at
before update on public.couple_spaces
for each row execute function public.set_updated_at();

create trigger calendar_events_set_updated_at
before update on public.calendar_events
for each row execute function public.set_updated_at();

create trigger plans_set_updated_at
before update on public.plans
for each row execute function public.set_updated_at();

create trigger notes_set_updated_at
before update on public.notes
for each row execute function public.set_updated_at();

create trigger profiles_protect_immutable_fields
before update on public.profiles
for each row execute function public.protect_immutable_fields();

create trigger couple_spaces_protect_immutable_fields
before update on public.couple_spaces
for each row execute function public.protect_immutable_fields();

create trigger calendar_events_protect_immutable_fields
before update on public.calendar_events
for each row execute function public.protect_immutable_fields();

create trigger plans_protect_immutable_fields
before update on public.plans
for each row execute function public.protect_immutable_fields();

create trigger notes_protect_immutable_fields
before update on public.notes
for each row execute function public.protect_immutable_fields();

create trigger couple_memberships_enforce_rules
before insert or update on public.couple_memberships
for each row execute function public.enforce_membership_rules();

create trigger couple_memberships_promote_space
after insert or update on public.couple_memberships
for each row execute function public.promote_space_when_second_member_joins();

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, display_name)
select
  users.id,
  coalesce(
    nullif(btrim(users.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(coalesce(users.email, ''), '@', 1), ''),
    '新的用户'
  )
from auth.users users
left join public.profiles profiles
  on profiles.id = users.id
where profiles.id is null;

alter table public.profiles enable row level security;
alter table public.couple_spaces enable row level security;
alter table public.couple_memberships enable row level security;
alter table public.couple_invites enable row level security;
alter table public.calendar_events enable row level security;
alter table public.plans enable row level security;
alter table public.notes enable row level security;

create policy "profiles_select_self"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

create policy "profiles_update_self"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "couple_spaces_select_active_members"
  on public.couple_spaces
  for select
  to authenticated
  using (public.is_active_member(id));

create policy "couple_spaces_update_active_members"
  on public.couple_spaces
  for update
  to authenticated
  using (public.is_active_member(id))
  with check (public.is_active_member(id));

create policy "couple_memberships_select_active_members"
  on public.couple_memberships
  for select
  to authenticated
  using (public.is_active_member(couple_space_id));

create policy "couple_invites_select_active_members"
  on public.couple_invites
  for select
  to authenticated
  using (public.is_active_member(couple_space_id));

create policy "calendar_events_select_active_members"
  on public.calendar_events
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_member(couple_space_id)
  );

create policy "calendar_events_insert_active_members"
  on public.calendar_events
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.is_active_member(couple_space_id)
  );

create policy "calendar_events_update_active_members"
  on public.calendar_events
  for update
  to authenticated
  using (
    deleted_at is null
    and public.is_active_member(couple_space_id)
  )
  with check (public.is_active_member(couple_space_id));

create policy "plans_select_active_members"
  on public.plans
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_member(couple_space_id)
  );

create policy "plans_insert_active_members"
  on public.plans
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.is_active_member(couple_space_id)
  );

create policy "plans_update_active_members"
  on public.plans
  for update
  to authenticated
  using (
    deleted_at is null
    and public.is_active_member(couple_space_id)
  )
  with check (public.is_active_member(couple_space_id));

create policy "notes_select_active_members"
  on public.notes
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_member(couple_space_id)
  );

create policy "notes_insert_author_only"
  on public.notes
  for insert
  to authenticated
  with check (
    author_profile_id = auth.uid()
    and public.is_active_member(couple_space_id)
  );

create policy "notes_update_author_only"
  on public.notes
  for update
  to authenticated
  using (
    deleted_at is null
    and author_profile_id = auth.uid()
    and public.is_active_member(couple_space_id)
  )
  with check (
    author_profile_id = auth.uid()
    and public.is_active_member(couple_space_id)
  );

grant usage on schema public to anon, authenticated, service_role;

grant select, update on public.profiles to authenticated;
grant select, update on public.couple_spaces to authenticated;
grant select on public.couple_memberships to authenticated;
grant select on public.couple_invites to authenticated;
grant select, insert, update on public.calendar_events to authenticated;
grant select, insert, update on public.plans to authenticated;
grant select, insert, update on public.notes to authenticated;

revoke all on function public.create_couple_space(text, date) from public;
revoke all on function public.create_couple_invite(uuid, text, interval) from public;
revoke all on function public.accept_couple_invite(text) from public;
revoke all on function public.revoke_couple_invite(uuid) from public;
revoke all on function public.is_active_member(uuid, uuid) from public;

grant execute on function public.create_couple_space(text, date) to authenticated;
grant execute on function public.create_couple_invite(uuid, text, interval) to authenticated;
grant execute on function public.accept_couple_invite(text) to authenticated;
grant execute on function public.revoke_couple_invite(uuid) to authenticated;
grant execute on function public.is_active_member(uuid, uuid) to authenticated;

commit;
