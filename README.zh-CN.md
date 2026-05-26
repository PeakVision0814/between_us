# Between Us

[English](README.md)

Between Us 是一款以隐私优先为原则、面向情侣两个人使用的移动 App。
当前产品方向已经调整为“轻实用型情侣空间”：让两个人在一个共享空间里
查看首页状态、管理日历、记录计划与随记，并维护“我们”的共同设置。

## 产品焦点

- 构建一个真正的移动 App，而不是网页外壳。
- 把 MVP 收敛到 4 个核心界面：`首页`、`日历`、`计划笔记`、`我们`。
- 把产品做成“低压力的共享生活空间”，而不是重任务感工具或强打卡日记。
- 默认语言为简体中文，并在设置中提供 English 选项。
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

## 当前原型

仓库当前包含一个 Android 优先的 Flutter 原型，特点包括：

- Material 3 App shell
- 产品规划中的一级导航目标：`首页`、`日历`、`计划笔记`、`我们`
- 第一版原型使用纯本地示例内容
- 当前代码结构仍在从旧的信息架构向新规划迁移
- 已加入 Supabase 依赖，但本地原型还没有接入登录与同步
- 已添加导航和核心入口的 widget tests

本地运行：

```powershell
flutter pub get
flutter test
flutter run
```

## MVP 定义

只有在不依赖后端的前提下，完整演示下面这个本地产品闭环，第一版原型才算完成：

- 首页展示两个人的共享概览、最近动态预览、下一个重要日期和快捷入口。
- 日历展示纪念日、约会、提醒等“有明确日期”的内容。
- 计划笔记展示未定日期的计划，以及自由随记。
- 我们页面提供个人偏好和双人共享设置。
- 界面能清楚区分哪些页面属于 MVP，哪些仍然只是 backlog。

登录、邀请、共享同步和 Row Level Security 不属于本地原型范围，
它们属于下一阶段的共享数据基础建设。

## 进入后端前必须先明确的规则

在开始共享数据开发前，团队必须先定义：

- 谁创建 couple space，以及如何邀请另一方加入。
- 关系解绑、成员退出和权限撤销如何处理。
- 解绑或删除请求发生后，共享数据如何保留、导出或永久删除。
- 数据导出、保留周期和彻底删除的规则。
- 通知、预览和锁屏展示如何避免泄露私密内容。

这些规则现在统一沉淀在
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 和
[docs/DATABASE.md](docs/DATABASE.md)。

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

- [docs/ROADMAP.md](docs/ROADMAP.md)：阶段规划与交付检查点
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)：产品结构与核心规则
- [docs/DATABASE.md](docs/DATABASE.md)：共享数据模型与访问边界
- [docs/WORKFLOW.md](docs/WORKFLOW.md)：本仓库的开发工作流

## 许可证

本项目基于 MIT License 授权。
