import 'package:flutter/material.dart';

/// Centralized language configuration for Between Us.
///
/// Each supported language defines its [languageCode], human-readable
/// [displayName], and Flutter [locale]. The static helpers provide
/// code-to-enum lookup with a guaranteed fallback to [zhCn].
///
/// To add a new language:
/// 1. Add a new enum value below.
/// 2. Add string translations in [AppStrings] (core path strings).
/// 3. No changes needed in settings, MaterialApp, or persistence logic.
enum AppLanguage {
  zhCn('zh-CN', '简体中文', Locale('zh', 'CN')),
  zhTw('zh-TW', '繁體中文', Locale('zh', 'TW')),
  en('en', 'English', Locale('en')),
  ja('ja', '日本語', Locale('ja')),
  ko('ko', '한국어', Locale('ko'));

  const AppLanguage(this.languageCode, this.displayName, this.locale);

  /// Stable code used for persistence (e.g. `'zh-CN'`, `'en'`).
  final String languageCode;

  /// Human-readable name shown in the settings language picker.
  final String displayName;

  /// Flutter [Locale] used by [MaterialApp.locale].
  final Locale locale;

  /// The default language used when an unknown code is encountered.
  static const AppLanguage fallback = AppLanguage.zhCn;

  /// Resolve a persisted [code] to an [AppLanguage].
  ///
  /// Returns [fallback] if the code is null, empty, or not recognized.
  /// Also handles legacy values like `'zh'` (maps to [zhCn]).
  static AppLanguage fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return fallback;
    final normalized = code.trim();
    for (final lang in values) {
      if (lang.languageCode == normalized) return lang;
    }
    // Legacy: bare 'zh' → zhCn.
    if (normalized == 'zh') return zhCn;
    return fallback;
  }

  /// All locales that [MaterialApp.supportedLocales] should advertise.
  static List<Locale> get supportedLocales =>
      [for (final lang in values) lang.locale];

  /// Whether the language is a Chinese variant (zh-CN or zh-TW).
  bool get isChinese => this == zhCn || this == zhTw;

  /// Whether the language uses CJK characters (for layout hints).
  bool get isCjk => this == zhCn || this == zhTw || this == ja || this == ko;
}
