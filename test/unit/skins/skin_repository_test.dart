import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/skins/data/local/skin_cache.dart';
import 'package:retro_calculator/features/skins/data/skin_repository.dart';
import 'package:retro_calculator/platform/preferences/key_value_store.dart';

class _MemoryStore implements KeyValueStore {
  String? value;
  @override
  Future<String?> getString(String key) async => value;
  @override
  Future<void> setString(String key, String value) async {
    this.value = value;
  }
}

class _StaticSource implements SkinManifestSource {
  const _StaticSource(this.raw);
  final String raw;
  @override
  Future<String> fetch() async => raw;
}

class _OfflineSource implements SkinManifestSource {
  @override
  Future<String> fetch() => throw const SocketExceptionMock();
}

class SocketExceptionMock implements Exception {
  const SocketExceptionMock();
}

void main() {
  final String valid = File('assets/catalog/manifest.json').readAsStringSync();

  test('ignora entradas inválidas una a una sin perder las válidas', () async {
    final _MemoryStore store = _MemoryStore()..value = valid;
    final Map<String, dynamic> mixed =
        jsonDecode(valid) as Map<String, dynamic>;
    mixed['version'] = 2;
    final List<dynamic> entries = mixed['entries'] as List<dynamic>;
    final Map<String, dynamic> good = entries.single as Map<String, dynamic>;
    final Map<String, dynamic> bad = Map<String, dynamic>.from(good)
      ..['id'] = 'remote_bad'
      ..['checksum'] = '0' * 64;
    entries.add(bad);
    final SkinRepository repository = SkinRepository.remote(
      _StaticSource(jsonEncode(mixed)),
      SkinCache(store),
    );
    final List<dynamic> skins = await repository.load();
    expect(skins.map((dynamic skin) => skin.id), contains('lcd_classica'));
    expect(skins.map((dynamic skin) => skin.id), isNot(contains('remote_bad')));
    final Map<String, dynamic> cached =
        jsonDecode(store.value!) as Map<String, dynamic>;
    expect(cached['version'], 2);
    expect((cached['entries'] as List<dynamic>), hasLength(1));
  });

  test('sin red devuelve la base compilada y la caché válida', () async {
    final _MemoryStore store = _MemoryStore()..value = valid;
    final SkinRepository repository = SkinRepository.remote(
      _OfflineSource(),
      SkinCache(store),
    );
    expect((await repository.load()).length, 2);
  });

  test('versión remota menor no reemplaza la caché', () async {
    final Map<String, dynamic> older =
        jsonDecode(valid) as Map<String, dynamic>;
    older['version'] = 0;
    final _MemoryStore store = _MemoryStore()..value = valid;
    await SkinRepository.remote(
      _StaticSource(jsonEncode(older)),
      SkinCache(store),
    ).load();
    expect(store.value, valid);
  });

  test('descarta la caché corrupta y conserva el fallback offline', () async {
    const String corrupt =
        '{"schemaVersion":1,"version":1,"entries":[{"id":"x"}]}';
    final _MemoryStore store = _MemoryStore()..value = corrupt;
    final SkinRepository repository = SkinRepository.remote(
      _OfflineSource(),
      SkinCache(store),
    );
    expect((await repository.load()).map((dynamic skin) => skin.id), <String>[
      'classic_amber',
      'lcd_classica',
    ]);
  });

  test(
    'filtra capacidades y tokens inválidos sin perder los válidos',
    () async {
      final Map<String, dynamic> mixed =
          jsonDecode(valid) as Map<String, dynamic>;
      final List<dynamic> entries = mixed['entries'] as List<dynamic>;
      final Map<String, dynamic> good = entries.single as Map<String, dynamic>;
      final Map<String, dynamic> badCapability = Map<String, dynamic>.from(good)
        ..['id'] = 'remote_bad_capability'
        ..['capabilities'] = <String>['quantum'];
      final Map<String, dynamic> invalidTokens = Map<String, dynamic>.from(
        good['tokens'] as Map<String, dynamic>,
      )..['keyMinHeight'] = 44;
      final Map<String, dynamic> badToken = Map<String, dynamic>.from(good)
        ..['id'] = 'remote_bad_token'
        ..['tokens'] = invalidTokens;
      final Map<String, dynamic> remoteGood = Map<String, dynamic>.from(good)
        ..['id'] = 'remote_good';
      entries
        ..clear()
        ..add(badCapability)
        ..add(badToken)
        ..add(remoteGood);
      final _MemoryStore store = _MemoryStore();
      final SkinRepository repository = SkinRepository.remote(
        _StaticSource(jsonEncode(mixed)),
        SkinCache(store),
      );
      final List<dynamic> skins = await repository.load();
      final Iterable<dynamic> ids = skins.map((dynamic skin) => skin.id);
      expect(ids, contains('remote_good'));
      expect(ids, isNot(contains('remote_bad_capability')));
      expect(ids, isNot(contains('remote_bad_token')));
      final Map<String, dynamic> cached =
          jsonDecode(store.value!) as Map<String, dynamic>;
      expect(
        (cached['entries'] as List<dynamic>).map(
          (dynamic entry) => entry['id'],
        ),
        <dynamic>['remote_good'],
      );
    },
  );
}
