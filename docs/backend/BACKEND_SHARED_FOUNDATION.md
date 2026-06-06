# 共享基础数据层 V1

这份文档对应第一版后端共享基础层的实际落地文件：

- [shared_foundation_v1.sql](/D:/Lenovo/Documents/Profile/Project/between_us/supabase/migrations/20260527221500_shared_foundation_v1.sql)

## 本轮已落地

已建表：

- `profiles`
- `couple_spaces`
- `couple_memberships`
- `couple_invites`
- `calendar_events`
- `plans`
- `notes`

已落地的数据库能力：

- 核心字段与外键
- 关键 check constraints
- `updated_at` 自动维护触发器
- 新用户自动补 `profiles` 行
- 共享空间成员上限约束
- 共享空间 owner 约束
- RLS policy
- 最小 invite 生命周期 RPC
- 伴侣互相可见 profiles 的 SECURITY DEFINER 函数（`20260604100000_add_profiles_select_couple_partner.sql`）

## 关系边界

`profiles`

- 一行对应一个 `auth.users.id`
- 只承接个人资料与个人偏好
- RLS 允许用户读取和更新自己的完整资料行
- RLS 允许同一 couple_space 的活跃成员互相读取最小公开资料字段：`display_name`、`avatar_url`

`couple_spaces`

- 所有共享内容都必须归属一个 `couple_space`
- 首版状态只保留：`pending_partner`、`active`、`closed`
- 本轮只实现创建与激活，不实现完整解绑关闭流程
- 产品边界已收口：`pending_partner` 只服务邀请和成员关系准备，不应开放计划、随记、日历事件等共享业务写入
- `active` 双人空间才是共享业务数据的有效写入容器

`couple_memberships`

- 一个用户同时最多只有一个活跃 membership
- 一个 `couple_space` 同时最多只有两个活跃成员
- 首版角色只保留：`owner`、`partner`

`couple_invites`

- 使用 `code_hash` 存储邀请码摘要，不存原始码
- 接受邀请后记录 `accepted_by` 和 `accepted_at`
- 撤销邀请后写入 `revoked_at`

`calendar_events`

- 只放有明确日期或时间的共享内容
- 首版 `event_type` 只支持：
  - `anniversary`
  - `date_plan`
  - `reminder`
- 首版 `recurrence` 只支持：
  - `none`
  - `yearly`
- `yearly` 只允许用于 `anniversary`，并要求 `all_day = true`

`plans`

- 只放未定日期的计划
- 首版 `status` 只支持：
  - `idea`
  - `discussing`
  - `scheduled`
  - `done`
  - `archived`

`notes`

- 双方可读
- 只有作者可更新
- 删除策略走软删除：更新 `deleted_at`
- 不开放直接 `DELETE` 给客户端

`cycle_records`

- 经期记录等敏感生活数据单独建表，不并入普通 `calendar_events`
- 只有记录者本人可创建、编辑、软删除
- 默认 `shared_with_partner = false`
- 伴侣只有在 `shared_with_partner = true` 且同属 active 双人空间时可读取
- 客户端删除策略走软删除：更新 `deleted_at`

## RLS 方向已经怎样落地

`profiles`

- `select`: 本人可读取自己的完整资料；同一 `couple_space` 的活跃成员可通过 `get_partner_public_profile()` 函数读取对方的 `display_name` 和 `avatar_url`
- `update`: 只能改自己
- 伴侣可见通过 SECURITY DEFINER 函数实现，不直接开放 RLS 行策略读取 profiles 整行（migration `20260604100000`）

`couple_spaces`

- `select`: 只有活跃成员能读
- `update`: 只有活跃成员能改共享基础信息
- 不开放直接 `insert`，用 `create_couple_space()` 创建

`couple_memberships`

- `select`: 活跃成员可读自己所在空间的 membership
- 不开放客户端直写

`couple_invites`

- `select`: 活跃成员可读自己所在空间的 invite
- 不开放客户端直写
- 通过 RPC 创建、接受、撤销

`calendar_events`

- 只有 `active` 双人空间的活跃成员才能读取（`pending_partner` 空间不可见）
- 只有 `active` 双人空间的活跃成员才能新建和更新
- 软删除后默认不再出现在客户端查询结果里
- 已通过 `is_active_couple_member()` 和 migration `20260603100000` + `20260603120000` 实施

`plans`

- 只有 `active` 双人空间的活跃成员才能读取（`pending_partner` 空间不可见）
- 只有 `active` 双人空间的活跃成员才能新建和更新
- 软删除后默认不再出现在客户端查询结果里
- 已通过 `is_active_couple_member()` 和 migration `20260603100000` + `20260603120000` 实施

`notes`

- 只有 `active` 双人空间的活跃成员才能读取（`pending_partner` 空间不可见）
- 只有 `active` 双人空间的活跃成员才能新建 note，`author_profile_id` 只表示作者，不表示业务数据归属
- 只有作者本人可更新或软删除自己的 note
- 已通过 `is_active_couple_member()` 和 migration `20260603100000` + `20260603120000` 实施

`cycle_records`

- 记录者本人可读取自己的未删除记录
- 记录者本人可在 active 双人空间内创建和更新自己的记录
- 记录者本人可通过软删除隐藏自己的记录
- 伴侣仅在 `shared_with_partner = true` 时可读取，不可编辑或删除
- 读取和写入均复用 `is_active_couple_member()`，保证 closed / pending 空间不可访问

## 前端接线约定

### 1. `calendar_events.event_type`

首版固定取值：

- `anniversary`
- `date_plan`
- `reminder`

不要在前端额外发明 `todo`、`note`、`cycle` 等类型。

### 2. `recurrence`

首版只支持：

- `none`
- `yearly`

并且：

- `yearly` 仅用于纪念日
- 不支持按周、按月、自定义 RRULE

### 3. `notes` 作者权限边界

- 双方成员都可读取同一 `couple_space` 下的 note
- `author_profile_id` 必须等于当前用户
- 只有作者本人能更新
- 首版删除用软删除，不走物理删除

### 4. `plans` 与 `calendar_events` 的关联

首版约定为可选的一对一关联，并要求两边必须属于同一个 `couple_space`：

- `calendar_events.source_plan_id`
- `plans.scheduled_event_id`

推荐接线方式：

1. 先创建 `plan`
2. 当计划确定日期后，创建 `calendar_event`
3. 在同一事务里回填双方的关联字段

业务语义：

- `plan` 仍然表示“原始未定计划”
- `calendar_event` 表示“已经进入日历的确定事项”

### 5. `couple_space / membership / invite` 最小生命周期

首版按下面的最小流转实现：

1. 用户调用 `create_couple_space()`
2. 数据库创建 `couple_space`
3. 数据库为创建者写入 `owner` membership
4. owner 调用 `create_couple_invite()`
5. 被邀请方调用 `accept_couple_invite()`
6. 数据库写入 `partner` membership
7. 空间状态从 `pending_partner` 升级为 `active`

撤销与异常：

- 邀请过期后不可再接受
- 邀请撤销后不可再接受
- 已在其他活跃空间中的用户不可接受新邀请
- 已满 2 个活跃成员的空间不可再接受邀请

## 经期记录 V1

对应 migration：`20260606110847_add_cycle_records.sql`

已落地：

- 新增 `cycle_records` 表
- 保留并使用 `profiles.cycle_sharing_enabled`
- 日历读取 `cycle_records` 的可见记录并做独立视觉标记
- 女性用户且处于 active 双人空间时可手动创建经期记录
- 记录者可编辑、软删除自己的记录
- 共享开关开启时批量把本人未删除记录设为 `shared_with_partner = true`
- 共享开关关闭时批量把本人未删除记录设为 `shared_with_partner = false`

边界：

- 默认不共享
- 敏感表不并入 `calendar_events`
- 伴侣只读，不可编辑或删除
- 首版不做预测、统计或医疗建议

## 本轮明确没做

- 不接 Flutter UI
- 不做完整登录 UI（后续阶段将补邮箱验证码登录，并预留手机号验证码登录）
- 不做通知
- 不做复杂云函数编排
- 不做经期预测
- 不做解绑、导出、永久删除完整流程
- 不做超出当前产品文档的新功能扩展

## 退出请求机制 V1

对应 migration：`20260604140000_add_couple_space_exit_requests.sql`

### 已落地

新增表：

- `couple_space_exit_requests`

新增 RPC：

- `request_couple_space_exit()` — 发起退出请求
- `approve_couple_space_exit(uuid)` — 审批退出请求

### 表职责

`couple_space_exit_requests`

- 记录双人空间退出请求的完整生命周期
- 一个 active couple space 同一时间最多只有一个 `pending` 请求
- `requested_by` 必须是该空间 active member
- 审批人不能是 `requested_by`

### RPC 行为

`request_couple_space_exit()`

- 校验用户已登录
- 校验用户属于 active 双人空间（2 名 active member）
- 如果已有 pending 请求，返回已有请求 id
- 否则创建新的 pending 请求并返回 id
- 不允许单人态调用成功

`approve_couple_space_exit(p_request_id)`

- 校验用户已登录
- 校验请求存在且为 `pending`
- 校验当前用户是该空间 active member
- 校验当前用户不是 `requested_by`
- 校验空间仍是 active 双人空间
- 更新请求状态为 `approved`
- 更新该空间所有 active membership 为 `left`（设 `left_at`）
- 更新 `couple_spaces.status` 为 `closed`（设 `closed_at`）
- 整个操作在一个事务中完成

### RLS 方向

- active couple space 成员可以读取自己空间的退出请求（select）
- 不开放客户端直接 insert/update/delete
- 所有变更通过 SECURITY DEFINER RPC 执行
- SECURITY DEFINER 函数设置了固定 `search_path = public`
- 已 revoke from anon，仅 grant execute to authenticated

### 退出状态流

```
A 发起退出请求 → pending
B 同意退出    → approved → 空间 closed，双方 left
```

本轮未实现的状态流转（留到后续阶段）：

- `pending` → `cancelled`（发起方取消）
- 对方拒绝退出
- 同一方连续 3 次被拒绝后强制关闭
- 对方 24 小时无操作自动关闭

### 关闭空间后共享数据保留

空间关闭后，以下数据不物理删除：

- `calendar_events`
- `plans`
- `notes`

这些数据仍保留在原 `couple_space_id` 下。由于现有 RLS 策略要求 `is_active_couple_member()` 返回 true，空间关闭后（member status = 'left'），该函数返回 false，双方自然不可继续读取或写入这些共享数据。

### Flutter 回到单人态

- `AppController._loadCurrentMembership()` 查询 `status = 'active'` 的 membership
- 关闭空间后 membership status = 'left'，查询返回 null
- `_loadOrCreateCurrentSpaceId()` 自动调用 `create_couple_space()` 创建新空间
- `hasActiveCoupleSpace` 返回 false
- 用户回到单人态

## 后续已完成的前端接入

本节保留的是后端共享基础层当时的落地边界。后续阶段已经完成：

- Flutter App 初始化 Supabase
- 邮箱验证码登录与注册分离
- 注册后资料引导
- 邀请码生成与接受流程接入
- 邀请配对闭环完成：创建邀请码 → 输入邀请码 → 接受邀请 → 双方进入 active 双人空间
- 日历、计划、随记接入共享空间同步
- `AppController` 统一持有当前用户资料和 `currentSpaceId`

## 还需要产品收口的少量边界

1. `pending_partner` 状态下是否允许提前写入共享内容：产品结论为不允许。单人态采用严格能力白名单，`pending_partner` 只用于邀请，不承载计划、随记、日历事件等业务写入。
2. 邀请码有效期默认值当前定为 `24 hours`（已在 migration `20260528120000` 中从 7 天改为 24 小时），如果产品要改为更短或更长，需要同步 RPC 默认参数。
