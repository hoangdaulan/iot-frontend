class AppConfig {
  static final String webUrl = const String.fromEnvironment('WEB_URL');
  static final String baseUrl = const String.fromEnvironment('BASE_URL');
  static final String signatureSecret = const String.fromEnvironment('SIGNATURE_SECRET');
}
