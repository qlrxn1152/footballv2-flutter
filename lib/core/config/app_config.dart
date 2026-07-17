abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://a13dab754ed07d83baeef42d6f0c2128@o4511748845273088.ingest.us.sentry.io/4511748854317056',
  );

  static const sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );

  static const sentryRelease = String.fromEnvironment(
    'SENTRY_RELEASE',
    defaultValue: 'footballv2-flutter@1.0.0+1',
  );

  static const enableSentryInDebug = bool.fromEnvironment(
    'SENTRY_ENABLE_IN_DEBUG',
    defaultValue: false,
  );
}
