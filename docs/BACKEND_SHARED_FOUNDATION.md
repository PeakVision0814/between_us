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

## 关系边界

`profiles`

- 一行对应一个 `auth.users.id`
- 只承接个人资料与个人偏好
- RLS 只允许用户读取和更新自己的行

`couple_spaces`

- 所有共享内容都必须归属一个 `couple_space`
- 首版状态只保留：`pending_partner`、`active`、`closed`
- 本轮只实现创建与激活，不实现完整解绑关闭流程

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

## RLS 方向已经怎样落地

`profiles`

- `select`: 只能读自己
- `update`: 只能改自己

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

- 活跃成员都可读
- 活跃成员都可新建
- 活跃成员都可更新
- 软删除后默认不再出现在客户端查询结果里

`plans`

- 活跃成员都可读
- 活跃成员都可新建
- 活跃成员都可更新
- 软删除后默认不再出现在客户端查询结果里

`notes`

- 活跃成员都可读
- 只有作者本人可新建为自己的 note
- 只有作者本人可更新或软删除自己的 note

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

## 经期记录预留策略

这轮没有创建 `cycle_records` 表。

保留策略是：

- 先保留 `profiles.cycle_sharing_enabled`
- 未来敏感数据单独建表
- 未来敏感表不并入普通 `calendar_events`
- 如果未来要在日历展示，应走“敏感表 + 投影视图/受控查询”路线
- 默认不共享，且只允许本人写

## 本轮明确没做

- 不接 Flutter UI
- 不做完整登录 UI
- 不做通知
- 不做复杂云函数编排
- 不做经期预测
- 不做经期真实表接入
- 不做解绑、导出、永久删除完整流程
- 不做超出当前产品文档的新功能扩展

## 还需要产品收口的少量边界

1. `pending_partner` 状态下，owner 是否允许提前写入共享内容。当前实现是允许。
2. 邀请码有效期默认值当前定为 `7 days`，如果产品要改为更短或更长，需要同步 RPC 默认参数。
