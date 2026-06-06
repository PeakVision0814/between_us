# Between Us

[English](README.md)

Between Us 是一款以隐私优先为原则、面向情侣两个人使用的移动 App。
当前产品方向已经调整为“轻实用型情侣空间”：让两个人在一个共享空间里
查看首页状态、管理日历、记录计划与随记，并维护“我们”的共同设置。

## 产品焦点

- 构建一个真正的移动 App，而不是网页外壳。
- 把 MVP 收敛到 4 个核心界面：`首页`、`日历`、`计划笔记`、`我们`。
- 把产品做成“低压力的共享生活空间”，而不是重任务感工具或强打卡日记。
- 默认语言为简体中文；多语言基础设施已支持简体中文、繁體中文、English、日本語、한국어。
- 主题模式支持跟随系统、浅色、深色三档。
- 先验证留存，再扩展更多模块。
- 把隐私、数据归属和删除规则当作产品要求，而不是后补的技术项。
- 在共享基础能力被验证之前，不提前铺开低频功能。

## 计划技术栈

- App：Flutter
- 后端：Supabase
- 数据库：通过 Supabase 使用 PostgreSQL
- 身份认证：Supabase Auth
- 存储：Supabase Storage
- 目标平台：Android 优先，之后支持 iOS

## 当前状态

仓库当前包含一个 Android 优先的 Flutter App，特点包括：

- Material 3 App shell
- 已落地一级导航：`首页`、`日历`、`计划笔记`、`我们`
- 邮箱验证码登录与注册分离
- 昵称、性别、生日的注册后资料引导
- Supabase 共享 Alpha：日历事件、计划、随记、邀请流程已接入双人空间同步
- `AppController` 统一持有用户资料、登录状态和当前 `spaceId`
- 主要页面已完成统一视觉系统 rollout
- 已添加导航、日历、空间门禁和认证状态相关 widget tests

本地运行：

```powershell
flutter pub get
flutter test
flutter run
```

## 当前 MVP 定义

当前 MVP 以登录后的共享生活空间为核心闭环：

- 首页展示真实昵称、共享概览、最近动态预览、下一个重要日期和快捷入口。
- 日历展示纪念日、约会、提醒等“有明确日期”的内容。
- 计划笔记展示未定日期的计划，以及自由随记，并接入共享空间同步。
- 我们页面承接个人资料入口、TA / 邀请入口、共享空间信息和二级设置页。
- 单人模式可以先使用核心内容，并通过邀请码进入双人模式。

登录、邀请、共享同步、Row Level Security、个人资料闭环、单人态能力白名单、多语言基础设施第一阶段和双人空间退出机制 MVP 已进入当前基础能力。进入敏感数据或私测 Beta 前，建议先用两个真实账号手工验收邀请配对、退出空间和语言偏好恢复。

## 共享基础规则

共享数据开发必须遵守：

- 谁创建 couple space，以及如何邀请另一方加入。
- 更复杂的关系解绑规则如何处理，例如拒绝、取消、强制退出、超时自动关闭和通知推送。
- 解绑或删除请求发生后，共享数据如何保留、导出或永久删除。
- 数据导出、保留周期和彻底删除的规则。
- 通知、预览和锁屏展示如何避免泄露私密内容。

这些规则现在统一沉淀在
[docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) 和
[docs/architecture/DATABASE.md](docs/architecture/DATABASE.md)。

## 暂缓的模块

在核心闭环被验证前，以下内容明确属于 backlog：

- 礼物想法 / 愿望清单
- 共享照片回忆
- 提醒与通知
- 旅行计划
- 家庭菜单
- 冲突冷静页
- 个人偏好笔记

## 工作文档

- [docs/architecture/ROADMAP.md](docs/architecture/ROADMAP.md)：阶段规划与交付检查点
- [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md)：产品结构与核心规则
- [docs/architecture/DATABASE.md](docs/architecture/DATABASE.md)：共享数据模型与访问边界
- [docs/guides/WORKFLOW.md](docs/guides/WORKFLOW.md)：本仓库的开发工作流

## 许可证

本项目基于 MIT License 授权。
