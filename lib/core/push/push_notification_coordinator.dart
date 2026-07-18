import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'push_notification_service.dart';

class PushNotificationCoordinator extends ConsumerStatefulWidget {
  const PushNotificationCoordinator({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushNotificationCoordinator> createState() =>
      _PushNotificationCoordinatorState();
}

class _PushNotificationCoordinatorState
    extends ConsumerState<PushNotificationCoordinator> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncToken);
  }

  Future<void> _syncToken() async {
    try {
      await ref.read(pushNotificationServiceProvider).syncIfAuthorized();
    } catch (error, stackTrace) {
      if (Sentry.isEnabled) {
        await Sentry.captureException(error, stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
