# Between Us

[English](README.md)

Between Us 是一款以隐私优先为原则、面向情侣两个人使用的移动 App。
当前产品假设会刻意收缩：先验证“今天留一句话或一条小记录，再把重要日子一直放在眼前”
这个闭环，确认它值得被每天打开，再考虑继续扩展。

## 产品焦点

- 构建一个真正的移动 App，而不是网页外壳。
- 把 MVP 收敛到一个日常闭环：留言、记录、纪念日。
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
- 聚焦型一级导航：`Home`、`Timeline`、`Dates`
- 第一版原型使用纯本地示例内容
- backlog 想法页和关系设置页作为二级页面保留
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

- Home 展示两个人的共享概览、今日留言入口和下一个重要日期。
- Timeline 展示产品希望培养的轻量日常记录行为。
- Dates 展示核心纪念日及其倒计时价值。
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

## 许可证

本项目基于 MIT License 授权。
