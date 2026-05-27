# Supabase Backend

这轮共享基础层的可执行落地文件放在这里：

- `migrations/20260527221500_shared_foundation_v1.sql`

## 这份 migration 包含什么

- `profiles`
- `couple_spaces`
- `couple_memberships`
- `couple_invites`
- `calendar_events`
- `plans`
- `notes`
- 触发器、约束、RLS policy
- 4 个最小 RPC：
  - `create_couple_space`
  - `create_couple_invite`
  - `accept_couple_invite`
  - `revoke_couple_invite`

## 应用方式

如果本地已经初始化 Supabase CLI：

```powershell
supabase db push
```

如果当前还没初始化 CLI，也可以先把 migration 内容放到 Supabase SQL Editor 执行。

## 当前刻意没做

- 不接 Flutter UI
- 不做通知
- 不做云函数编排
- 不做经期表的真实接入
- 不做复杂 recurrence
- 不做解绑/导出完整流程

经期记录这轮只保留了 `profiles.cycle_sharing_enabled` 这个用户级共享开关，
后续真实表应独立建模，并保持“默认不共享、仅本人可写”的规则。
