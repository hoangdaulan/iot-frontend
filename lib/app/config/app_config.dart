class AppConfig {
  static final String webUrl = const String.fromEnvironment('WEB_URL');

  /// Backend origin, e.g. `http://localhost:8080` (the local docker compose stack).
  static final String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static final String signatureSecret = const String.fromEnvironment('SIGNATURE_SECRET');

  /// `--dart-define=USE_MOCK_API=true` runs the app on the in-memory mock repositories.
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API');
}
