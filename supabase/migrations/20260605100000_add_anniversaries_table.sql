begin;

-- 1. 新建纪念日表
create table public.anniversaries (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  type text not null check (type in ('first_met', 'relationship_start', 'custom')),
  title text not null,
  date date not null,
  is_custom boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.anniversaries is '纪念日表，存储相识纪念日、恋爱纪念日和自定义纪念日';
comment on column public.anniversaries.type is '纪念日类型：first_met（相识）、relationship_start（恋爱）、custom（自定义）';
comment on column public.anniversaries.is_custom is '是否为自定义纪念日';

-- 2. 启用 RLS
alter table public.anniversaries enable row level security;

-- 3. RLS 策略：只允许同一 couple_space 的活跃成员访问
create policy "anniversaries_select_active_couple" on public.anniversaries
  for select to authenticated
  using (
    exists (
      select 1 from public.couple_memberships cm
      where cm.couple_space_id = anniversaries.couple_space_id
      and cm.profile_id = auth.uid()
      and cm.status = 'active'
    )
  );

create policy "anniversaries_insert_active_couple" on public.anniversaries
  for insert to authenticated
  with check (
    exists (
      select 1 from public.couple_memberships cm
      where cm.couple_space_id = anniversaries.couple_space_id
      and cm.profile_id = auth.uid()
      and cm.status = 'active'
    )
  );

create policy "anniversaries_update_active_couple" on public.anniversaries
  for update to authenticated
  using (
    exists (
      select 1 from public.couple_memberships cm
      where cm.couple_space_id = anniversaries.couple_space_id
      and cm.profile_id = auth.uid()
      and cm.status = 'active'
    )
  );

create policy "anniversaries_delete_active_couple" on public.anniversaries
  for delete to authenticated
  using (
    exists (
      select 1 from public.couple_memberships cm
      where cm.couple_space_id = anniversaries.couple_space_id
      and cm.profile_id = auth.uid()
      and cm.status = 'active'
    )
  );

-- 4. 索引
create index idx_anniversaries_couple_space_id on public.anniversaries(couple_space_id);
create index idx_anniversaries_type on public.anniversaries(type);

-- 5. 启用 Realtime
alter publication supabase_realtime add table public.anniversaries;

-- 6. 删除 couple_spaces.relationship_start_date 字段
alter table public.couple_spaces drop column if exists relationship_start_date;

-- 7. 更新 create_couple_space 函数，移除 p_relationship_start_date 参数
-- 同时在空间创建时自动预置两个固有纪念日
create or replace function public.create_couple_space(
  p_space_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 检查用户是否已有活跃空间
  if exists (
    select 1 from couple_memberships
    where profile_id = v_user_id and status = 'active'
  ) then
    raise exception 'User already belongs to an active couple_space';
  end if;

  -- 创建空间
  insert into couple_spaces (created_by, space_name, status)
  values (v_user_id, p_space_name, 'pending_partner')
  returning id into v_space_id;

  -- 创建成员关系
  insert into couple_memberships (couple_space_id, profile_id, role, status)
  values (v_space_id, v_user_id, 'owner', 'active');

  -- 预置固有纪念日
  insert into anniversaries (couple_space_id, type, title, date, is_custom)
  values
    (v_space_id, 'first_met', '相识纪念日', current_date, false),
    (v_space_id, 'relationship_start', '恋爱纪念日', current_date, false);

  return v_space_id;
end;
$$;

commit;
