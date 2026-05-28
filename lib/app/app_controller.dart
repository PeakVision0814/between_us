import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _notificationPreviewEnabled = false;
  bool _supabaseReady = false;
  String? _supabaseFailureReason;

  AppLanguage get language => _language;
  AppThemePreference get themePreference => _themePreference;
  bool get notificationPreviewEnabled => _notificationPreviewEnabled;
  bool get supabaseReady => _supabaseReady;
  String? get supabaseFailureReason => _supabaseFailureReason;

  Locale get locale => _language.locale;

  ThemeMode get themeMode => switch (_themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  void setSupabaseBootstrapState({
    required bool ready,
    String? failureReason,
  }) {
    if (_supabaseReady == ready && _supabaseFailureReason == failureReason) {
      return;
    }
    _supabaseReady = ready;
    _supabaseFailureReason = failureReason;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
    _persistProfile({'preferred_locale': language == AppLanguage.zhCn ? 'zh-CN' : 'en'});
  }

  void setThemePreference(AppThemePreference preference) {
    if (_themePreference == preference) {
      return;
    }
    _themePreference = preference;
    notifyListeners();
    _persistProfile({'theme_preference': preference.name});
  }

  void setNotificationPreviewEnabled(bool enabled) {
    if (_notificationPreviewEnabled == enabled) {
      return;
    }
    _notificationPreviewEnabled = enabled;
    notifyListeners();
    _persistProfile({'notification_preview_enabled': enabled});
  }

  Future<void> loadPreferences() async {
    if (!_supabaseReady) {
      debugPrint(
        '[Supabase] Skipping loadPreferences because bootstrap is not ready (${_supabaseFailureReason ?? 'unknown'})',
      );
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('preferred_locale, theme_preference, notification_preview_enabled')
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) return;
      var changed = false;
      final locale = profile['preferred_locale'] as String?;
      if (locale != null) {
        final lang = locale == 'en' ? AppLanguage.en : AppLanguage.zhCn;
        if (_language != lang) {
          _language = lang;
          changed = true;
        }
      }
      final theme = profile['theme_preference'] as String?;
      if (theme != null) {
        final pref = switch (theme) {
          'light' => AppThemePreference.light,
          'dark' => AppThemePreference.dark,
          _ => AppThemePreference.system,
        };
        if (_themePreference != pref) {
          _themePreference = pref;
          changed = true;
        }
      }
      final notif = profile['notification_preview_enabled'] as bool?;
      if (notif != null && _notificationPreviewEnabled != notif) {
        _notificationPreviewEnabled = notif;
        changed = true;
      }
      if (changed) notifyListeners();
    } catch (_) {
      // Supabase not initialized or query failed; keep defaults.
    }
  }

  void _persistProfile(Map<String, dynamic> data) {
    if (!_supabaseReady) {
      debugPrint(
        '[Supabase] Skipping profile persistence because bootstrap is not ready (${_supabaseFailureReason ?? 'unknown'})',
      );
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      Supabase.instance.client.from('profiles').update(data).eq('id', userId).then(
        (_) {},
        onError: (_) {},
      );
    } catch (_) {
      // Supabase not initialized; skip persistence.
    }
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

  static AppController read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
