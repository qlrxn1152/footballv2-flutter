import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/analytics/app_visit_tracker.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const app = ProviderScope(
    child: AppVisitTracker(child: FootballV2App()),
  );

  final monitoringEnabled =
      AppConfig.sentryDsn.isNotEmpty &&
      (kReleaseMode || AppConfig.enableSentryInDebug);
  if (!monitoringEnabled) {
    runApp(app);
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.sentryEnvironment;
      options.release = AppConfig.sentryRelease;
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0.05;
    },
    appRunner: () => runApp(SentryWidget(child: app)),
  );
}
