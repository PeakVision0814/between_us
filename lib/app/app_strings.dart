import 'package:flutter/material.dart';

import 'app_controller.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  /// Whether the current language is a Chinese variant (zh-CN or zh-TW).
  /// Used for layout/formatting hints and as a fallback gate for inline copy.
  bool get isChinese => language.isChinese;

  static AppStrings of(BuildContext context) {
    final controller = AppScope.of(context);
    return AppStrings._(controller.language);
  }

  /// Resolve a string for the current language with automatic fallback to zh-CN.
  ///
  /// Every string getter should call this instead of using `isChinese ? ... : ...`.
  /// Core path strings provide all 5 translations; non-core strings provide
  /// zh-CN + en and let other languages fall back to zh-CN.
  String _resolve({
    required String zhCn,
    String? zhTw,
    String? en,
    String? ja,
    String? ko,
  }) {
    return switch (language) {
      AppLanguage.zhCn => zhCn,
      AppLanguage.zhTw => zhTw ?? zhCn,
      AppLanguage.en => en ?? zhCn,
      AppLanguage.ja => ja ?? zhCn,
      AppLanguage.ko => ko ?? zhCn,
    };
  }

  String get appName => 'Between Us';
  String get authSignInTitle => _resolve(
    zhCn: '登录',
    zhTw: '登入',
    en: 'Sign In',
    ja: 'ログイン',
    ko: '로그인',
  );
  String get authRegisterTitle => _resolve(
    zhCn: '创建账号',
    zhTw: '建立帳號',
    en: 'Create Account',
    ja: 'アカウント作成',
    ko: '계정 생성',
  );
  String get authSignInSubtitle => _resolve(
    zhCn: '登录后才能进入属于你们的情侣共享空间。',
    zhTw: '登入後才能進入屬於你們的情侶共享空間。',
    en: 'Sign in before entering your shared space together.',
    ja: 'ログインしてから二人の共有スペースに入りましょう。',
    ko: '로그인 후 두 사람의 공유 공간에 들어갈 수 있습니다.',
  );
  String get authRegisterSubtitle => _resolve(
    zhCn: '为你们的情侣共享空间创建一个新账号。',
    zhTw: '為你們的情侶共享空間建立一個新帳號。',
    en: 'Create a new account for your shared couple space.',
    ja: '二人の共有スペース用の新しいアカウントを作成します。',
    ko: '두 사람의 공유 공간을 위한 새 계정을 만드세요.',
  );
  String get authCheckingSessionLabel => _resolve(
    zhCn: '正在检查登录状态...',
    zhTw: '正在檢查登入狀態...',
    en: 'Checking your session...',
    ja: 'セッションを確認中...',
    ko: '세션 확인 중...',
  );
  String get authRetryLabel => _resolve(
    zhCn: '重试',
    zhTw: '重試',
    en: 'Retry',
    ja: '再試行',
    ko: '재시도',
  );
  String get authEmailLabel => _resolve(
    zhCn: '邮箱',
    zhTw: '電子郵件',
    en: 'Email',
    ja: 'メールアドレス',
    ko: '이메일',
  );
  String get authEmailHint => _resolve(
    zhCn: '输入接收验证码的邮箱',
    zhTw: '輸入接收驗證碼的電子郵件',
    en: 'Enter the email that should receive the code',
    ja: '認証コードを受け取るメールアドレスを入力',
    ko: '인증 코드를 받을 이메일을 입력하세요',
  );
  String get authEmailMethodLabel => _resolve(
    zhCn: '邮箱',
    zhTw: '電子郵件',
    en: 'Email',
  );
  String get authPhoneMethodLabel => _resolve(
    zhCn: '手机号',
    zhTw: '手機號',
    en: 'Phone',
  );
  String get authPhoneLabel => _resolve(
    zhCn: '手机号',
    zhTw: '手機號',
    en: 'Phone number',
  );
  String get authPhoneHint => _resolve(
    zhCn: '请输入 E.164 格式，例如 +8613812345678',
    zhTw: '請輸入 E.164 格式，例如 +8613812345678',
    en: 'Use E.164 format, for example +8613812345678',
  );
  String get authOtpLabel => _resolve(
    zhCn: '验证码',
    zhTw: '驗證碼',
    en: 'Verification code',
    ja: '認証コード',
    ko: '인증 코드',
  );
  String get authOtpHint => _resolve(
    zhCn: '输入 6 位数字',
    zhTw: '輸入 6 位數字',
    en: 'Enter 6 digits',
    ja: '6桁の数字を入力',
    ko: '6자리 숫자 입력',
  );
  String get authChangeEmailLabel => _resolve(
    zhCn: '更换邮箱',
    zhTw: '更換電子郵件',
    en: 'Change email',
    ja: 'メールアドレス変更',
    ko: '이메일 변경',
  );
  String get authChangePhoneLabel => _resolve(
    zhCn: '更换手机号',
    zhTw: '更換手機號',
    en: 'Change phone',
  );
  String get authSendSignInCodeLabel => _resolve(
    zhCn: '发送登录验证码',
    zhTw: '發送登入驗證碼',
    en: 'Send sign-in code',
    ja: 'ログインコードを送信',
    ko: '로그인 코드 전송',
  );
  String get authSendRegisterCodeLabel => _resolve(
    zhCn: '发送注册验证码',
    zhTw: '發送註冊驗證碼',
    en: 'Send sign-up code',
    ja: '登録コードを送信',
    ko: '가입 코드 전송',
  );
  String get authSendPhoneSignInCodeLabel => _resolve(
    zhCn: '发送手机号登录验证码',
    zhTw: '發送手機號登入驗證碼',
    en: 'Send phone sign-in code',
  );
  String get authSendPhoneRegisterCodeLabel => _resolve(
    zhCn: '发送手机号注册验证码',
    zhTw: '發送手機號註冊驗證碼',
    en: 'Send phone sign-up code',
  );
  String get authVerifyAndSignInLabel => _resolve(
    zhCn: '验证并登录',
    zhTw: '驗證並登入',
    en: 'Verify and sign in',
    ja: '確認してログイン',
    ko: '확인 후 로그인',
  );
  String get authVerifyAndCreateAccountLabel => _resolve(
    zhCn: '验证并创建账号',
    zhTw: '驗證並建立帳號',
    en: 'Verify and create account',
    ja: '確認してアカウント作成',
    ko: '확인 후 계정 생성',
  );
  String get authGoRegisterLabel => _resolve(
    zhCn: '没有账号？去注册',
    zhTw: '沒有帳號？去註冊',
    en: 'No account? Create one',
    ja: 'アカウントがない方は新規登録',
    ko: '계정이 없으신가요? 가입하기',
  );
  String get authGoSignInLabel => _resolve(
    zhCn: '已有账号？去登录',
    zhTw: '已有帳號？去登入',
    en: 'Already have an account? Sign in',
    ja: 'アカウントをお持ちの方はログイン',
    ko: '이미 계정이 있으신가요? 로그인',
  );
  String get authOtpStepSubtitle => _resolve(
    zhCn: '请在 App 内输入 6 位验证码完成验证。',
    zhTw: '請在 App 內輸入 6 位驗證碼完成驗證。',
    en: 'Enter the 6-digit code here to complete verification.',
    ja: '6桁のコードを入力して認証を完了してください。',
    ko: '6자리 코드를 입력하여 인증을 완료하세요.',
  );
  String authCodeSentTo(String email) => _resolve(
    zhCn: '验证码已发送至 $email',
    zhTw: '驗證碼已發送至 $email',
    en: 'A code has been sent to $email',
    ja: 'コードが$emailに送信されました',
    ko: '코드가 $email로 전송되었습니다',
  );
  String authPhoneCodeSentTo(String phone) => _resolve(
    zhCn: '验证码已发送至 $phone',
    zhTw: '驗證碼已發送至 $phone',
    en: 'A code has been sent to $phone',
  );
  String get authOtpSentToast => _resolve(
    zhCn: '验证码已发送，请在 App 内输入 6 位验证码',
    zhTw: '驗證碼已發送，請在 App 內輸入 6 位驗證碼',
    en: 'Verification code sent. Enter the 6-digit code in the app.',
    ja: '認証コードを送信しました。App内で6桁のコードを入力してください。',
    ko: '인증 코드가 전송되었습니다. 앱에서 6자리 코드를 입력하세요.',
  );
  String get authRegisterOtpSentToast => _resolve(
    zhCn: '注册验证码已发送，请在 App 内输入 6 位验证码',
    zhTw: '註冊驗證碼已發送，請在 App 內輸入 6 位驗證碼',
    en: 'Registration code sent. Enter the 6-digit code in the app.',
    ja: '登録コードを送信しました。App内で6桁のコードを入力してください。',
    ko: '가입 코드가 전송되었습니다. 앱에서 6자리 코드를 입력하세요.',
  );
  String get authPhoneOtpSentToast => _resolve(
    zhCn: '手机号验证码已发送，请在 App 内输入 6 位验证码',
    zhTw: '手機號驗證碼已發送，請在 App 內輸入 6 位驗證碼',
    en: 'Phone code sent. Enter the 6-digit code in the app.',
  );
  String get authPhoneRegisterOtpSentToast => _resolve(
    zhCn: '手机号注册验证码已发送，请在 App 内输入 6 位验证码',
    zhTw: '手機號註冊驗證碼已發送，請在 App 內輸入 6 位驗證碼',
    en: 'Phone registration code sent. Enter the 6-digit code in the app.',
  );
  String get authInitializeFailedMessage => _resolve(
    zhCn: '登录服务初始化失败，请检查 Supabase 配置后重试。',
    zhTw: '登入服務初始化失敗，請檢查 Supabase 設定後重試。',
    en: 'Failed to initialize auth. Check Supabase configuration and try again.',
    ja: '認証サービスの初期化に失敗しました。Supabaseの設定を確認してください。',
    ko: '인증 서비스 초기화에 실패했습니다. Supabase 설정을 확인하세요.',
  );
  String get authInvalidEmailMessage => _resolve(
    zhCn: '请输入有效的邮箱地址。',
    zhTw: '請輸入有效的電子郵件地址。',
    en: 'Enter a valid email address.',
    ja: '有効なメールアドレスを入力してください。',
    ko: '유효한 이메일 주소를 입력하세요.',
  );
  String get authInvalidPhoneMessage => _resolve(
    zhCn: '请输入 E.164 格式的手机号，例如 +8613812345678。',
    zhTw: '請輸入 E.164 格式的手機號，例如 +8613812345678。',
    en: 'Enter a phone number in E.164 format, for example +8613812345678.',
  );
  String get authOtpSendFailedMessage => _resolve(
    zhCn: '验证码发送失败，请稍后重试。',
    zhTw: '驗證碼發送失敗，請稍後重試。',
    en: 'Failed to send the verification code. Please try again later.',
    ja: '認証コードの送信に失敗しました。後でもう一度お試しください。',
    ko: '인증 코드 전송에 실패했습니다. 나중에 다시 시도하세요.',
  );
  String get authSignUpSendFailedMessage => _resolve(
    zhCn: '创建账号失败，请稍后重试。',
    zhTw: '建立帳號失敗，請稍後重試。',
    en: 'Failed to create the account. Please try again later.',
    ja: 'アカウントの作成に失敗しました。後でもう一度お試しください。',
    ko: '계정 생성에 실패했습니다. 나중에 다시 시도하세요.',
  );
  String get authPhoneOtpSendFailedMessage => _resolve(
    zhCn: '手机号验证码发送失败，请稍后重试。',
    zhTw: '手機號驗證碼發送失敗，請稍後重試。',
    en: 'Failed to send the phone verification code. Please try again later.',
  );
  String get authPhoneSignUpSendFailedMessage => _resolve(
    zhCn: '手机号创建账号失败，请稍后重试。',
    zhTw: '手機號建立帳號失敗，請稍後重試。',
    en: 'Failed to create the phone account. Please try again later.',
  );
  String get authUserNotRegisteredMessage => _resolve(
    zhCn: '该邮箱尚未注册，请先创建账号。',
    zhTw: '該電子郵件尚未註冊，請先建立帳號。',
    en: 'This email is not registered yet. Please create an account first.',
    ja: 'このメールアドレスは登録されていません。先にアカウントを作成してください。',
    ko: '이 이메일은 아직 등록되지 않았습니다. 먼저 계정을 만드세요.',
  );
  String get authUserAlreadyRegisteredMessage => _resolve(
    zhCn: '该邮箱已经注册，请直接登录。',
    zhTw: '該電子郵件已經註冊，請直接登入。',
    en: 'This email is already registered. Please sign in instead.',
    ja: 'このメールアドレスは既に登録されています。ログインしてください。',
    ko: '이 이메일은 이미 등록되어 있습니다. 로그인하세요.',
  );
  String get authPhoneUserNotRegisteredMessage => _resolve(
    zhCn: '该手机号尚未注册，请先创建账号。',
    zhTw: '該手機號尚未註冊，請先建立帳號。',
    en:
        'This phone number is not registered yet. Please create an account first.',
  );
  String get authPhoneUserAlreadyRegisteredMessage => _resolve(
    zhCn: '该手机号已经注册，请直接登录。',
    zhTw: '該手機號已經註冊，請直接登入。',
    en: 'This phone number is already registered. Please sign in instead.',
  );
  String get authMissingPendingEmailMessage => _resolve(
    zhCn: '请先输入邮箱并发送验证码。',
    zhTw: '請先輸入電子郵件並發送驗證碼。',
    en: 'Enter your email and request a code first.',
    ja: 'メールアドレスを入力してコードをリクエストしてください。',
    ko: '이메일을 입력하고 코드를 요청하세요.',
  );
  String get authMissingPendingPhoneMessage => _resolve(
    zhCn: '请先输入手机号并发送验证码。',
    zhTw: '請先輸入手機號並發送驗證碼。',
    en: 'Enter your phone number and request a code first.',
  );
  String get authInvalidTokenLengthMessage => _resolve(
    zhCn: '请输入 6 位验证码。',
    zhTw: '請輸入 6 位驗證碼。',
    en: 'Enter the 6-digit verification code.',
    ja: '6桁の認証コードを入力してください。',
    ko: '6자리 인증 코드를 입력하세요.',
  );
  String get authOtpVerifyFailedMessage => _resolve(
    zhCn: '验证码校验失败，请确认后重试。',
    zhTw: '驗證碼校驗失敗，請確認後重試。',
    en: 'Verification failed. Check the code and try again.',
    ja: '認証に失敗しました。コードを確認してもう一度お試しください。',
    ko: '인증에 실패했습니다. 코드를 확인하고 다시 시도하세요.',
  );
  String get authUnknownErrorMessage => _resolve(
    zhCn: '认证过程中发生异常，请重试。',
    zhTw: '認證過程中發生異常，請重試。',
    en: 'Something went wrong during authentication. Please try again.',
    ja: '認証中に問題が発生しました。もう一度お試しください。',
    ko: '인증 중 문제가 발생했습니다. 다시 시도하세요.',
  );

  String get profileEditLabel => _resolve(
    zhCn: '编辑',
    zhTw: '編輯',
    en: 'Edit',
    ja: '編集',
    ko: '편집',
  );
  String get profileCancelLabel => _resolve(
    zhCn: '取消',
    zhTw: '取消',
    en: 'Cancel',
    ja: 'キャンセル',
    ko: '취소',
  );
  String get profileSaveLabel => _resolve(
    zhCn: '保存',
    zhTw: '儲存',
    en: 'Save',
    ja: '保存',
    ko: '저장',
  );
  String get profileDisplayNameLabel => _resolve(
    zhCn: '昵称',
    zhTw: '暱稱',
    en: 'Display name',
    ja: '表示名',
    ko: '표시 이름',
  );
  String get profileDisplayNameHint => _resolve(
    zhCn: '输入你的昵称',
    zhTw: '輸入你的暱稱',
    en: 'Enter your display name',
    ja: '表示名を入力してください',
    ko: '표시 이름을 입력하세요',
  );
  String get profileDisplayNameEmptyError => _resolve(
    zhCn: '昵称不能为空',
    zhTw: '暱稱不能為空',
    en: 'Display name cannot be empty',
    ja: '表示名は空にできません',
    ko: '표시 이름은 비워둘 수 없습니다',
  );
  String get profileDisplayNameTooLongError => _resolve(
    zhCn: '昵称不能超过 40 个字符',
    zhTw: '暱稱不能超過 40 個字元',
    en: 'Display name cannot exceed 40 characters',
    ja: '表示名は40文字以内にしてください',
    ko: '표시 이름은 40자를 초과할 수 없습니다',
  );
  String get profileGenderLabel => _resolve(
    zhCn: '性别',
    zhTw: '性別',
    en: 'Gender',
    ja: '性別',
    ko: '성별',
  );
  String get profileGenderMaleLabel => _resolve(
    zhCn: '男生',
    zhTw: '男生',
    en: 'Male',
    ja: '男性',
    ko: '남성',
  );
  String get profileGenderFemaleLabel => _resolve(
    zhCn: '女生',
    zhTw: '女生',
    en: 'Female',
    ja: '女性',
    ko: '여성',
  );
  String get profileGenderRequiredError => _resolve(
    zhCn: '请选择性别',
    zhTw: '請選擇性別',
    en: 'Please select a gender',
    ja: '性別を選択してください',
    ko: '성별을 선택하세요',
  );
  String get profileBirthdayLabel => _resolve(
    zhCn: '生日',
    zhTw: '生日',
    en: 'Birthday',
    ja: '誕生日',
    ko: '생일',
  );
  String get profileBirthdayHint => _resolve(
    zhCn: '点击选择日期',
    zhTw: '點擊選擇日期',
    en: 'Tap to select date',
    ja: 'タップして日付を選択',
    ko: '날짜를 선택하려면 탭하세요',
  );
  String get profileBirthdayClearLabel => _resolve(
    zhCn: '清空',
    zhTw: '清空',
    en: 'Clear',
    ja: 'クリア',
    ko: '지우기',
  );
  String get profileEmailLabel => _resolve(
    zhCn: '邮箱',
    zhTw: '電子郵件',
    en: 'Email',
    ja: 'メールアドレス',
    ko: '이메일',
  );
  String get profileSaveFailedMessage => _resolve(
    zhCn: '保存失败，请稍后重试',
    zhTw: '儲存失敗，請稍後重試',
    en: 'Failed to save. Please try again later.',
    ja: '保存に失敗しました。後でもう一度お試しください。',
    ko: '저장에 실패했습니다. 나중에 다시 시도하세요.',
  );
  String get profileSessionExpiredMessage => _resolve(
    zhCn: '登录已过期，请重新登录',
    zhTw: '登入已過期，請重新登入',
    en: 'Session expired. Please sign in again.',
    ja: 'セッションが期限切れです。再度ログインしてください。',
    ko: '세션이 만료되었습니다. 다시 로그인하세요.',
  );

  // ── Profile setup screen ──────────────────────────────────────────────

  String get profileSetupTitle => _resolve(
    zhCn: '完善你的资料',
    zhTw: '完善你的資料',
    en: 'Complete your profile',
    ja: 'プロフィールを完成させてください',
    ko: '프로필을 완성하세요',
  );
  String get profileSetupSubtitle => _resolve(
    zhCn: '登录已经完成。请先填写昵称和性别，生日可以稍后补充为空。保存后即可进入 Between Us。',
    zhTw: '登入已經完成。請先填寫暱稱和性別，生日可以稍後補充為空。儲存後即可進入 Between Us。',
    en: 'Sign-in is complete. Finish your name and gender first. Birthday is optional, and you can continue after saving.',
    ja: 'ログインが完了しました。まず名前と性別を入力してください。誕生日は任意です。保存後 Between Us を使用できます。',
    ko: '로그인이 완료되었습니다. 이름과 성별을 먼저 입력하세요. 생일은 선택 사항이며, 저장 후 Between Us를 사용할 수 있습니다.',
  );
  String get profileDisplayNameSetupHint => _resolve(
    zhCn: '输入你想展示的昵称',
    zhTw: '輸入你想展示的暱稱',
    en: 'Enter the name you want to show',
    ja: '表示したい名前を入力してください',
    ko: '표시할 이름을 입력하세요',
  );
  String get profileBirthdayOptionalLabel => _resolve(
    zhCn: '生日（可选）',
    zhTw: '生日（可選）',
    en: 'Birthday (optional)',
    ja: '誕生日（任意）',
    ko: '생일 (선택)',
  );
  String get profileClearBirthdayLabel => _resolve(
    zhCn: '清空生日',
    zhTw: '清空生日',
    en: 'Clear birthday',
    ja: '誕生日をクリア',
    ko: '생일 지우기',
  );
  String get profileSaveAndContinueLabel => _resolve(
    zhCn: '保存并进入',
    zhTw: '儲存並進入',
    en: 'Save and continue',
    ja: '保存して続ける',
    ko: '저장 후 계속',
  );
  String get profileChooseBirthdayLabel => _resolve(
    zhCn: '选择生日',
    zhTw: '選擇生日',
    en: 'Choose your birthday',
    ja: '誕生日を選択',
    ko: '생일 선택',
  );
  String get profilePreparingLabel => _resolve(
    zhCn: '正在准备你的资料...',
    zhTw: '正在準備你的資料...',
    en: 'Preparing your profile...',
    ja: 'プロフィールを準備中...',
    ko: '프로필 준비 중...',
  );

  // ── Profile setup error messages ──────────────────────────────────────

  String get profileSetupInitFailedError => _resolve(
    zhCn: '资料服务初始化失败，请稍后重试。',
    zhTw: '資料服務初始化失敗，請稍後重試。',
    en: 'Profile service failed to initialize. Please try again.',
    ja: 'プロフィールサービスの初期化に失敗しました。もう一度お試しください。',
    ko: '프로필 서비스 초기화에 실패했습니다. 다시 시도하세요.',
  );
  String get profileSetupMissingUserError => _resolve(
    zhCn: '当前登录状态无效，请重新登录。',
    zhTw: '當前登入狀態無效，請重新登入。',
    en: 'Your session is invalid. Please sign in again.',
    ja: 'セッションが無効です。再度ログインしてください。',
    ko: '세션이 유효하지 않습니다. 다시 로그인하세요.',
  );
  String get profileSetupInvalidNameError => _resolve(
    zhCn: '昵称不能为空、不能使用默认占位名，且不能超过 40 个字符。',
    zhTw: '暱稱不能為空、不能使用預設佔位名，且不能超過 40 個字元。',
    en: 'Display name must be 1 to 40 characters, and cannot be the default placeholder.',
    ja: '表示名は1〜40文字で、デフォルトのプレースホルダーは使用できません。',
    ko: '표시 이름은 1~40자여야 하며, 기본 플레이스홀더를 사용할 수 없습니다.',
  );
  String get profileSetupSaveFailedError => _resolve(
    zhCn: '资料保存失败，请稍后重试。',
    zhTw: '資料儲存失敗，請稍後重試。',
    en: 'Failed to save your profile. Please try again.',
    ja: 'プロフィールの保存に失敗しました。もう一度お試しください。',
    ko: '프로필 저장에 실패했습니다. 다시 시도하세요.',
  );
  String get profileSetupSessionExpiredError => _resolve(
    zhCn: '登录状态已过期，请重新登录。',
    zhTw: '登入狀態已過期，請重新登入。',
    en: 'Your session has expired. Please sign in again.',
    ja: 'セッションが期限切れです。再度ログインしてください。',
    ko: '세션이 만료되었습니다. 다시 로그인하세요.',
  );
  String get profileSetupUnknownError => _resolve(
    zhCn: '资料保存时发生异常，请重试。',
    zhTw: '資料儲存時發生異常，請重試。',
    en: 'Something went wrong while saving your profile. Please try again.',
    ja: 'プロフィールの保存中に問題が発生しました。もう一度お試しください。',
    ko: '프로필 저장 중 문제가 발생했습니다. 다시 시도하세요.',
  );

  // ── Invite page ───────────────────────────────────────────────────────

  String get invitePartnerTitle => _resolve(
    zhCn: 'TA 的资料',
    zhTw: 'TA 的資料',
    en: 'Partner profile',
    ja: 'パートナーのプロフィール',
    ko: '파트너 프로필',
  );
  String get inviteAboutPartnerTitle => _resolve(
    zhCn: '关于 TA',
    zhTw: '關於 TA',
    en: 'About partner',
    ja: 'パートナーについて',
    ko: '파트너 소개',
  );
  String get invitePartnerJoinedLabel => _resolve(
    zhCn: '已加入空间',
    zhTw: '已加入空間',
    en: 'Has joined the space',
    ja: 'スペースに参加済み',
    ko: '공간에 참여함',
  );
  String get invitePartnerMoreInfoLabel => _resolve(
    zhCn: '关于 TA 的更多资料，会出现在这里。',
    zhTw: '關於 TA 的更多資料，會出現在這裡。',
    en: 'More about your partner will appear here.',
    ja: 'パートナーの詳細情報がここに表示されます。',
    ko: '파트너의 추가 정보가 여기에 표시됩니다.',
  );
  String get inviteInvitePartnerTitle => _resolve(
    zhCn: '邀请 TA',
    zhTw: '邀請 TA',
    en: 'Invite your partner',
    ja: 'パートナーを招待',
    ko: '파트너 초대',
  );
  String get inviteLeaveSpotSubtitle => _resolve(
    zhCn: '先给 TA 留一个位置',
    zhTw: '先給 TA 留一個位置',
    en: 'Leave a spot for your partner',
    ja: 'パートナーの席を確保しましょう',
    ko: '파트너를 위한 자리를 마련하세요',
  );
  String get inviteSpotDescription => _resolve(
    zhCn: '等 TA 加入后，这里会慢慢变成只属于你们两个人的空间。',
    zhTw: '等 TA 加入後，這裡會慢慢變成只屬於你們兩個人的空間。',
    en: 'Once your partner joins, this space will start to feel like it belongs to the two of you.',
    ja: 'パートナーが参加すると、このスペースはふたりだけのものになります。',
    ko: '파트너가 참여하면 이 공간은 두 사람만의 공간이 됩니다.',
  );
  String get inviteActionsTitle => _resolve(
    zhCn: '邀请操作',
    zhTw: '邀請操作',
    en: 'Invite actions',
    ja: '招待アクション',
    ko: '초대 작업',
  );
  String get inviteActionsSubtitle => _resolve(
    zhCn: '生成或输入邀请码',
    zhTw: '生成或輸入邀請碼',
    en: 'Generate or enter an invite code',
    ja: '招待コードを生成または入力',
    ko: '초대 코드 생성 또는 입력',
  );
  String get inviteGenerateCodeButton => _resolve(
    zhCn: '生成邀请码',
    zhTw: '生成邀請碼',
    en: 'Generate invite code',
    ja: '招待コードを生成',
    ko: '초대 코드 생성',
  );
  String get inviteEnterCodeJoinButton => _resolve(
    zhCn: '输入邀请码加入',
    zhTw: '輸入邀請碼加入',
    en: 'Enter invite code to join',
    ja: '招待コードを入力して参加',
    ko: '초대 코드를 입력하여 참여',
  );
  String get inviteCurrentCodeLabel => _resolve(
    zhCn: '当前邀请码',
    zhTw: '當前邀請碼',
    en: 'Current invite code',
    ja: '現在の招待コード',
    ko: '현재 초대 코드',
  );
  String get inviteCopyCodeTooltip => _resolve(
    zhCn: '复制邀请码',
    zhTw: '複製邀請碼',
    en: 'Copy invite code',
    ja: '招待コードをコピー',
    ko: '초대 코드 복사',
  );
  String get inviteGenerateFailedMessage => _resolve(
    zhCn: '邀请码生成失败，请稍后重试',
    zhTw: '邀請碼生成失敗，請稍後重試',
    en: 'Failed to generate invite code. Please try again later.',
    ja: '招待コードの生成に失敗しました。後でもう一度お試しください。',
    ko: '초대 코드 생성에 실패했습니다. 나중에 다시 시도하세요.',
  );
  String get inviteEnterCodeDialogTitle => _resolve(
    zhCn: '输入邀请码',
    zhTw: '輸入邀請碼',
    en: 'Enter invite code',
    ja: '招待コードを入力',
    ko: '초대 코드 입력',
  );
  String get inviteEnterCodeDialogHint => _resolve(
    zhCn: '请输入对方分享的邀请码',
    zhTw: '請輸入對方分享的邀請碼',
    en: 'Enter the invite code shared by your partner',
    ja: 'パートナーが共有した招待コードを入力してください',
    ko: '파트너가 공유한 초대 코드를 입력하세요',
  );
  String get inviteJoinButton => _resolve(
    zhCn: '加入',
    zhTw: '加入',
    en: 'Join',
    ja: '参加',
    ko: '참여',
  );
  String get inviteJoinSuccessMessage => _resolve(
    zhCn: '已成功加入空间',
    zhTw: '已成功加入空間',
    en: 'Successfully joined the space',
    ja: 'スペースへの参加が完了しました',
    ko: '공간에 성공적으로 참여했습니다',
  );
  String get inviteCodeInvalidError => _resolve(
    zhCn: '邀请码无效或已过期',
    zhTw: '邀請碼無效或已過期',
    en: 'Invalid or expired invite code',
    ja: '招待コードが無効または期限切れです',
    ko: '초대 코드가 유효하지 않거나 만료되었습니다',
  );
  String get invitePartnerToStartUsing => _resolve(
    zhCn: '邀请对方加入后，即可开始使用',
    zhTw: '邀請對方加入後，即可開始使用',
    en: 'Invite your partner to start using',
    ja: 'パートナーを招待して使い始めましょう',
    ko: '파트너를 초대하여 사용을 시작하세요',
  );
  String inviteExpiryText(int month, int day, int hour, int minute) => _resolve(
    zhCn: '有效期至 $month 月 $day 日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    zhTw: '有效期至 $month 月 $day 日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    en: 'Expires $month/$day ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    ja: '有効期限: $month月$day日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    ko: '만료: $month월 $day일 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
  );

  // ── Partner / self display names ──────────────────────────────────────

  String get partnerFallbackName => _resolve(
    zhCn: 'TA',
    zhTw: 'TA',
    en: 'Partner',
    ja: 'パートナー',
    ko: '파트너',
  );
  String get selfFallbackName => _resolve(
    zhCn: '我',
    zhTw: '我',
    en: 'Me',
    ja: '自分',
    ko: '나',
  );

  // ── Home hero card ────────────────────────────────────────────────────

  /// 预设情绪文案列表，每次打开 APP 随机选择一条。
  List<String> get homeHeroQuotes => [
    _resolve(
      zhCn: '💕 我们的故事',
      zhTw: '💕 我們的故事',
      en: '💕 Our Story',
      ja: '💕 私たちの物語',
      ko: '💕 우리의 이야기',
    ),
    _resolve(
      zhCn: '🌤 今天也是想你的一天',
      zhTw: '🌤 今天也是想你的一天',
      en: '🌤 Missing you today too',
      ja: '🌤 今日もあなたが恋しい',
      ko: '🌤 오늘도 보고픈 하루',
    ),
    _resolve(
      zhCn: '🌙 今晚月色很温柔',
      zhTw: '🌙 今晚月色很溫柔',
      en: '🌙 The moon is gentle tonight',
      ja: '🌙 今夜の月は優しい',
      ko: '🌙 오늘 밤 달이 부드러워',
    ),
    _resolve(
      zhCn: '💝 每一天都值得纪念',
      zhTw: '💝 每一天都值得紀念',
      en: '💝 Every day is worth celebrating',
      ja: '💝 每日が記念日',
      ko: '💝 매일매일이 기념일',
    ),
    _resolve(
      zhCn: '🌸 有你真好',
      zhTw: '🌸 有你真好',
      en: '🌸 So glad to have you',
      ja: '🌸 いてくれてよかった',
      ko: '🌸 있어줘서 고마워',
    ),
  ];

  String get homeHeroDaysTogetherLabel => _resolve(
    zhCn: '我们已经一起走过',
    zhTw: '我們已經一起走過',
    en: 'We have been together for',
    ja: '一緒に過ごした日数',
    ko: '함께한 날',
  );

  String get homeHeroDaysUnit => _resolve(
    zhCn: '天',
    zhTw: '天',
    en: 'days',
    ja: '日',
    ko: '일',
  );

  String get homeHeroWaitingForPartner => _resolve(
    zhCn: '等待另一半加入',
    zhTw: '等待另一半加入',
    en: 'Waiting for your partner to join',
    ja: 'パートナーの参加を待っています',
    ko: '파트너의 참여를 기다리고 있어요',
  );

  String homeHeroAnniversaryCountdown(String title, int days) => _resolve(
    zhCn: '距离$title还有 $days 天',
    zhTw: '距離$title還有 $days 天',
    en: '$title in $days days',
    ja: '$titleまで $days 日',
    ko: '$title까지 $days 일',
  );

  // ── Network error ─────────────────────────────────────────────────────

  String get networkCheckConnectionError => _resolve(
    zhCn: '请检查网络连接',
    zhTw: '請檢查網路連線',
    en: 'Please check your network connection',
    ja: 'ネットワーク接続を確認してください',
    ko: '네트워크 연결을 확인하세요',
  );

  String get homeTab => _resolve(
    zhCn: '首页',
    zhTw: '首頁',
    en: 'Home',
    ja: 'ホーム',
    ko: '홈',
  );
  String get calendarTab => _resolve(
    zhCn: '日历',
    zhTw: '日曆',
    en: 'Calendar',
    ja: 'カレンダー',
    ko: '캘린더',
  );
  String get plansNotesTab => _resolve(
    zhCn: '计划笔记',
    zhTw: '計畫筆記',
    en: 'Plans & Notes',
    ja: 'プラン・メモ',
    ko: '계획・메모',
  );
  String get usTab => _resolve(
    zhCn: '我们',
    zhTw: '我們',
    en: 'Us',
    ja: 'ふたり',
    ko: '우리',
  );

  String get overviewSection => _resolve(
    zhCn: '我们概览',
    zhTw: '我們概覽',
    en: 'Our overview',
    ja: 'ふたりの概要',
    ko: '우리의 개요',
  );
  String get nextDateSection => _resolve(
    zhCn: '下一个重要日期',
    zhTw: '下一個重要日期',
    en: 'Next important date',
    ja: '次の記念日',
    ko: '다음 중요한 날',
  );
  String get recentUpdateSection => _resolve(
    zhCn: '最近随记',
    zhTw: '最近隨記',
    en: 'Recent note',
    ja: '最近のメモ',
    ko: '최근 메모',
  );
  String get recentPlanSection => _resolve(
    zhCn: '最近计划',
    zhTw: '最近計畫',
    en: 'Recent plan',
    ja: '最近のプラン',
    ko: '최근 계획',
  );
  String get quickLinksSection => _resolve(
    zhCn: '快速操作',
    zhTw: '快速操作',
    en: 'Quick actions',
    ja: 'クイックアクション',
    ko: '빠른 실행',
  );

  String get writeNoteLabel => _resolve(
    zhCn: '写随记',
    zhTw: '寫隨記',
    en: 'Write a note',
    ja: 'メモを書く',
    ko: '메모 작성',
  );
  String get createPlanLabel => _resolve(
    zhCn: '新建计划',
    zhTw: '新建計畫',
    en: 'New plan',
    ja: '新しいプラン',
    ko: '새 계획',
  );
  String get goCalendarLabel => _resolve(
    zhCn: '去日历',
    zhTw: '去日曆',
    en: 'Open calendar',
    ja: 'カレンダーを開く',
    ko: '캘린더 열기',
  );
  String get goUsLabel => _resolve(
    zhCn: '去我们',
    zhTw: '去我們',
    en: 'Open Us',
    ja: 'ふたりを開く',
    ko: '우리 열기',
  );

  String get avatarLabelOne => isChinese ? '满' : 'X';
  String get avatarLabelTwo => isChinese ? '澈' : 'A';
  String get coupleNames => isChinese ? '小满 和 阿澈' : 'Xiaoman & Ache';
  String get relationshipStatus => isChinese ? '一起第 214 天' : 'Day 214 together';
  String get relationshipMood => isChinese
      ? '这周都不算太忙，周五晚上留给一起出门。'
      : 'This week feels calm enough. Friday night is still saved for the two of you.';
  String get spaceStatusLabel => _resolve(
    zhCn: '空间状态',
    zhTw: '空間狀態',
    en: 'Space status',
    ja: 'スペースの状態',
    ko: '공간 상태',
  );
  String get spaceStatusValue => isChinese ? '稳定同步中' : 'Steady and shared';
  String get overviewChipOne => isChinese ? '今晚都在线' : 'Both around tonight';
  String get overviewChipTwo => isChinese ? '周五留给约会' : 'Friday kept for a date';

  String get noteComposerTitle => _resolve(
    zhCn: '想留一句话时，就写在这里',
    en: 'Leave a note whenever it feels right',
  );
  String get noteComposerHint => _resolve(
    zhCn: '不用写很多，想到什么就留一点。',
    en: 'Keep it light. A few words are enough.',
  );
  String get noteComposerExample => _resolve(
    zhCn: '比如：回来的路上别忘了买点水果，我想留一半给明天早上。',
    en: 'For example: grab some fruit on the way back. I want to save half for tomorrow morning.',
  );

  List<String> get weekLabels => switch (language) {
    AppLanguage.zhCn || AppLanguage.zhTw =>
      const ['一', '二', '三', '四', '五', '六', '日'],
    AppLanguage.en => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    AppLanguage.ja => const ['月', '火', '水', '木', '金', '土', '日'],
    AppLanguage.ko => const ['월', '화', '수', '목', '금', '토', '일'],
  };
  String get monthYearLabel => _resolve(
    zhCn: '2026 年 6 月',
    zhTw: '2026 年 6 月',
    en: 'June 2026',
    ja: '2026年6月',
    ko: '2026년 6월',
  );

  String get calendarTitle => calendarTab;
  String get calendarLeadTitle => _resolve(
    zhCn: '本月安排',
    en: 'This month at a glance',
  );
  String get calendarLeadSubtitle => _resolve(
    zhCn: '纪念日、约会和提醒，都放在这里。',
    en: 'Anniversaries, scheduled plans, and reminders stay here.',
  );
  String get selectedDateSection => _resolve(
    zhCn: '选中日期详情',
    en: 'Selected date details',
  );
  String get upcomingEventsSection => _resolve(
    zhCn: '近期事项',
    zhTw: '近期事項',
    en: 'Coming up soon',
    ja: '近日の予定',
    ko: '다가오는 일정',
  );
  String get createCalendarEntrySection => _resolve(
    zhCn: '添加事件',
    zhTw: '新增事件',
    en: 'Add event',
    ja: 'イベント追加',
    ko: '이벤트 추가',
  );
  String get selectedDateLabel => isChinese ? '6 月 6 日 · 周六' : 'June 6 · Saturday';
  String get createAnniversaryLabel => _resolve(
    zhCn: '纪念日',
    zhTw: '紀念日',
    en: 'Anniversary',
    ja: '記念日',
    ko: '기념일',
  );
  String get createDatePlanLabel => _resolve(
    zhCn: '约会',
    zhTw: '約會',
    en: 'Date plan',
    ja: 'デート',
    ko: '데이트',
  );
  String get createReminderLabel => _resolve(
    zhCn: '提醒',
    zhTw: '提醒',
    en: 'Reminder',
    ja: 'リマインダー',
    ko: '알림',
  );
  String get plansNotesTitle => plansNotesTab;
  String get plansNotesLeadTitle => _resolve(
    zhCn: '没定日期的，先放这里',
    en: 'Keep undecided things here first',
  );
  String get plansNotesLeadSubtitle => _resolve(
    zhCn: '有日期的去日历，没日期的计划和随记留在这里。',
    en: 'Dated items belong in calendar. Undated plans and notes stay here.',
  );
  String get plansSectionTitle => _resolve(
    zhCn: '计划',
    zhTw: '計畫',
    en: 'Plans',
    ja: 'プラン',
    ko: '계획',
  );
  String get plansSectionSubtitle => _resolve(
    zhCn: '还没定日期的想法、待讨论事项和约会意向。',
    en: 'Undated ideas, date intentions, and things to discuss.',
  );
  String get notesSectionTitle => _resolve(
    zhCn: '随记',
    zhTw: '隨記',
    en: 'Notes',
    ja: 'メモ',
    ko: '메모',
  );
  String get notesSectionSubtitle => _resolve(
    zhCn: '随手记下的小事、心情和共享日常。',
    en: 'Light shared notes, little thoughts, and daily moments.',
  );
  String get moveToCalendarLabel => _resolve(
    zhCn: '以后放进日历',
    en: 'Later move to calendar',
  );
  String get addPlanLabel => _resolve(
    zhCn: '加一个计划',
    zhTw: '加一個計畫',
    en: 'Add a plan',
    ja: 'プランを追加',
    ko: '계획 추가',
  );
  String get addNoteLabel => _resolve(
    zhCn: '写一条随记',
    zhTw: '寫一條隨記',
    en: 'Write a note',
    ja: 'メモを書く',
    ko: '메모 작성',
  );

  String get switchToNotesHint => _resolve(
    zhCn: '看看随记',
    zhTw: '看看隨記',
    en: 'Switch to notes',
    ja: 'メモを見る',
    ko: '메모 보기',
  );
  String get switchToPlansHint => _resolve(
    zhCn: '看看计划',
    zhTw: '看看計畫',
    en: 'Switch to plans',
    ja: 'プランを見る',
    ko: '계획 보기',
  );

  String get usTitle => usTab;
  String get usLeadTitle => _resolve(
    zhCn: '我们的空间',
    zhTw: '我們的空間',
    en: 'Our shared space',
    ja: 'ふたりのスペース',
    ko: '우리의 공간',
  );
  String get usLeadSubtitle => _resolve(
    zhCn: '把自己的偏好和两个人一起用的规则，都放在同一个地方。',
    zhTw: '把自己的偏好和兩個人一起用的規則，都放在同一個地方。',
    en: 'Keep your personal preferences and shared space rules together.',
    ja: '個人の設定とふたりのルールを一か所にまとめましょう。',
    ko: '개인 설정과 두 사람의 규칙을 한 곳에 모아보세요.',
  );
  String get settingsMoreTitle => _resolve(
    zhCn: '设置与更多',
    zhTw: '設定與更多',
    en: 'Settings & more',
    ja: '設定とその他',
    ko: '설정 및 기타',
  );
  String get settingsMoreSubtitle => _resolve(
    zhCn: '语言、主题、通知和账号相关设置都在这里。',
    zhTw: '語言、主題、通知和帳號相關設定都在這裡。',
    en: 'Language, theme, notifications, and account settings are all here.',
    ja: '言語、テーマ、通知、アカウント設定がすべてここにあります。',
    ko: '언어, 테마, 알림, 계정 설정이 모두 여기에 있습니다.',
  );
  String get preferencesSection => _resolve(
    zhCn: '我的偏好',
    zhTw: '我的偏好',
    en: 'My preferences',
    ja: '個人設定',
    ko: '내 설정',
  );
  String get spaceSection => _resolve(
    zhCn: '我们的空间',
    zhTw: '我們的空間',
    en: 'Our space',
    ja: 'ふたりのスペース',
    ko: '우리의 공간',
  );

  // ── Anniversary ──────────────────────────────────────────────────────

  String get anniversarySectionTitle => _resolve(
    zhCn: '纪念日',
    zhTw: '紀念日',
    en: 'Anniversaries',
    ja: '記念日',
    ko: '기념일',
  );
  String get firstMetAnniversary => _resolve(
    zhCn: '相识纪念日',
    zhTw: '相識紀念日',
    en: 'First Met',
    ja: '出会った記念日',
    ko: '처음 만난 날',
  );
  String get relationshipStartAnniversary => _resolve(
    zhCn: '恋爱纪念日',
    zhTw: '戀愛紀念日',
    en: 'Together Since',
    ja: '付き合い始めた記念日',
    ko: '사귀기 시작한 날',
  );
  String get addCustomAnniversary => _resolve(
    zhCn: '添加自定义纪念日',
    zhTw: '添加自定義紀念日',
    en: 'Add custom anniversary',
    ja: 'カスタム記念日を追加',
    ko: '커스텀 기념일 추가',
  );
  String get customAnniversaryTitleHint => _resolve(
    zhCn: '纪念日名称',
    zhTw: '紀念日名稱',
    en: 'Anniversary title',
    ja: '記念日の名前',
    ko: '기념일 이름',
  );
  String get deleteAnniversary => _resolve(
    zhCn: '删除纪念日',
    zhTw: '刪除紀念日',
    en: 'Delete anniversary',
    ja: '記念日を削除',
    ko: '기념일 삭제',
  );
  String get deleteAnniversaryConfirm => _resolve(
    zhCn: '确定要删除这个纪念日吗？',
    zhTw: '確定要刪除這個紀念日嗎？',
    en: 'Are you sure you want to delete this anniversary?',
    ja: 'この記念日を削除しますか？',
    ko: '이 기념일을 삭제하시겠습니까?',
  );
  String get maxCustomAnniversariesReached => _resolve(
    zhCn: '最多只能添加两个自定义纪念日',
    zhTw: '最多只能添加兩個自定義紀念日',
    en: 'You can add up to 2 custom anniversaries',
    ja: 'カスタム記念日は最大2つまで',
    ko: '커스텀 기념일은 최대 2개까지',
  );
  String get anniversaryDateLabel => _resolve(
    zhCn: '日期',
    zhTw: '日期',
    en: 'Date',
    ja: '日付',
    ko: '날짜',
  );

  String get nextEventLabel => _resolve(
    zhCn: '下一个安排',
    zhTw: '下一個安排',
    en: 'Next event',
    ja: '次の予定',
    ko: '다음 일정',
  );
  String get noUpcomingEvent => _resolve(
    zhCn: '暂无安排',
    zhTw: '暫無安排',
    en: 'No upcoming events',
    ja: '予定なし',
    ko: '예정 없음',
  );
  String get privacySection => _resolve(
    zhCn: '隐私与共享',
    zhTw: '隱私與共享',
    en: 'Privacy & sharing',
    ja: 'プライバシーと共有',
    ko: '개인정보 및 공유',
  );
  String get languageTitle => _resolve(
    zhCn: '语言',
    zhTw: '語言',
    en: 'Language',
    ja: '言語',
    ko: '언어',
  );
  String get themeTitle => _resolve(
    zhCn: '主题模式',
    zhTw: '主題模式',
    en: 'Theme mode',
    ja: 'テーマ',
    ko: '테마',
  );
  String get timeZoneTitle => _resolve(
    zhCn: '时区',
    zhTw: '時區',
    en: 'Time zone',
    ja: 'タイムゾーン',
    ko: '시간대',
  );
  String get timeZoneHint => _resolve(
    zhCn: '首页、日历和随记时间都会按这里展示。',
    zhTw: '首頁、日曆和隨記時間都會按這裡展示。',
    en: 'Home, calendar, and note times follow this device time zone.',
    ja: 'ホーム、カレンダー、メモの時間はこのデバイスのタイムゾーンに従います。',
    ko: '홈, 캘린더, 메모 시간은 이 기기의 시간대를 따릅니다.',
  );
  String get notificationPreviewTitle => _resolve(
    zhCn: '通知预览',
    zhTw: '通知預覽',
    en: 'Notification previews',
    ja: '通知プレビュー',
    ko: '알림 미리보기',
  );
  String get notificationPreviewSubtitle => _resolve(
    zhCn: '在通知里直接显示随记和提醒内容。',
    zhTw: '在通知裡直接顯示隨記和提醒內容。',
    en: 'Show note and reminder text directly inside notifications.',
    ja: '通知内にメモとリマインダーの内容を直接表示します。',
    ko: '알림에 메모와 알림 내용을 직접 표시합니다.',
  );
  String get appearanceSettingsTitle => _resolve(
    zhCn: '外观与语言',
    zhTw: '外觀與語言',
    en: 'Appearance',
    ja: '外観と言語',
    ko: '외관 및 언어',
  );
  String get notificationSettingsTitle => _resolve(
    zhCn: '通知设置',
    zhTw: '通知設定',
    en: 'Notifications',
    ja: '通知設定',
    ko: '알림 설정',
  );
  String get privacySettingsTitle => _resolve(
    zhCn: '隐私与共享',
    zhTw: '隱私與共享',
    en: 'Privacy & sharing',
    ja: 'プライバシーと共有',
    ko: '개인정보 및 공유',
  );
  String get accountSecurityTitle => _resolve(
    zhCn: '账号与安全',
    zhTw: '帳號與安全',
    en: 'Account & security',
  );
  String get accountSecuritySettingsSubtitle => _resolve(
    zhCn: '登录邮箱、手机号和账号凭证',
    zhTw: '登入電子郵件、手機號和帳號憑證',
    en: 'Login email, phone, and account credentials',
  );
  String get accountSecuritySubtitle => _resolve(
    zhCn: '管理可以登录这个账号的邮箱和手机号。',
    zhTw: '管理可以登入這個帳號的電子郵件和手機號。',
    en: 'Manage the email and phone number that can sign in to this account.',
  );
  String get accountSecurityEmailTitle => _resolve(
    zhCn: '登录邮箱',
    zhTw: '登入電子郵件',
    en: 'Login email',
  );
  String get accountSecurityPhoneTitle => _resolve(
    zhCn: '登录手机号',
    zhTw: '登入手機號',
    en: 'Login phone',
  );
  String get accountSecurityEmailUnbound => _resolve(
    zhCn: '未绑定邮箱',
    zhTw: '未綁定電子郵件',
    en: 'No email bound',
  );
  String get accountSecurityPhoneUnbound => _resolve(
    zhCn: '未绑定手机号',
    zhTw: '未綁定手機號',
    en: 'No phone bound',
  );
  String get accountSecurityBindEmailLabel => _resolve(
    zhCn: '绑定邮箱',
    zhTw: '綁定電子郵件',
    en: 'Bind email',
  );
  String get accountSecurityBindPhoneLabel => _resolve(
    zhCn: '绑定手机号',
    zhTw: '綁定手機號',
    en: 'Bind phone',
  );
  String get accountSecurityPrivacyHint => _resolve(
    zhCn: '手机号用于登录和账号安全，不会默认展示给 TA。',
    zhTw: '手機號用於登入和帳號安全，不會預設展示給 TA。',
    en: 'Your phone number is for sign-in and account security. It is not shown to your partner by default.',
  );
  String get accountSecurityBindPhoneTitle => _resolve(
    zhCn: '绑定手机号',
    zhTw: '綁定手機號',
    en: 'Bind phone number',
  );
  String get accountSecurityBindEmailTitle => _resolve(
    zhCn: '绑定邮箱',
    zhTw: '綁定電子郵件',
    en: 'Bind email',
  );
  String get accountSecurityBindPhoneHint => _resolve(
    zhCn: '请输入 E.164 格式手机号。绑定后，它会成为当前账号的登录方式。',
    zhTw: '請輸入 E.164 格式手機號。綁定後，它會成為目前帳號的登入方式。',
    en: 'Enter a phone number in E.164 format. After binding, it can sign in to this account.',
  );
  String get accountSecurityBindEmailHint => _resolve(
    zhCn: '绑定后，这个邮箱会成为当前账号的登录方式。',
    zhTw: '綁定後，這個電子郵件會成為目前帳號的登入方式。',
    en: 'After binding, this email can sign in to this account.',
  );
  String get accountSecuritySendBindingCodeLabel => _resolve(
    zhCn: '发送绑定验证码',
    zhTw: '發送綁定驗證碼',
    en: 'Send binding code',
  );
  String get accountSecurityVerifyBindingLabel => _resolve(
    zhCn: '验证并绑定',
    zhTw: '驗證並綁定',
    en: 'Verify and bind',
  );
  String accountSecurityBindingCodeSentTo(String target) => _resolve(
    zhCn: '验证码已发送至 $target',
    zhTw: '驗證碼已發送至 $target',
    en: 'A code has been sent to $target',
  );
  String get accountSecurityNotAuthenticatedMessage => _resolve(
    zhCn: '请先登录后再管理账号安全。',
    zhTw: '請先登入後再管理帳號安全。',
    en: 'Sign in before managing account security.',
  );
  String get accountSecurityBindingConflictMessage => _resolve(
    zhCn: '这个邮箱或手机号已经属于另一个账号，不能直接绑定。',
    zhTw: '這個電子郵件或手機號已經屬於另一個帳號，不能直接綁定。',
    en: 'This email or phone number already belongs to another account.',
  );
  String get accountSecurityPhoneBindingSendFailedMessage => _resolve(
    zhCn: '手机号绑定验证码发送失败，请稍后重试。',
    zhTw: '手機號綁定驗證碼發送失敗，請稍後重試。',
    en: 'Failed to send the phone binding code. Please try again later.',
  );
  String get accountSecurityEmailBindingSendFailedMessage => _resolve(
    zhCn: '邮箱绑定验证码发送失败，请稍后重试。',
    zhTw: '電子郵件綁定驗證碼發送失敗，請稍後重試。',
    en: 'Failed to send the email binding code. Please try again later.',
  );
  String get accountSecurityBindingVerifyFailedMessage => _resolve(
    zhCn: '绑定验证码校验失败，请确认后重试。',
    zhTw: '綁定驗證碼校驗失敗，請確認後重試。',
    en: 'Binding verification failed. Check the code and try again.',
  );
  String get cycleSharingTitle => _resolve(
    zhCn: '经期记录共享',
    zhTw: '經期記錄共享',
    en: 'Share cycle records',
    ja: '生理期間の記録を共有',
    ko: '생리 기간 기록 공유',
  );
  String get cycleSharingSubtitle => _resolve(
    zhCn: '开启后，伴侣可以在日历中看到你的经期记录',
    zhTw: '開啟後，伴侶可以在日曆中看到你的經期記錄',
    en: 'When enabled, your partner can see your cycle records on the calendar',
    ja: 'オンにすると、パートナーがカレンダーであなたの生理期間の記録を確認できます',
    ko: '켜면 파트너가 캘린더에서 내 생리 기간 기록을 볼 수 있습니다',
  );
  String get cycleSharingEnabledLabel => _resolve(
    zhCn: '已共享',
    zhTw: '已共享',
    en: 'Shared',
    ja: '共有中',
    ko: '공유됨',
  );
  String get cycleSharingDisabledLabel => _resolve(
    zhCn: '未共享',
    zhTw: '未共享',
    en: 'Not shared',
    ja: '未共有',
    ko: '공유 안 함',
  );
  String get privacySettingsHiddenForMale => _resolve(
    zhCn: '当前没有需要设置的隐私共享项。',
    zhTw: '目前沒有需要設定的隱私共享項。',
    en: 'There are no privacy sharing options for this profile.',
    ja: 'このプロフィールで設定できる共有項目はありません。',
    ko: '이 프로필에서 설정할 개인정보 공유 항목이 없습니다.',
  );
  String get viewProfileTitle => _resolve(
    zhCn: '个人资料',
    zhTw: '個人資料',
    en: 'Profile',
    ja: 'プロフィール',
    ko: '프로필',
  );
  String get signOutTitle => _resolve(
    zhCn: '退出登录',
    zhTw: '登出',
    en: 'Sign out',
    ja: 'ログアウト',
    ko: '로그아웃',
  );
  String get notificationPreviewEnabledLabel => _resolve(
    zhCn: '预览已开启',
    zhTw: '預覽已開啟',
    en: 'Preview on',
    ja: 'プレビュー有効',
    ko: '미리보기 켜짐',
  );
  String get notificationPreviewDisabledLabel => _resolve(
    zhCn: '预览已关闭',
    zhTw: '預覽已關閉',
    en: 'Preview off',
    ja: 'プレビュー無効',
    ko: '미리보기 꺼짐',
  );
  String get spaceNameTitle => _resolve(
    zhCn: '空间名称',
    zhTw: '空間名稱',
    en: 'Space name',
    ja: 'スペース名',
    ko: '공간 이름',
  );
  String get inviteStatusTitle => _resolve(
    zhCn: '邀请状态',
    zhTw: '邀請狀態',
    en: 'Invite status',
    ja: '招待状態',
    ko: '초대 상태',
  );
  String get inviteCodeCopied => _resolve(
    zhCn: '邀请码已复制',
    zhTw: '邀請碼已複製',
    en: 'Invite code copied',
    ja: '招待コードをコピーしました',
    ko: '초대 코드가 복사되었습니다',
  );
  String get inviteCodeEmptyError => _resolve(
    zhCn: '请输入邀请码',
    zhTw: '請輸入邀請碼',
    en: 'Please enter an invite code',
    ja: '招待コードを入力してください',
    ko: '초대 코드를 입력하세요',
  );
  String get inviteAlreadyPairedError => _resolve(
    zhCn: '你已经在配对空间中',
    zhTw: '你已經在配對空間中',
    en: 'You are already in a paired space',
    ja: '既にペアのスペースに参加しています',
    ko: '이미 페어 공간에 있습니다',
  );
  String get inviteAccepting => _resolve(
    zhCn: '正在加入...',
    zhTw: '正在加入...',
    en: 'Joining...',
    ja: '参加中...',
    ko: '참여 중...',
  );
  String get exitSpaceSection => _resolve(
    zhCn: '退出空间',
    zhTw: '退出空間',
    en: 'Exit space',
    ja: 'スペースを退出',
    ko: '공간 나가기',
  );
  String get exitSpaceButton => _resolve(
    zhCn: '退出双人空间',
    zhTw: '退出雙人空間',
    en: 'Exit couple space',
    ja: 'カップルスペースを退出',
    ko: '커플 공간 나가기',
  );
  String get exitSpaceWarningTitle => _resolve(
    zhCn: '退出双人空间',
    zhTw: '退出雙人空間',
    en: 'Exit couple space',
    ja: 'カップルスペースを退出',
    ko: '커플 공간 나가기',
  );
  String get exitSpaceWarningBody => _resolve(
    zhCn: '退出后，你们双方都会回到单人态。双人空间中的计划、随记、日历数据不会被删除，但双方都将无法继续查看或编辑。后续如重新组成空间，旧空间数据不会自动合并。',
    zhTw: '退出後，你們雙方都會回到單人態。雙人空間中的計畫、隨記、日曆資料不會被刪除，但雙方都將無法繼續檢視或編輯。後續如重新組成空間，舊空間資料不會自動合併。',
    en: 'After exiting, both of you will return to single mode. Plans, notes, and calendar data in this space will not be deleted, but neither of you will be able to view or edit them. If you form a new space later, old data will not be merged automatically.',
    ja: '退出後、お二人ともシングルモードに戻ります。このスペースのプラン、メモ、カレンダーデータは削除されませんが、閲覧・編集できなくなります。後で新しいスペースを作成しても、旧データは自動的に統合されません。',
    ko: '나가면 두 사람 모두 싱글 모드로 돌아갑니다. 이 공간의 계획, 메모, 캘린더 데이터는 삭제되지 않지만, 더 이상 볼 수 없고 편집할 수 없습니다. 나중에 새 공간을 만들어도 이전 데이터는 자동으로 병합되지 않습니다.',
  );
  String get exitSpaceConfirmTitle => _resolve(
    zhCn: '确认退出',
    zhTw: '確認退出',
    en: 'Confirm exit',
    ja: '退出を確認',
    ko: '나가기 확인',
  );
  String get exitSpaceConfirmBody => _resolve(
    zhCn: '确定要发起退出双人空间的请求吗？对方确认后，空间将关闭。',
    zhTw: '確定要發起退出雙人空間的請求嗎？對方確認後，空間將關閉。',
    en: 'Are you sure you want to request exiting the couple space? The space will close once your partner confirms.',
    ja: 'カップルスペースの退出リクエストを送信しますか？パートナーが確認すると、スペースは閉鎖されます。',
    ko: '커플 공간 나가기 요청을 보내시겠습니까? 상대방이 확인하면 공간이 닫힙니다.',
  );
  String get exitSpaceWaiting => _resolve(
    zhCn: '已发起退出请求，等待对方确认',
    zhTw: '已發起退出請求，等待對方確認',
    en: 'Exit requested. Waiting for partner to confirm.',
    ja: '退出リクエストを送信しました。パートナーの確認を待っています。',
    ko: '나가기 요청이 전송되었습니다. 상대방의 확인을 기다리는 중입니다.',
  );
  String get exitSpacePartnerRequest => _resolve(
    zhCn: '对方请求退出双人空间',
    zhTw: '對方請求退出雙人空間',
    en: 'Partner requests to exit the couple space',
    ja: 'パートナーがカップルスペースの退出をリクエストしました',
    ko: '상대방이 커플 공간 나가기를 요청했습니다',
  );
  String get exitSpaceApproveButton => _resolve(
    zhCn: '同意退出',
    zhTw: '同意退出',
    en: 'Approve exit',
    ja: '退出を承認',
    ko: '나가기 승인',
  );
  String get exitSpaceApproveConfirmTitle => _resolve(
    zhCn: '确认同意退出',
    zhTw: '確認同意退出',
    en: 'Confirm exit approval',
    ja: '退出承認の確認',
    ko: '나가기 승인 확인',
  );
  String get exitSpaceApproveConfirmBody => _resolve(
    zhCn: '同意后，双人空间将关闭，双方都将回到单人态。空间中的数据不会删除，但双方将无法继续查看或编辑。确定继续吗？',
    zhTw: '同意後，雙人空間將關閉，雙方都將回到單人態。空間中的資料不會刪除，但雙方將無法繼續檢視或編輯。確定繼續嗎？',
    en: 'Once approved, the couple space will close and both of you will return to single mode. Data will not be deleted, but neither of you can view or edit it. Continue?',
    ja: '承認後、カップルスペースは閉鎖され、お二人ともシングルモードに戻ります。データは削除されませんが、閲覧・編集できなくなります。続行しますか？',
    ko: '승인하면 커플 공간이 닫히고 두 사람 모두 싱글 모드로 돌아갑니다. 데이터는 삭제되지 않지만 볼 수 없고 편집할 수 없습니다. 계속하시겠습니까?',
  );
  String get exitSpaceSuccess => _resolve(
    zhCn: '已退出双人空间',
    zhTw: '已退出雙人空間',
    en: 'Exited the couple space',
    ja: 'カップルスペースを退出しました',
    ko: '커플 공간을 나갔습니다',
  );
  String get exitSpaceError => _resolve(
    zhCn: '操作失败，请稍后重试',
    zhTw: '操作失敗，請稍後重試',
    en: 'Operation failed. Please try again later.',
    ja: '操作に失敗しました。後でもう一度お試しください。',
    ko: '작업에 실패했습니다. 나중에 다시 시도하세요.',
  );
  String get exitSpaceStatusActive => _resolve(
    zhCn: '双人空间已开启',
    zhTw: '雙人空間已開啟',
    en: 'Couple space is active',
    ja: 'カップルスペースは有効です',
    ko: '커플 공간이 활성화되어 있습니다',
  );
  String spaceSharingWithPartner(String partnerName) => _resolve(
    zhCn: '与 $partnerName 共享中',
    zhTw: '與 $partnerName 共享中',
    en: 'Sharing with $partnerName',
    ja: '$partnerName と共有中',
    ko: '$partnerName과 공유 중',
  );
  String get exitSpaceReturnToSingleHint => _resolve(
    zhCn: '退出后双方回到单人态',
    zhTw: '退出後雙方回到單人態',
    en: 'Both return to single mode after exit',
    ja: '退出後、ふたりともシングルモードに戻ります',
    ko: '나가면 두 사람 모두 싱글 모드로 돌아갑니다',
  );
  String get sharedRulesTitle => _resolve(
    zhCn: '共享规则',
    zhTw: '共享規則',
    en: 'Shared rules',
    ja: '共有ルール',
    ko: '공유 규칙',
  );
  String get relationshipDateTitle => _resolve(
    zhCn: '关系起点',
    zhTw: '關係起點',
    en: 'Relationship date',
    ja: '交際開始日',
    ko: '교제 시작일',
  );
  String get cyclePrivacyTitle => _resolve(
    zhCn: '经期记录共享规则',
    zhTw: '經期記錄共享規則',
    en: 'Cycle sharing rule',
    ja: '生理記録の共有ルール',
    ko: '생리 기록 공유 규칙',
  );
  String get exportUnlinkTitle => _resolve(
    zhCn: '导出与解绑',
    zhTw: '匯出與解綁',
    en: 'Export and unlink',
    ja: 'エクスポートと解除',
    ko: '내보내기 및 연결 해제',
  );
  String get themeSystemLabel => _resolve(
    zhCn: '跟随系统',
    zhTw: '跟隨系統',
    en: 'System',
    ja: 'システム',
    ko: '시스템',
  );
  String get themeLightLabel => _resolve(
    zhCn: '浅色',
    zhTw: '淺色',
    en: 'Light',
    ja: 'ライト',
    ko: '라이트',
  );
  String get themeDarkLabel => _resolve(
    zhCn: '深色',
    zhTw: '深色',
    en: 'Dark',
    ja: 'ダーク',
    ko: '다크',
  );

  List<PlanItemCopy> get plans => isChinese
      ? const [
          PlanItemCopy(
            title: '把六月短途出门定下来',
            body: '先决定是去海边还是去山里，别拖到最后一周。',
            statusLabel: '待讨论',
            helperLabel: '还没定日期',
          ),
          PlanItemCopy(
            title: '给客厅换一盏更暖的落地灯',
            body: '想找一盏晚上看书时更舒服的灯。',
            statusLabel: '想法中',
            helperLabel: '生活计划',
          ),
          PlanItemCopy(
            title: '把七月那顿生日饭店先挑出来',
            body: '定下来以后就可以放进日历。',
            statusLabel: '准备安排',
            helperLabel: '可转入日历',
          ),
        ]
      : const [
          PlanItemCopy(
            title: 'Settle the short June getaway',
            body:
                'Pick sea or mountains before the last week sneaks up on you.',
            statusLabel: 'To discuss',
            helperLabel: 'No date yet',
          ),
          PlanItemCopy(
            title: 'Find a warmer floor lamp for the living room',
            body: 'Something that feels better when reading at night.',
            statusLabel: 'Idea',
            helperLabel: 'Home plan',
          ),
          PlanItemCopy(
            title: 'Pick the July birthday dinner place early',
            body: 'Once it is decided, it can move into calendar.',
            statusLabel: 'Ready to schedule',
            helperLabel: 'Can move to calendar',
          ),
        ];

  List<NoteItemCopy> get notes => isChinese
      ? const [
          NoteItemCopy(author: '阿澈', timeLabel: '刚刚', text: '到家啦，楼下买到了你喜欢的豆花。'),
          NoteItemCopy(
            author: '小满',
            timeLabel: '昨晚 21:18',
            text: '今天风有点大，回来的时候记得把外套拉好。',
          ),
          NoteItemCopy(
            author: '阿澈',
            timeLabel: '周日 17:40',
            text: '下次还想跟你去那家小店，汤底真的很暖。',
          ),
        ]
      : const [
          NoteItemCopy(
            author: 'Ache',
            timeLabel: 'Just now',
            text:
                'I am home. The tofu pudding place downstairs still had your favorite one.',
          ),
          NoteItemCopy(
            author: 'Xiaoman',
            timeLabel: 'Last night 9:18 PM',
            text: 'The wind was strong today. Zip your jacket on the way back.',
          ),
          NoteItemCopy(
            author: 'Ache',
            timeLabel: 'Sun 5:40 PM',
            text:
                'I still want to go back to that little place with you. The broth felt so warm.',
          ),
        ];

  String get spaceNameValue => _resolve(
    zhCn: '两个人的小屋',
    zhTw: '兩個人的小屋',
    en: 'Little Room for Two',
    ja: 'ふたりの小屋',
    ko: '두 사람의 작은 집',
  );
  String get inviteStatusValue => _resolve(
    zhCn: '邀请流程还没接真实账号，先保留结构位。',
    en: 'Invite flow is still local-only for now.',
  );
  String get sharedRulesValue => _resolve(
    zhCn: '日历和计划默认是共享的，随记默认只有作者自己能改。',
    en: 'Calendar and plans are shared by default. Notes are editable only by their author.',
  );
  String get relationshipDateValue => _resolve(
    zhCn: '2025 年 10 月 5 日',
    en: 'October 5, 2025',
  );
  String get calendarDetailsTitle => _resolve(
    zhCn: '这一天有什么',
    en: 'What is on this day',
  );
  String get calendarUpcomingTitle => _resolve(
    zhCn: '近期事项',
    zhTw: '近期事項',
    en: 'Coming up soon',
    ja: '近日の予定',
    ko: '다가오는 일정',
  );
  String get calendarRepeatYearlyLabel => _resolve(
    zhCn: '每年重复',
    zhTw: '每年重複',
    en: 'Repeats yearly',
    ja: '毎年繰り返し',
    ko: '매년 반복',
  );
  String get calendarRepeatOnceLabel => _resolve(
    zhCn: '单次安排',
    zhTw: '單次安排',
    en: 'One-time',
    ja: '一回限り',
    ko: '일회성',
  );
  String get calendarTodayLabel => _resolve(
    zhCn: '今天',
    zhTw: '今天',
    en: 'Today',
    ja: '今日',
    ko: '오늘',
  );
  String get calendarTomorrowLabel => _resolve(
    zhCn: '明天',
    zhTw: '明天',
    en: 'Tomorrow',
    ja: '明日',
    ko: '내일',
  );

  String calendarTypeLabel(CalendarEntryType type) => switch (type) {
    CalendarEntryType.anniversary => _resolve(
      zhCn: '纪念日',
      zhTw: '紀念日',
      en: 'Anniversary',
      ja: '記念日',
      ko: '기념일',
    ),
    CalendarEntryType.datePlan => _resolve(
      zhCn: '约会',
      zhTw: '約會',
      en: 'Date',
      ja: 'デート',
      ko: '데이트',
    ),
    CalendarEntryType.reminder => _resolve(
      zhCn: '提醒',
      zhTw: '提醒',
      en: 'Reminder',
      ja: 'リマインダー',
      ko: '알림',
    ),
    CalendarEntryType.cycle => _resolve(
      zhCn: '经期',
      zhTw: '經期',
      en: 'Cycle',
      ja: '生理期間',
      ko: '생리 기간',
    ),
  };

  String calendarRepeatLabel(CalendarRepeatRule repeatRule) =>
      switch (repeatRule) {
        CalendarRepeatRule.none => calendarRepeatOnceLabel,
        CalendarRepeatRule.yearly => calendarRepeatYearlyLabel,
      };

  // ── Calendar composer dialog ──────────────────────────────────────────

  String get calendarCreateDialogTitle => _resolve(
    zhCn: '新建日历项',
    zhTw: '新建日曆項',
    en: 'Add to calendar',
    ja: 'カレンダーに追加',
    ko: '캘린더에 추가',
  );
  String get calendarTitleHint => _resolve(
    zhCn: '标题',
    zhTw: '標題',
    en: 'Title',
    ja: 'タイトル',
    ko: '제목',
  );
  String get calendarDescriptionHint => _resolve(
    zhCn: '描述（可选）',
    zhTw: '描述（可選）',
    en: 'Description (optional)',
    ja: '説明（任意）',
    ko: '설명 (선택)',
  );
  String get calendarDateLabel => _resolve(
    zhCn: '日期',
    zhTw: '日期',
    en: 'Date',
    ja: '日付',
    ko: '날짜',
  );
  String get calendarTimeLabel => _resolve(
    zhCn: '时间',
    zhTw: '時間',
    en: 'Time',
    ja: '時間',
    ko: '시간',
  );
  String get calendarCreateButton => _resolve(
    zhCn: '创建',
    zhTw: '建立',
    en: 'Create',
    ja: '作成',
    ko: '생성',
  );
  String get calendarCreateFailedError => _resolve(
    zhCn: '创建失败，请重试',
    zhTw: '建立失敗，請重試',
    en: 'Failed to create. Please try again.',
    ja: '作成に失敗しました。もう一度お試しください。',
    ko: '생성에 실패했습니다. 다시 시도하세요.',
  );
  String get cycleCreateDialogTitle => _resolve(
    zhCn: '记录经期',
    zhTw: '記錄經期',
    en: 'Record cycle',
    ja: '生理期間を記録',
    ko: '생리 기간 기록',
  );
  String get cycleEditDialogTitle => _resolve(
    zhCn: '编辑经期记录',
    zhTw: '編輯經期記錄',
    en: 'Edit cycle record',
    ja: '生理期間の記録を編集',
    ko: '생리 기간 기록 편집',
  );
  String get cycleStartDateLabel => _resolve(
    zhCn: '开始日期',
    zhTw: '開始日期',
    en: 'Start date',
    ja: '開始日',
    ko: '시작일',
  );
  String get cycleEndDateLabel => _resolve(
    zhCn: '结束日期',
    zhTw: '結束日期',
    en: 'End date',
    ja: '終了日',
    ko: '종료일',
  );
  String get cycleEndDateUnsetLabel => _resolve(
    zhCn: '未填写',
    zhTw: '未填寫',
    en: 'Not set',
    ja: '未設定',
    ko: '미설정',
  );
  String get cycleNoteHint => _resolve(
    zhCn: '备注（可选）',
    zhTw: '備註（可選）',
    en: 'Note (optional)',
    ja: 'メモ（任意）',
    ko: '메모 (선택)',
  );
  String get cycleSaveButton => _resolve(
    zhCn: '保存',
    zhTw: '儲存',
    en: 'Save',
    ja: '保存',
    ko: '저장',
  );
  String get cycleCreateFailedError => _resolve(
    zhCn: '经期记录保存失败，请重试',
    zhTw: '經期記錄儲存失敗，請重試',
    en: 'Failed to save cycle record. Please try again.',
    ja: '生理期間の記録を保存できませんでした。もう一度お試しください。',
    ko: '생리 기간 기록을 저장하지 못했습니다. 다시 시도하세요.',
  );
  String get cycleDeleteConfirmTitle => _resolve(
    zhCn: '删除这条经期记录？',
    zhTw: '刪除這條經期記錄？',
    en: 'Delete this cycle record?',
    ja: 'この生理期間の記録を削除しますか？',
    ko: '이 생리 기간 기록을 삭제하시겠습니까?',
  );
  String get cycleDeleteConfirmBody => _resolve(
    zhCn: '删除后，这条经期记录将不再显示在日历中。',
    zhTw: '刪除後，這條經期記錄將不再顯示在日曆中。',
    en: 'Once deleted, this cycle record will no longer appear in the calendar.',
    ja: '削除すると、この記録はカレンダーに表示されなくなります。',
    ko: '삭제하면 이 기록은 캘린더에 더 이상 표시되지 않습니다.',
  );
  String get cycleDeleteFailedError => _resolve(
    zhCn: '经期记录删除失败，请重试',
    zhTw: '經期記錄刪除失敗，請重試',
    en: 'Failed to delete cycle record. Please try again.',
    ja: '生理期間の記録を削除できませんでした。もう一度お試しください。',
    ko: '생리 기간 기록을 삭제하지 못했습니다. 다시 시도하세요.',
  );
  String get cycleSharedLabel => _resolve(
    zhCn: '已共享给伴侣',
    zhTw: '已共享給伴侶',
    en: 'Shared with partner',
    ja: 'パートナーと共有中',
    ko: '파트너와 공유됨',
  );
  String get cyclePrivateLabel => _resolve(
    zhCn: '仅自己可见',
    zhTw: '僅自己可見',
    en: 'Only visible to you',
    ja: '自分だけに表示',
    ko: '나에게만 표시',
  );
  String get cyclePartnerRecordLabel => _resolve(
    zhCn: '伴侣的经期记录',
    zhTw: '伴侶的經期記錄',
    en: "Partner's cycle record",
    ja: 'パートナーの生理期間記録',
    ko: '파트너의 생리 기간 기록',
  );
  String get cycleDateRangeSeparator => _resolve(
    zhCn: '至',
    zhTw: '至',
    en: 'to',
    ja: '〜',
    ko: '~',
  );
  String get calendarNoEventsYet => _resolve(
    zhCn: '还没有日历事件',
    zhTw: '還沒有日曆事件',
    en: 'No calendar events yet',
    ja: 'カレンダーイベントはまだありません',
    ko: '캘린더 이벤트가 아직 없습니다',
  );
  String get calendarSelectedDayEmpty => _resolve(
    zhCn: '这一天暂无安排',
    zhTw: '這一天暫無安排',
    en: 'Nothing scheduled this day',
    ja: 'この日の予定はありません',
    ko: '이 날은 예정이 없습니다',
  );
  String get calendarDeleteConfirmTitle => _resolve(
    zhCn: '删除这个事件？',
    zhTw: '刪除這個事件？',
    en: 'Delete this event?',
    ja: 'このイベントを削除しますか？',
    ko: '이 이벤트를 삭제하시겠습니까?',
  );
  String get calendarDeleteConfirmBody => _resolve(
    zhCn: '删除后，这个事件将不再显示在日历中。',
    zhTw: '刪除後，這個事件將不再顯示在日曆中。',
    en: 'Once deleted, this event will no longer appear in the calendar.',
    ja: '削除すると、このイベントはカレンダーに表示されなくなります。',
    ko: '삭제하면 이 이벤트는 캘린더에 더 이상 표시되지 않습니다.',
  );
  String get calendarDeleteButton => _resolve(
    zhCn: '删除',
    zhTw: '刪除',
    en: 'Delete',
    ja: '削除',
    ko: '삭제',
  );
  String get calendarDeleteFailedError => _resolve(
    zhCn: '删除失败，请重试',
    zhTw: '刪除失敗，請重試',
    en: 'Failed to delete. Please try again.',
    ja: '削除に失敗しました。もう一度お試しください。',
    ko: '삭제에 실패했습니다. 다시 시도하세요.',
  );
  String createdByLabel(String name) => _resolve(
    zhCn: '由 $name 创建',
    zhTw: '由 $name 建立',
    en: 'Created by $name',
    ja: '$name が作成',
    ko: '$name 생성',
  );

  List<DateTime> calendarVisibleDaysForMonth(DateTime displayMonth) {
    final monthStart = DateTime(displayMonth.year, displayMonth.month);
    var gridStart = monthStart.subtract(Duration(days: monthStart.weekday - 1));

    if (_sameDate(gridStart, monthStart)) {
      gridStart = gridStart.subtract(const Duration(days: 7));
    }

    return List<DateTime>.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );
  }

  String formatCalendarMonthYear(DateTime date) {
    return switch (language) {
      AppLanguage.zhCn || AppLanguage.zhTw =>
        '${date.year} 年 ${date.month} 月',
      AppLanguage.en =>
        '${_englishMonthNames[date.month - 1]} ${date.year}',
      AppLanguage.ja => '${date.year}年${date.month}月',
      AppLanguage.ko => '${date.year}년 ${date.month}월',
    };
  }

  String formatCalendarDate(
    DateTime date, {
    bool includeWeekday = false,
    bool includeTime = false,
  }) {
    final buffer = StringBuffer();

    switch (language) {
      case AppLanguage.zhCn || AppLanguage.zhTw:
        buffer.write('${date.month} 月 ${date.day} 日');
      case AppLanguage.en:
        buffer.write('${_englishMonthNames[date.month - 1]} ${date.day}');
      case AppLanguage.ja:
        buffer.write('${date.month}月${date.day}日');
      case AppLanguage.ko:
        buffer.write('${date.month}월 ${date.day}일');
    }

    if (includeWeekday) {
      buffer.write(' · ${calendarWeekdayLabel(date.weekday)}');
    }

    if (includeTime) {
      buffer.write(isChinese ? ' ' : ', ');
      buffer.write(_formatTime(date));
    }

    return buffer.toString();
  }

  String calendarWeekdayLabel(int weekday) => switch (language) {
    AppLanguage.zhCn || AppLanguage.zhTw =>
      _chineseWeekdayNames[weekday - 1],
    AppLanguage.en => _englishWeekdayNames[weekday - 1],
    AppLanguage.ja => _japaneseWeekdayNames[weekday - 1],
    AppLanguage.ko => _koreanWeekdayNames[weekday - 1],
  };

  String formatCountdownLabel(DateTime target, DateTime reference) {
    final difference = DateTime(target.year, target.month, target.day)
        .difference(DateTime(reference.year, reference.month, reference.day))
        .inDays;

    if (difference <= 0) {
      return calendarTodayLabel;
    }

    if (difference == 1) {
      return calendarTomorrowLabel;
    }

    return switch (language) {
      AppLanguage.zhCn => '$difference 天后',
      AppLanguage.zhTw => '$difference 天後',
      AppLanguage.en => 'In $difference days',
      AppLanguage.ja => '$difference日後',
      AppLanguage.ko => '$difference일 후',
    };
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static const List<String> _englishMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _englishWeekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _chineseWeekdayNames = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static const List<String> _japaneseWeekdayNames = [
    '月曜日',
    '火曜日',
    '水曜日',
    '木曜日',
    '金曜日',
    '土曜日',
    '日曜日',
  ];

  static const List<String> _koreanWeekdayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];
}

class CalendarEntryOccurrence {
  const CalendarEntryOccurrence({
    required this.entry,
    required this.occurrence,
  });

  final CalendarEntryData entry;
  final DateTime occurrence;

  bool get showsTime => occurrence.hour != 0 || occurrence.minute != 0;
}

class PlanItemCopy {
  const PlanItemCopy({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.helperLabel,
  });

  final String title;
  final String body;
  final String statusLabel;
  final String helperLabel;
}

class NoteItemCopy {
  const NoteItemCopy({
    required this.author,
    required this.timeLabel,
    required this.text,
  });

  final String author;
  final String timeLabel;
  final String text;
}

enum CalendarEntryType { anniversary, datePlan, reminder, cycle }

enum CalendarRepeatRule { none, yearly }

class CalendarEntryData {
  const CalendarEntryData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.repeatRule,
  });

  final String id;
  final CalendarEntryType type;
  final String title;
  final String description;
  final DateTime startsAt;
  final CalendarRepeatRule repeatRule;

  bool occursOn(DateTime day) {
    if (repeatRule == CalendarRepeatRule.yearly) {
      return day.month == startsAt.month && day.day == startsAt.day;
    }

    return day.year == startsAt.year &&
        day.month == startsAt.month &&
        day.day == startsAt.day;
  }

  DateTime? nextOccurrenceFrom(DateTime reference) {
    if (repeatRule == CalendarRepeatRule.none) {
      return startsAt.isBefore(reference) ? null : startsAt;
    }

    final thisYear = DateTime(
      reference.year,
      startsAt.month,
      startsAt.day,
      startsAt.hour,
      startsAt.minute,
    );

    if (!thisYear.isBefore(reference)) {
      return thisYear;
    }

    return DateTime(
      reference.year + 1,
      startsAt.month,
      startsAt.day,
      startsAt.hour,
      startsAt.minute,
    );
  }
}
