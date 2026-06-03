-- ============================================================
-- RLS 验证脚本：restrict_shared_writes_to_active_couple
-- 在 Supabase SQL Editor 中以 service_role 执行，或在本地 supabase 中执行
-- ============================================================

-- 前置说明：
-- RLS 策略依赖 auth.uid()，因此完整验证需要以 authenticated 用户身份执行。
-- 以下测试通过模拟场景说明预期行为，实际验证建议结合 Supabase Dashboard 的
-- Authentication > Users 功能创建测试用户后，以对应 JWT 执行 insert/update。

-- ============================================================
-- 场景 1：pending_partner 空间写入应失败
-- ============================================================

-- 准备：创建一个 pending_partner 空间，只有 1 个 owner
-- （假设已有测试用户 test-user-1 的 auth.uid()）

-- 1a. pending_partner 空间 insert calendar_events：应返回 0 rows 或报错
-- INSERT INTO public.calendar_events (couple_space_id, created_by, event_type, title, starts_at)
-- VALUES ('<pending_space_id>', '<test-user-1>', 'reminder', 'test', now());
-- 预期：ERROR: new row violates row-level security policy

-- 1b. pending_partner 空间 insert plans：应返回 0 rows 或报错
-- INSERT INTO public.plans (couple_space_id, created_by, title)
-- VALUES ('<pending_space_id>', '<test-user-1>', 'test plan');
-- 预期：ERROR: new row violates row-level security policy

-- 1c. pending_partner 空间 insert notes：应返回 0 rows 或报错
-- INSERT INTO public.notes (couple_space_id, author_profile_id, body, author_local_date)
-- VALUES ('<pending_space_id>', '<test-user-1>', 'test note', current_date);
-- 预期：ERROR: new row violates row-level security policy

-- ============================================================
-- 场景 2：active 双人空间写入应成功
-- ============================================================

-- 准备：将空间 status 改为 active，并添加第二个成员
-- UPDATE public.couple_spaces SET status = 'active' WHERE id = '<space_id>';
-- INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
-- VALUES ('<space_id>', '<test-user-2>', 'partner');

-- 2a. active 空间成员 insert calendar_events：应成功
-- INSERT INTO public.calendar_events (couple_space_id, created_by, event_type, title, starts_at)
-- VALUES ('<space_id>', '<test-user-1>', 'reminder', 'test event', now());
-- 预期：INSERT 0 1

-- 2b. active 空间成员 insert plans：应成功
-- INSERT INTO public.plans (couple_space_id, created_by, title)
-- VALUES ('<space_id>', '<test-user-1>', 'test plan');
-- 预期：INSERT 0 1

-- 2c. active 空间成员 insert notes：应成功
-- INSERT INTO public.notes (couple_space_id, author_profile_id, body, author_local_date)
-- VALUES ('<space_id>', '<test-user-1>', 'test note', current_date);
-- 预期：INSERT 0 1

-- ============================================================
-- 场景 3：notes 作者权限
-- ============================================================

-- 3a. 作者本人 update 自己的 note：应成功
-- UPDATE public.notes SET body = 'updated' WHERE id = '<note_id>';
-- 预期：UPDATE 1

-- 3b. 非作者 update 别人的 note：应返回 0 rows（RLS 隐藏）
-- UPDATE public.notes SET body = 'hacked' WHERE id = '<note_id>';
-- 预期：UPDATE 0（以 test-user-2 身份执行）

-- ============================================================
-- 自动化验证（不依赖 auth.uid()，直接测试函数逻辑）
-- ============================================================

-- 验证 is_active_couple_member 函数逻辑正确

-- 测试 1：pending_partner 空间的 owner 应返回 false
DO $$
DECLARE
  v_space_id uuid;
  v_user_id uuid;
  v_result boolean;
BEGIN
  -- 创建测试数据
  INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'test@example.com')
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_user_id;
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'test@example.com' LIMIT 1;
  END IF;

  INSERT INTO public.couple_spaces (created_by, space_name, status)
  VALUES (v_user_id, 'test-pending', 'pending_partner')
  RETURNING id INTO v_space_id;

  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES (v_space_id, v_user_id, 'owner');

  -- 测试：pending_partner 空间应返回 false
  SELECT public.is_active_couple_member(v_space_id, v_user_id) INTO v_result;
  ASSERT v_result = false, 'pending_partner space should return false, got: ' || v_result;

  -- 清理
  DELETE FROM public.couple_memberships WHERE couple_space_id = v_space_id;
  DELETE FROM public.couple_spaces WHERE id = v_space_id;

  RAISE NOTICE 'Test 1 PASSED: pending_partner space returns false';
END $$;

-- 测试 2：active 空间但只有 1 个成员应返回 false
DO $$
DECLARE
  v_space_id uuid;
  v_user_id uuid;
  v_result boolean;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'test@example.com' LIMIT 1;

  INSERT INTO public.couple_spaces (created_by, space_name, status)
  VALUES (v_user_id, 'test-active-solo', 'active')
  RETURNING id INTO v_space_id;

  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES (v_space_id, v_user_id, 'owner');

  -- 测试：active 空间但只有 1 个成员应返回 false
  SELECT public.is_active_couple_member(v_space_id, v_user_id) INTO v_result;
  ASSERT v_result = false, 'active space with 1 member should return false, got: ' || v_result;

  -- 清理
  DELETE FROM public.couple_memberships WHERE couple_space_id = v_space_id;
  DELETE FROM public.couple_spaces WHERE id = v_space_id;

  RAISE NOTICE 'Test 2 PASSED: active space with 1 member returns false';
END $$;

-- 测试 3：active 空间且有 2 个成员应返回 true
DO $$
DECLARE
  v_space_id uuid;
  v_user1_id uuid;
  v_user2_id uuid;
  v_result boolean;
BEGIN
  SELECT id INTO v_user1_id FROM auth.users WHERE email = 'test@example.com' LIMIT 1;
  INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'test2@example.com')
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_user2_id;
  IF v_user2_id IS NULL THEN
    SELECT id INTO v_user2_id FROM auth.users WHERE email = 'test2@example.com' LIMIT 1;
  END IF;

  INSERT INTO public.couple_spaces (created_by, space_name, status)
  VALUES (v_user1_id, 'test-active-paired', 'active')
  RETURNING id INTO v_space_id;

  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES (v_space_id, v_user1_id, 'owner');
  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES (v_space_id, v_user2_id, 'partner');

  -- 测试：active 空间且有 2 个成员应返回 true
  SELECT public.is_active_couple_member(v_space_id, v_user1_id) INTO v_result;
  ASSERT v_result = true, 'active space with 2 members should return true, got: ' || v_result;

  -- 清理
  DELETE FROM public.couple_memberships WHERE couple_space_id = v_space_id;
  DELETE FROM public.couple_spaces WHERE id = v_space_id;

  RAISE NOTICE 'Test 3 PASSED: active space with 2 members returns true';
END $$;

-- 清理测试用户
DELETE FROM auth.users WHERE email IN ('test@example.com', 'test2@example.com');

RAISE NOTICE 'All is_active_couple_member function tests completed.';
