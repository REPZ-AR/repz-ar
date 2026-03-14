class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String supabaseRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'io.supabase.flutter://login-callback/',
  );

  /// The Web OAuth 2.0 client ID from Google Cloud Console.
  /// Required for native Google Sign-In on Android & iOS so that an ID token
  /// is returned. Pass via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Pass SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
    if (googleWebClientId.isEmpty) {
      throw StateError(
        'Missing Google config. Pass GOOGLE_WEB_CLIENT_ID via --dart-define.',
      );
    }
  }
}

