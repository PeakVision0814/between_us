# 数据库规划

这份文档说明在开始 Supabase 集成前，初始共享数据结构和访问规则应该如何设计。

## 设计原则

- 每一条共享数据都必须属于且只属于一个 `couple_space`。
- 每一次共享查询都必须基于 `couple_space membership` 做过滤。
- 应用个人偏好属于用户个人资料，不属于情侣共享空间。
- 一个 `couple space` 最多只能有 2 个活跃成员。
- 删除行为必须遵循明确的产品规则，不能依赖隐式级联删除。
- 数据导出与解绑行为必须在上线前就写清楚。
- 首版数据结构必须支持“中文优先、英文可选”和主题偏好。

## 核心表

### `profiles`

用途：

- 存放和 `auth.users` 绑定的个人展示信息与个人偏好。

建议字段：

- `id uuid primary key`，引用 `auth.users.id`
- `display_name text not null`
- `avatar_url text null`
- `timezone text not null`
- `preferred_locale text not null default 'zh-CN'`
- `theme_preference text not null default 'system'`
- `notification_preview_enabled boolean not null default false`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`

说明：

- `preferred_locale` 是个人设置，不要求和伴侣一致。
- 首版支持 `zh-CN` 和 `en`。
- `theme_preference` 支持 `system`、`light`、`dark`。

### `couple_spaces`

用途：

- 表示两个人之间唯一的私密共享空间。

建议字段：

- `id uuid primary key`
- `created_by uuid not null`
- `status text not null`，例如 `pending_partner`、`active`、`unlink_requested`、`closed`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `closed_at timestamptz null`

### `couple_memberships`

用途：

- 记录谁属于某个 `couple space`，以及其当前状态。

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `profile_id uuid not null`
- `role text not null`，例如 `owner`、`partner`
- `status text not null`，例如 `active`、`left`、`removed`
- `joined_at timestamptz not null`
- `left_at timestamptz null`

约束：

- 一个用户在任意时刻最多只能有一个活跃 membership。
- 一个 `couple space` 在任意时刻最多只能有两个活跃 membership。

### `couple_invites`

用途：

- 管理第二位成员的加入流程。

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `code_hash text not null`
- `expires_at timestamptz not null`
- `accepted_by uuid null`
- `accepted_at timestamptz null`
- `revoked_at timestamptz null`

规则：

- 只有活跃成员才能创建邀请。
- 邀请在被接受、撤销、过期，或者空间已满两人后失效。

### `moments`

用途：

- 存放轻量共享片刻和短消息。

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `author_profile_id uuid not null`
- `body text not null`
- `authored_at timestamptz not null`
- `author_timezone text not null`
- `author_local_date date not null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- 每条片刻只属于一个作者。
- 只有作者本人可以更新或删除该片刻。
- 首版数据模型不强制写“每天最多几条”的规则。
- 首版数据模型不引入连续打卡或“每日必须发”的逻辑。

### `anniversaries`

用途：

- 存放重要日期和倒计时相关信息。

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `title text not null`
- `event_date date not null`
- `recurrence text not null`，例如 `yearly`、`once`
- `reminder_days_before integer[] not null default '{}'`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- 首版只支持 `once` 和 `yearly`。

## Row Level Security 方向

`RLS` 规则应确保以下原则成立：

- 用户只能读取自己的 `profiles` 行。
- 用户只能更新自己的 `preferred_locale`、`theme_preference`、`timezone`
  和 `notification_preview_enabled`。
- 用户只有在拥有该空间活跃 membership 时，才能读取对应 `couple_space`。
- 用户只有在拥有该空间活跃 membership 时，才能读取该空间的 `moments`
  和 `anniversaries`。
- 用户只有在拥有该空间活跃 membership 时，才能创建 `moment`。
- 用户只有在 `author_profile_id` 与当前用户一致时，才能更新或删除该 `moment`。
- 邀请创建、撤销和接受都必须检查 membership 状态以及“两人上限”。
- 已关闭或已解绑的空间，除非存在专门恢复流程，否则应拒绝新的写入。

## 邀请流程规则

1. 用户 A 登录后创建一个 `couple space`。
2. 用户 A 成为 `owner` 且状态为活跃成员。
3. 用户 A 创建一个带过期时间的邀请。
4. 用户 B 使用邀请加入，并成为 `partner`。
5. 邀请被标记为已使用，空间状态变为 `active`。

必须处理的失败场景：

- 邀请已过期
- 邀请已撤销
- 用户已经属于另一个活跃 `couple space`
- 目标空间已经有两个活跃成员

## 解绑、导出与删除规则

- 解绑后，被移除成员必须立即失去未来的共享访问权限。
- 在允许永久删除前，必须先提供数据导出。
- 永久删除必须是显式且可审计的，不能只是解绑带来的副作用。
- 早期阶段优先使用 `deleted_at` 这类软删除字段，以便误操作可回看。

尚未最终拍板的产品问题：

- 解绑后，是否为双方保留一个只读导出窗口，再进入最终删除。

## 通知与隐私安全

- 默认通知内容不应直接包含敏感消息正文。
- 锁屏预览在双方明确开启前，应保持泛化提示。
- 发送提醒的后端函数必须在发送时再次检查 `couple space membership`，
  不能只在创建计划任务时检查一次。
