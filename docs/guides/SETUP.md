# 本地开发环境

这个项目是一个 Android 优先的 Flutter App，已接入 Supabase
实现认证、邀请和共享数据能力。

## 环境要求

- Flutter stable
- Android Studio 或 Android SDK 命令行工具
- 已为 Flutter 正确配置 Android SDK
- 用于本地运行和共享数据调试的 Supabase 项目

在修改产品行为前，建议先阅读这些文档：

- `docs/architecture/ROADMAP.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/architecture/DATABASE.md`
- `docs/guides/WORKFLOW.md`

## 验证 Flutter

```powershell
flutter doctor -v
```

Flutter SDK 本身必须通过检查。对于 Android 开发，Android toolchain
也必须正确配置。

如果 Android SDK 已经安装，但 Flutter 仍然找不到，可以运行：

```powershell
flutter config --android-sdk "C:\Users\<you>\AppData\Local\Android\Sdk"
flutter doctor --android-licenses
flutter doctor -v
```

## 运行 App

```powershell
flutter pub get
flutter run
flutter run -d 391QYGCJ226AE --dart-define=SUPABASE_URL=http://192.168.5.20:54321 --dart-define=SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
flutter run -d emulator-5554
```

## Supabase 配置说明

项目里已经加入 Supabase 依赖，App 启动时由 `AppController` 初始化 Supabase。
不要提交任何私钥或本地敏感配置。

当前约束：

- App 侧只使用公开的 anon 配置
- 数据库访问必须通过 Row Level Security 保护
