import 'package:flutter/material.dart';

enum AppLanguage { zhCn, en }

extension AppLanguageLocale on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.zhCn => const Locale('zh', 'CN'),
    AppLanguage.en => const Locale('en'),
  };
}

enum AppThemePreference { system, light, dark }

class AppController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.zhCn;
  AppThemePreference _themePreference = AppThemePreference.system;
  bool _lockScreenPreviewEnabled = false;

  AppLanguage get language => _language;
  AppThemePreference get themePreference => _themePreference;
  bool get lockScreenPreviewEnabled => _lockScreenPreviewEnabled;

  Locale get locale => _language.locale;

  ThemeMode get themeMode => switch (_themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }

  void setThemePreference(AppThemePreference preference) {
    if (_themePreference == preference) {
      return;
    }
    _themePreference = preference;
    notifyListeners();
  }

  void setLockScreenPreviewEnabled(bool enabled) {
    if (_lockScreenPreviewEnabled == enabled) {
      return;
    }
    _lockScreenPreviewEnabled = enabled;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
