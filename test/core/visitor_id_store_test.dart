import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/analytics/visitor_id_store.dart';

void main() {
  test('방문자 식별자를 한 번 생성하고 계속 재사용한다', () async {
    final storage = _MemorySecureStorage();
    var generatedCount = 0;
    final store = SecureVisitorIdStore(
      storage: storage,
      idFactory: () => 'visitor-${++generatedCount}',
    );

    final first = await store.getOrCreate();
    final second = await store.getOrCreate();

    expect(first, 'visitor-1');
    expect(second, first);
    expect(generatedCount, 1);
    expect(await storage.read(key: SecureVisitorIdStore.storageKey), first);
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}
