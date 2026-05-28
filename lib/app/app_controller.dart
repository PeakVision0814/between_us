import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

enum AppLanguage { zhCn, en }

extension AppLanguageLocale on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.zhCn => const Locale('zh', 'CN'),
    AppLanguage.en => const Locale('en'),
  };
}

enum AppThemePreference { system, light, dark }

enum AppAuthStatus { initializing, unauthenticated, otpSent, authenticated }

class AppController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.zhCn;
  AppThemePreference _themePreference = AppThemePreference.system;
  bool _notificationPreviewEnabled = false;
  bool _supabaseReady = false;
  String? _supabaseFailureReason;
  AppAuthStatus _authStatus = AppAuthStatus.initializing;
  String? _pendingEmail;
  String? _authErrorCode;
  bool _authBusy = false;
  String? _loadedPreferencesUserId;
  StreamSubscription<AuthState>? _authStateSubscription;

  AppLanguage get language => _language;
  AppThemePreference get themePreference => _themePreference;
  bool get notificationPreviewEnabled => _notificationPreviewEnabled;
  bool get supabaseReady => _supabaseReady;
  String? get supabaseFailureReason => _supabaseFailureReason;
  AppAuthStatus get authStatus => _authStatus;
  String? get pendingEmail => _pendingEmail;
  String? get authErrorCode => _authErrorCode;
  bool get authBusy => _authBusy;
  bool get isAuthenticated => _authStatus == AppAuthStatus.authenticated;

  Locale get locale => _language.locale;

  ThemeMode get themeMode => switch (_themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  Future<void> bootstrap() async {
    _authBusy = false;
    _authErrorCode = null;
    _pendingEmail = null;
    _authStatus = AppAuthStatus.initializing;
    _supabaseReady = false;
    _supabaseFailureReason = null;
    notifyListeners();

    await _authStateSubscription?.cancel();
    _authStateSubscription = null;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _supabaseReady = true;
      debugPrint('[Supabase] Initialized with url=${SupabaseConfig.url}');
    } catch (error) {
      _supabaseReady = false;
      _supabaseFailureReason = 'initialize_failed';
      _authStatus = AppAuthStatus.unauthenticated;
      _authErrorCode = 'initialize_failed';
      debugPrint('[Supabase] Initialize failed: $error');
      notifyListeners();
      return;
    }

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          unawaited(_syncSession(data.session));
        });

    await _syncSession(Supabase.instance.client.auth.currentSession);
    debugPrint(
      '[Supabase] Bootstrap ready=$_supabaseReady auth=${_authStatus.name} reason=${_supabaseFailureReason ?? 'none'}',
    );
  }

  void setSupabaseBootstrapState({required bool ready, String? failureReason}) {
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
    _persistProfile({
      'preferred_locale': language == AppLanguage.zhCn ? 'zh-CN' : 'en',
    });
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

  Future<bool> sendEmailOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_supabaseReady) {
      _setAuthError('initialize_failed');
      return false;
    }
    if (!_looksLikeEmail(normalizedEmail)) {
      _setAuthError('invalid_email');
      return false;
    }

    _setAuthBusy(true);
    _authErrorCode = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: normalizedEmail);
      _pendingEmail = normalizedEmail;
      _authStatus = AppAuthStatus.otpSent;
      _authErrorCode = null;
      return true;
    } catch (error) {
      debugPrint('[Auth] Send email OTP failed: $error');
      _authErrorCode = 'otp_send_failed';
      return false;
    } finally {
      _setAuthBusy(false);
    }
  }

  Future<bool> verifyEmailOtp(String token) async {
    if (!_supabaseReady) {
      _setAuthError('initialize_failed');
      return false;
    }
    if (_pendingEmail == null) {
      _setAuthError('missing_pending_email');
      return false;
    }

    final normalizedToken = token.trim();
    if (normalizedToken.length != 6) {
      _setAuthError('invalid_token_length');
      return false;
    }

    _setAuthBusy(true);
    _authErrorCode = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _pendingEmail,
        token: normalizedToken,
        type: OtpType.email,
      );
      await _syncSession(
        response.session ?? Supabase.instance.client.auth.currentSession,
      );
      return isAuthenticated;
    } catch (error) {
      debugPrint('[Auth] Verify email OTP failed: $error');
      _authErrorCode = 'otp_verify_failed';
      return false;
    } finally {
      _setAuthBusy(false);
    }
  }

  void returnToEmailEntry() {
    _pendingEmail = null;
    _authErrorCode = null;
    if (_authStatus != AppAuthStatus.unauthenticated) {
      _authStatus = AppAuthStatus.unauthenticated;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void clearAuthError() {
    if (_authErrorCode == null) {
      return;
    }
    _authErrorCode = null;
    notifyListeners();
  }

  Future<void> loadPreferences({bool force = false}) async {
    if (!_supabaseReady) {
      debugPrint(
        '[Supabase] Skipping loadPreferences because bootstrap is not ready (${_supabaseFailureReason ?? 'unknown'})',
      );
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      if (!force && _loadedPreferencesUserId == userId) {
        return;
      }
      Map<String, dynamic>? profile;
      for (var attempt = 0; attempt < 3; attempt++) {
        profile = await Supabase.instance.client
            .from('profiles')
            .select(
              'preferred_locale, theme_preference, notification_preview_enabled',
            )
            .eq('id', userId)
            .maybeSingle();
        if (profile != null) {
          break;
        }
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
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
      _loadedPreferencesUserId = userId;
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
      Supabase.instance.client
          .from('profiles')
          .update(data)
          .eq('id', userId)
          .then((_) {}, onError: (_) {});
    } catch (_) {
      // Supabase not initialized; skip persistence.
    }
  }

  Future<void> _syncSession(Session? session) async {
    if (session == null) {
      _authStatus = AppAuthStatus.unauthenticated;
      _pendingEmail = null;
      _authErrorCode = null;
      _loadedPreferencesUserId = null;
      _language = AppLanguage.zhCn;
      _themePreference = AppThemePreference.system;
      _notificationPreviewEnabled = false;
      notifyListeners();
      return;
    }

    _authStatus = AppAuthStatus.authenticated;
    _pendingEmail = null;
    _authErrorCode = null;
    notifyListeners();
    await loadPreferences();
  }

  void _setAuthBusy(bool busy) {
    if (_authBusy == busy) {
      return;
    }
    _authBusy = busy;
    notifyListeners();
  }

  void _setAuthError(String errorCode) {
    _authErrorCode = errorCode;
    notifyListeners();
  }

  bool _looksLikeEmail(String value) {
    final atIndex = value.indexOf('@');
    return atIndex > 0 && atIndex < value.length - 1;
  }

  @visibleForTesting
  void debugSetAuthState({
    required AppAuthStatus status,
    bool supabaseReady = false,
    String? pendingEmail,
    String? authErrorCode,
  }) {
    _authStatus = status;
    _supabaseReady = supabaseReady;
    _pendingEmail = pendingEmail;
    _authErrorCode = authErrorCode;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
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
