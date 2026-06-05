import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'language_config.dart';
import 'supabase_config.dart';

export 'language_config.dart' show AppLanguage;

enum AppThemePreference { system, light, dark }

enum AppAuthStatus { initializing, unauthenticated, otpSent, authenticated }

class AppController extends ChangeNotifier {
  static const String defaultDisplayNamePlaceholder = '新的用户';
  static const String genderUnset = 'unset';
  static const String genderMale = 'male';
  static const String genderFemale = 'female';

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
  String? _displayName;
  String? _gender;
  DateTime? _birthday;
  String? _selfProfileId;
  String? _currentSpaceId;
  int _memberCount = 0;
  String? _partnerDisplayName;
  bool _profileCheckInProgress = false;
  bool _profileSaveInProgress = false;
  String? _profileErrorCode;
  StreamSubscription<AuthState>? _authStateSubscription;
  Future<void> _sessionSyncQueue = Future<void>.value();
  Future<void> Function()? _debugSignOutAction;
  RealtimeChannel? _realtimeChannel;

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
  bool get signOutInProgress => _authBusy && isAuthenticated;
  String? get displayName => _displayName;
  String? get gender => _gender;
  DateTime? get birthday => _birthday;
  String? get email {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  String? get selfProfileId => _selfProfileId;
  String? get currentSpaceId => _currentSpaceId;
  int get memberCount => _memberCount;
  String? get partnerDisplayName => _partnerDisplayName;
  bool get hasActiveCoupleSpace => _memberCount >= 2 && _currentSpaceId != null;
  bool get profileCheckInProgress => _profileCheckInProgress;
  bool get profileSaveInProgress => _profileSaveInProgress;
  String? get profileErrorCode => _profileErrorCode;
  bool get appReady =>
      _supabaseReady &&
      isAuthenticated &&
      _currentSpaceId != null &&
      !_profileCheckInProgress;
  bool get requiresProfileSetup =>
      isAuthenticated &&
      !_profileCheckInProgress &&
      (!_hasCompletedDisplayName(_displayName) ||
          !_hasCompletedGender(_gender));

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
    _sessionSyncQueue = Future<void>.value();

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
    _persistProfile({'preferred_locale': language.languageCode});
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
      await Supabase.instance.client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: false,
      );
      _pendingEmail = normalizedEmail;
      _authStatus = AppAuthStatus.otpSent;
      _authErrorCode = null;
      return true;
    } catch (error) {
      debugPrint('[Auth] Send email OTP failed: $error');
      _authErrorCode = _isUserNotRegisteredError(error)
          ? 'user_not_registered'
          : 'otp_send_failed';
      return false;
    } finally {
      _setAuthBusy(false);
    }
  }

  Future<bool> signUpWithEmail(String email) async {
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
      await Supabase.instance.client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
      );
      _pendingEmail = normalizedEmail;
      _authStatus = AppAuthStatus.otpSent;
      _authErrorCode = null;
      return true;
    } catch (error) {
      debugPrint('[Auth] Sign up with email failed: $error');
      _authErrorCode = _isUserAlreadyRegisteredError(error)
          ? 'user_already_registered'
          : 'signup_send_failed';
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

  Future<bool> signOut() async {
    if (!_supabaseReady) {
      _setAuthError('initialize_failed');
      return false;
    }
    if (_authBusy) {
      return false;
    }

    _setAuthBusy(true);
    _authErrorCode = null;
    notifyListeners();

    try {
      final signOutAction =
          _debugSignOutAction ??
          (() => Supabase.instance.client.auth.signOut());
      await signOutAction();
      await _syncSession(null);
      return true;
    } catch (error) {
      debugPrint('[Auth] Sign out failed: $error');
      _authErrorCode = 'sign_out_failed';
      notifyListeners();
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
      if (userId == null) {
        return;
      }
      if (!force && _loadedPreferencesUserId == userId) {
        return;
      }
      final client = Supabase.instance.client;
      Map<String, dynamic>? profile;
      for (var attempt = 0; attempt < 3; attempt++) {
        final response = await client.rpc('get_my_profile');
        final rows = switch (response) {
          final List<dynamic> r when r.isNotEmpty =>
            r.first as Map<String, dynamic>,
          final Map<String, dynamic> row => row,
          _ => null,
        };
        if (rows != null) {
          profile = rows;
          break;
        }
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
      if (profile == null) {
        return;
      }

      String? currentSpaceId;
      var memberCount = 0;
      String? partnerDisplayName;
      currentSpaceId = await _loadOrCreateCurrentSpaceId(client, userId);
      if (currentSpaceId != null) {
        final memberships = await client
            .from('couple_memberships')
            .select('profile_id')
            .eq('couple_space_id', currentSpaceId)
            .eq('status', 'active');
        final activeMemberships = (memberships as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList();
        memberCount = activeMemberships.length > 2
            ? 2
            : activeMemberships.length;
        String? partnerProfileId;
        for (final row in activeMemberships) {
          final profileId = row['profile_id'] as String?;
          if (profileId != null && profileId != userId) {
            partnerProfileId = profileId;
            break;
          }
        }
        if (partnerProfileId != null) {
          final partnerResponse = await client.rpc(
            'get_partner_public_profile',
            params: {'p_profile_id': partnerProfileId},
          );
          final partnerRow = switch (partnerResponse) {
            final List<dynamic> r when r.isNotEmpty =>
              r.first as Map<String, dynamic>,
            final Map<String, dynamic> row => row,
            _ => null,
          };
          partnerDisplayName = partnerRow?['display_name'] as String?;
        }
      }

      var changed = false;
      if (_selfProfileId != userId) {
        _selfProfileId = userId;
        changed = true;
      }
      final displayName = profile['display_name'] as String?;
      if (_displayName != displayName) {
        _displayName = displayName;
        changed = true;
      }
      final gender = profile['gender'] as String?;
      if (_gender != gender) {
        _gender = gender;
        changed = true;
      }
      final birthday = _parseBirthday(profile['birthday']);
      if (_birthday != birthday) {
        _birthday = birthday;
        changed = true;
      }
      if (_currentSpaceId != currentSpaceId) {
        _currentSpaceId = currentSpaceId;
        changed = true;
      }
      if (_memberCount != memberCount) {
        _memberCount = memberCount;
        changed = true;
      }
      if (_partnerDisplayName != partnerDisplayName) {
        _partnerDisplayName = partnerDisplayName;
        changed = true;
      }
      final locale = profile['preferred_locale'] as String?;
      if (locale != null) {
        final lang = AppLanguage.fromCode(locale);
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
      // 订阅 Realtime（如果空间 ID 变化或首次加载）
      _subscribeToRealtime();
      if (changed) notifyListeners();
    } catch (error) {
      if (_isJwtExpired(error)) {
        rethrow;
      }
      // Supabase not initialized or query failed; keep defaults.
    }
  }

  Future<bool> saveProfileSetup({
    required String displayName,
    required String gender,
    DateTime? birthday,
  }) async {
    final normalizedDisplayName = displayName.trim();
    final normalizedGender = gender.trim();
    final normalizedBirthday = birthday == null
        ? null
        : DateUtils.dateOnly(birthday);
    if (!_supabaseReady) {
      _setProfileError('initialize_failed');
      return false;
    }
    if (!_isValidDisplayName(normalizedDisplayName)) {
      _setProfileError('invalid_display_name');
      return false;
    }
    if (!_isValidGender(normalizedGender)) {
      _setProfileError('invalid_gender');
      return false;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _setProfileError('missing_user');
      return false;
    }

    _profileSaveInProgress = true;
    _profileErrorCode = null;
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': normalizedDisplayName,
            'gender': normalizedGender,
            'birthday': _formatBirthdayForStorage(normalizedBirthday),
          })
          .eq('id', userId);
      _displayName = normalizedDisplayName;
      _gender = normalizedGender;
      _birthday = normalizedBirthday;
      _profileErrorCode = null;
      notifyListeners();
      // Profile saved — reload preferences to create couple space if needed.
      await loadPreferences(force: true);
      return true;
    } catch (error) {
      debugPrint('[Profile] Save setup failed: $error');
      if (_isJwtExpired(error)) {
        _profileErrorCode = 'session_expired';
        notifyListeners();
        await _handleExpiredSession();
      } else {
        _profileErrorCode = 'save_failed';
        notifyListeners();
      }
      return false;
    } finally {
      _profileSaveInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> saveDisplayName(String value) {
    return saveProfileSetup(
      displayName: value,
      gender: _gender ?? genderUnset,
      birthday: _birthday,
    );
  }

  /// 订阅 Supabase Realtime，监听当前空间的数据变化。
  /// 当 couple_spaces / calendar_events / plans / notes 发生变更时，
  /// 自动调用 loadPreferences 刷新数据并 notifyListeners。
  void _subscribeToRealtime() {
    _unsubscribeFromRealtime();

    final spaceId = _currentSpaceId;
    if (spaceId == null || !_supabaseReady) return;

    final client = Supabase.instance.client;

    _realtimeChannel = client
        .channel('public:space:$spaceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'couple_spaces',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: spaceId,
          ),
          callback: (_) => _onRealtimeDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendar_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_space_id',
            value: spaceId,
          ),
          callback: (_) => _onRealtimeDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_space_id',
            value: spaceId,
          ),
          callback: (_) => _onRealtimeDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_space_id',
            value: spaceId,
          ),
          callback: (_) => _onRealtimeDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'anniversaries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_space_id',
            value: spaceId,
          ),
          callback: (_) => _onRealtimeDataChanged(),
        )
        .subscribe();
  }

  void _unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  void _onRealtimeDataChanged() {
    debugPrint('[Realtime] Data changed, refreshing preferences');
    _loadedPreferencesUserId = null;
    loadPreferences(force: true);
  }

  /// 刷新当前用户的空间和成员状态。
  /// 在接受邀请成功后调用，确保 AppController 持有的
  /// currentSpaceId、memberCount、partnerDisplayName 等字段同步更新。
  Future<void> refreshAfterInviteAccepted() async {
    _loadedPreferencesUserId = null;
    await loadPreferences(force: true);
  }

  /// 供页面下拉刷新调用，强制重新加载所有数据。
  Future<void> refreshAllData() async {
    _loadedPreferencesUserId = null;
    await loadPreferences(force: true);
  }

  void clearProfileError() {
    if (_profileErrorCode == null) {
      return;
    }
    _profileErrorCode = null;
    notifyListeners();
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

  Future<void> _syncSession(
    Session? session, {
    bool forceBlockingProfileCheck = false,
  }) {
    _sessionSyncQueue = _sessionSyncQueue
        .catchError((Object _, StackTrace _) {})
        .then(
          (_) => _applySessionSnapshot(
            userId: session?.user.id,
            forceBlockingProfileCheck: forceBlockingProfileCheck,
            reloadProfile: loadPreferences,
          ),
        );
    return _sessionSyncQueue;
  }

  Future<void> _applySessionSnapshot({
    required String? userId,
    required Future<void> Function({bool force}) reloadProfile,
    bool forceBlockingProfileCheck = false,
  }) async {
    if (userId == null) {
      _clearAuthenticatedState();
      return;
    }

    final shouldBlockForProfileCheck =
        forceBlockingProfileCheck ||
        _authStatus != AppAuthStatus.authenticated ||
        _loadedPreferencesUserId != userId;

    var shouldNotify = false;
    if (_authStatus != AppAuthStatus.authenticated) {
      _authStatus = AppAuthStatus.authenticated;
      shouldNotify = true;
    }
    if (_pendingEmail != null) {
      _pendingEmail = null;
      shouldNotify = true;
    }
    if (_authErrorCode != null) {
      _authErrorCode = null;
      shouldNotify = true;
    }
    if (_profileErrorCode != null) {
      _profileErrorCode = null;
      shouldNotify = true;
    }

    if (!shouldBlockForProfileCheck) {
      if (_profileCheckInProgress) {
        _profileCheckInProgress = false;
        shouldNotify = true;
      }
      if (shouldNotify) {
        notifyListeners();
      }
      return;
    }

    if (!_profileCheckInProgress) {
      _profileCheckInProgress = true;
      shouldNotify = true;
    }
    if (shouldNotify) {
      notifyListeners();
    }

    try {
      await reloadProfile(force: true);
    } catch (error) {
      debugPrint('[Auth] Profile reload failed: $error');
      if (_isJwtExpired(error)) {
        await _handleExpiredSession();
        return;
      }
    }
    if (_profileCheckInProgress) {
      _profileCheckInProgress = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void debugSeedLoadedProfile({
    required String? userId,
    String? displayName,
    String? gender,
    DateTime? birthday,
    String? currentSpaceId,
    int memberCount = 0,
    String? partnerDisplayName,
  }) {
    _loadedPreferencesUserId = userId;
    _selfProfileId = userId;
    _displayName = displayName;
    _gender = gender;
    _birthday = birthday;
    _currentSpaceId = currentSpaceId;
    _memberCount = memberCount;
    _partnerDisplayName = partnerDisplayName;
  }

  @visibleForTesting
  Future<void> debugSyncSessionUser(
    String? userId, {
    Future<void> Function({bool force})? onReloadProfile,
    bool forceBlockingProfileCheck = false,
  }) {
    return _applySessionSnapshot(
      userId: userId,
      forceBlockingProfileCheck: forceBlockingProfileCheck,
      reloadProfile: onReloadProfile ?? ({bool force = false}) async {},
    );
  }

  @visibleForTesting
  Future<void> debugClearSessionForTest() {
    return _applySessionSnapshot(
      userId: null,
      reloadProfile: ({bool force = false}) async {},
    );
  }

  @visibleForTesting
  void debugSetSignOutAction(Future<void> Function()? action) {
    _debugSignOutAction = action;
  }

  /// 清理已登录态数据，将 authStatus 设为 unauthenticated。
  /// 供 userId == null 和 JWT expired 两条路径共用。
  void _clearAuthenticatedState() {
    _unsubscribeFromRealtime();
    _authStatus = AppAuthStatus.unauthenticated;
    _pendingEmail = null;
    _authErrorCode = null;
    _loadedPreferencesUserId = null;
    _displayName = null;
    _gender = null;
    _birthday = null;
    _selfProfileId = null;
    _currentSpaceId = null;
    _memberCount = 0;
    _partnerDisplayName = null;
    _profileCheckInProgress = false;
    _profileSaveInProgress = false;
    _profileErrorCode = null;
    _language = AppLanguage.zhCn;
    _themePreference = AppThemePreference.system;
    _notificationPreviewEnabled = false;
    notifyListeners();
  }

  /// 内部会话过期处理：清理本地状态，不走 signOut() / _syncSession 队列。
  Future<void> _handleExpiredSession() async {
    debugPrint('[Auth] Session expired, clearing local state');
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // 忽略 Supabase auth.signOut() 的异常
    }
    _clearAuthenticatedState();
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

  void _setProfileError(String errorCode) {
    _profileErrorCode = errorCode;
    notifyListeners();
  }

  bool _looksLikeEmail(String value) {
    final atIndex = value.indexOf('@');
    return atIndex > 0 && atIndex < value.length - 1;
  }

  Future<String?> _loadOrCreateCurrentSpaceId(
    SupabaseClient client,
    String userId,
  ) async {
    final membership = await _loadCurrentMembership(client, userId);
    final existingSpaceId = membership?['couple_space_id'] as String?;
    if (existingSpaceId != null && existingSpaceId.isNotEmpty) {
      return existingSpaceId;
    }

    try {
      final response = await client.rpc('create_couple_space');
      final createdSpaceId = switch (response) {
        final String id when id.isNotEmpty => id,
        final Map<String, dynamic> row => row['id'] as String?,
        final List<dynamic> rows when rows.isNotEmpty =>
          (rows.first as Map<String, dynamic>)['id'] as String?,
        _ => null,
      };
      if (createdSpaceId != null && createdSpaceId.isNotEmpty) {
        return createdSpaceId;
      }
    } catch (error) {
      debugPrint('[Space] create_couple_space failed: $error');
    }

    final refetchedMembership = await _loadCurrentMembership(client, userId);
    return refetchedMembership?['couple_space_id'] as String?;
  }

  Future<Map<String, dynamic>?> _loadCurrentMembership(
    SupabaseClient client,
    String userId,
  ) {
    return client
        .from('couple_memberships')
        .select('couple_space_id')
        .eq('profile_id', userId)
        .eq('status', 'active')
        .maybeSingle();
  }

  bool _isUserNotRegisteredError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('signups not allowed for otp') ||
        message.contains('user not found') ||
        message.contains('not registered');
  }

  bool _isUserAlreadyRegisteredError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user already exists');
  }

  bool _isJwtExpired(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('jwt expired') ||
        message.contains('pgrst303') ||
        (message.contains('unauthorized') && message.contains('jwt'));
  }

  bool _isValidDisplayName(String value) {
    final length = value.characters.length;
    return length >= 1 &&
        length <= 40 &&
        value != defaultDisplayNamePlaceholder;
  }

  bool _isValidGender(String value) {
    return value == genderMale || value == genderFemale;
  }

  bool _hasCompletedDisplayName(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return false;
    }
    return normalizedValue != defaultDisplayNamePlaceholder;
  }

  bool _hasCompletedGender(String? value) {
    return value == genderMale || value == genderFemale;
  }

  DateTime? _parseBirthday(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateUtils.dateOnly(DateTime.parse(value));
  }

  String? _formatBirthdayForStorage(DateTime? value) {
    if (value == null) {
      return null;
    }
    final normalized = DateUtils.dateOnly(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  @visibleForTesting
  void debugSetAuthState({
    required AppAuthStatus status,
    bool supabaseReady = false,
    String? pendingEmail,
    String? authErrorCode,
    String? displayName,
    String? gender,
    DateTime? birthday,
    String? selfProfileId,
    String? currentSpaceId,
    int memberCount = 0,
    String? partnerDisplayName,
    bool profileCheckInProgress = false,
    String? profileErrorCode,
  }) {
    _authStatus = status;
    _supabaseReady = supabaseReady;
    _pendingEmail = pendingEmail;
    _authErrorCode = authErrorCode;
    _displayName = displayName;
    _gender = gender;
    _birthday = birthday;
    _selfProfileId = selfProfileId;
    _currentSpaceId = currentSpaceId;
    _memberCount = memberCount;
    _partnerDisplayName = partnerDisplayName;
    _profileCheckInProgress = profileCheckInProgress;
    _profileErrorCode = profileErrorCode;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribeFromRealtime();
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
