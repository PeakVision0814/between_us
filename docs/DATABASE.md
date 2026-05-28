# 数据库规划

这份文档用于约束当前产品方向下的数据模型、共享边界和敏感数据规则。

## 当前数据模型目标

当前产品围绕 4 个主界面构建：

- 首页
- 日历
- 计划笔记
- 我们

因此，数据结构也应围绕以下几类对象设计：

- 双人共享空间
- 日历事件
- 未定日期的计划
- 自由随记
- 个人偏好与共享设置
- 经期记录等敏感数据

## 设计原则

- 每条共享数据都必须属于一个 `couple_space`
- 个人偏好数据归个人所有，不归共享空间所有
- 日历、计划、随记的数据边界必须与页面边界保持一致
- 健康与敏感数据默认谨慎，不能默认完全共享
- 删除行为优先采用软删除策略，防止误操作

## 核心表

### `profiles`

用途：

- 存放用户个人资料与个人偏好

建议字段：

- `id uuid primary key`
- `display_name text not null`
- `avatar_url text null`
- `timezone text not null`
- `preferred_locale text not null default 'zh-CN'`
- `theme_preference text not null default 'system'`
- `notification_preview_enabled boolean not null default false`
- `cycle_sharing_enabled boolean not null default false`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`

说明：

- `preferred_locale` 只影响该用户自己的界面语言
- `theme_preference` 只影响该用户自己的主题
- `cycle_sharing_enabled` 用于表达该用户是否愿意把经期相关内容共享给伴侣

### `couple_spaces`

用途：

- 存放两个人之间唯一的共享空间

建议字段：

- `id uuid primary key`
- `created_by uuid not null`
- `space_name text null`
- `status text not null`
- `relationship_start_date date null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `closed_at timestamptz null`

### `couple_memberships`

用途：

- 存放用户与 `couple_space` 的关系

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `profile_id uuid not null`
- `role text not null`
- `status text not null`
- `joined_at timestamptz not null`
- `left_at timestamptz null`

约束：

- 一个用户同时最多只有一个活跃的 `couple_space membership`
- 一个 `couple_space` 同时最多只有两个活跃成员

### `couple_invites`

用途：

- 存放邀请第二位成员加入的记录

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `code_hash text not null`
- `expires_at timestamptz not null`
- `accepted_by uuid null`
- `accepted_at timestamptz null`
- `revoked_at timestamptz null`

### `calendar_events`

用途：

- 存放所有已确定日期或时间的共享内容

承载内容类型：

- 纪念日
- 约会安排
- 提醒
- 已经确定日期的计划

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `event_type text not null`
- `title text not null`
- `description text null`
- `starts_at timestamptz not null`
- `ends_at timestamptz null`
- `all_day boolean not null default true`
- `recurrence text not null default 'none'`
- `source_plan_id uuid null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- 只有明确绑定日期或时间的内容进入 `calendar_events`
- `event_type` 首版建议支持：`anniversary`、`date_plan`、`reminder`
- 首版纪念日重复规则建议支持：`none`、`yearly`
- 如果事件来自计划笔记，应记录 `source_plan_id`

### `plans`

用途：

- 存放还没有明确日期的计划

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `title text not null`
- `body text null`
- `status text not null`
- `scheduled_event_id uuid null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- `plans` 只放未绑定日期的计划
- 一旦计划进入日历，可以关联 `scheduled_event_id`
- 首版 `status` 建议支持：`idea`、`discussing`、`scheduled`、`done`、`archived`
- 计划是双人协作内容，不要求只允许作者编辑

### `notes`

用途：

- 存放自由随记和轻量共享日记

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `author_profile_id uuid not null`
- `body text not null`
- `authored_at timestamptz not null`
- `author_local_date date not null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- `notes` 用于自由记录，不要求绑定日期
- 双方都能看，但默认仅作者本人可编辑或删除
- 首版不强制“每天几条”的规则
- 首版不引入连续打卡逻辑

### `cycle_records`

用途：

- 存放经期记录等高敏感生活数据

建议字段：

- `id uuid primary key`
- `couple_space_id uuid not null`
- `owner_profile_id uuid not null`
- `period_start_date date not null`
- `period_end_date date null`
- `note text null`
- `shared_with_partner boolean not null default false`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

规则：

- 经期记录属于 `owner_profile_id`
- 只有记录者本人可以创建、编辑、删除
- 只有在 `shared_with_partner = true` 时，伴侣才可查看
- 首版只做手动记录，不做复杂预测

## Row Level Security 方向

`RLS` 应确保以下原则成立：

- 用户可以读取和更新自己的 `profiles` 行
- 同一 `couple_space` 的活跃成员可以互相读取对方的 `display_name` 和 `avatar_url`
- 用户只能修改自己的语言、主题、时区和通知偏好
- 活跃成员才能读取所在 `couple_space`
- 活跃成员才能读取 `calendar_events`、`plans`、`notes`
- 活跃成员可以共同创建和维护 `calendar_events`
- 活跃成员可以共同维护 `plans`
- `notes` 仅作者本人可更新或删除
- `cycle_records` 仅记录者本人可更新或删除
- 伴侣只有在 `shared_with_partner = true` 时才可读取 `cycle_records`
- 已解绑或已关闭的空间，除非存在专门恢复流，否则应阻止新的写入

## 页面与数据的对应关系

- `首页`
  - 读取 `calendar_events` 的近期数据
  - 读取 `plans` 的待推进数据
  - 读取 `notes` 的最近一条记录
  - 读取 `couple_spaces` 的基础信息

- `日历`
  - 主要读取 `calendar_events`
  - 后续可读取 `cycle_records` 的共享可见数据

- `计划笔记`
  - `计划` 子区读取 `plans`
  - `随记` 子区读取 `notes`

- `我们`
  - 读取和更新 `profiles`
  - 读取 `couple_spaces`、`couple_memberships`、`couple_invites`
  - 后续承接敏感数据共享开关

## 邀请流程规则

1. 用户 A 登录后创建一个 `couple_space`
2. 用户 A 成为 `owner`
3. 用户 A 创建邀请
4. 用户 B 接受邀请并成为 `partner`
5. 空间进入 `active`

必须处理的失败场景：

- 邀请过期
- 邀请撤销
- 用户已属于另一个活跃空间
- 目标空间成员已满

## 解绑、导出与删除规则

- 解绑后，被移除成员必须立即失去未来共享访问权限
- 永久删除前必须先支持导出
- 永久删除必须是显式行为，不能是解绑副作用
- 首版优先用软删除，减少误删风险

## 敏感数据特殊规则

经期记录属于健康与隐私敏感数据，产品和数据库都必须遵守：

- 默认不共享
- 记录者本人拥有绝对控制权
- 共享必须显式开启
- 共享后对方只能查看，不应默认获得编辑权
- 首版不在数据库层承载医疗建议、预测模型或过度复杂的生理统计
