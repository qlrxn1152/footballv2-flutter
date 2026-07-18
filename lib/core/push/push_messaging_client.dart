import 'push_messaging_client_base.dart';
import 'push_messaging_client_stub.dart'
    if (dart.library.js_interop) 'push_messaging_client_web.dart';

export 'push_messaging_client_base.dart';

PushMessagingClient createPushMessagingClient() =>
    createPlatformPushMessagingClient();
