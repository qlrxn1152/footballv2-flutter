import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract interface class VisitorIdStore {
  Future<String> getOrCreate();
}

class SecureVisitorIdStore implements VisitorIdStore {
  SecureVisitorIdStore({
    FlutterSecureStorage? storage,
    String Function()? idFactory,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _idFactory = idFactory ?? const Uuid().v4;

  static const storageKey = 'analytics_visitor_id';

  final FlutterSecureStorage _storage;
  final String Function() _idFactory;
  Future<String>? _pendingId;

  @override
  Future<String> getOrCreate() => _pendingId ??= _loadOrCreate();

  Future<String> _loadOrCreate() async {
    final storedId = await _storage.read(key: storageKey);
    if (storedId != null && storedId.isNotEmpty) return storedId;

    final visitorId = _idFactory();
    await _storage.write(key: storageKey, value: visitorId);
    return visitorId;
  }
}

final visitorIdStoreProvider = Provider<VisitorIdStore>(
  (ref) => SecureVisitorIdStore(),
);
