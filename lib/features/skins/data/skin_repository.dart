import 'package:flutter/material.dart';

import '../../../core/design_system/skin_tokens.dart';
import '../domain/skin.dart';
import 'local/skin_cache.dart';
import 'remote/skin_manifest.dart';

abstract interface class SkinManifestSource {
  Future<String> fetch();
}

class SkinRepository {
  /// Base compilada: la LCD clásica consume tokens generados por
  /// tool/skins/generate.dart. `Skin.generatedDefault` (48 dp) se activa en V9;
  /// hasta entonces el fallback heredado se mantiene para no romper los tests.
  static const List<Skin> compiledBase = <Skin>[
    Skin.classicAmber,
    Skin.lcdClasica,
  ];

  /// Constructor de T13: base compilada, sin manifiesto ni caché.
  const SkinRepository() : _source = null, _cache = null;

  const SkinRepository.remote(this._source, this._cache);

  final SkinManifestSource? _source;
  final SkinCache? _cache;

  Future<List<Skin>> load() async {
    if (_source == null || _cache == null) {
      return compiledBase;
    }
    SkinManifest? cached;
    try {
      cached = await _cache.loadValid();
    } on Object {
      cached = null;
    }
    try {
      final SkinManifest parsed = SkinManifest.fromJson(await _source.fetch());
      final List<SkinManifestEntry> accepted = parsed.entries
          .where(
            (SkinManifestEntry entry) =>
                entry.hasValidChecksum && entry.isCompatible,
          )
          .toList();
      if (accepted.isEmpty) return _compiledPlus(cached);
      final SkinManifest remote = SkinManifest(
        version: parsed.version,
        entries: accepted,
      );
      if (cached != null && cached.version >= remote.version) {
        return _compiledPlus(cached);
      }
      await _cache.save(remote);
      return _compiledPlus(remote);
    } on FormatException {
      return _compiledPlus(cached);
    } on Object {
      return _compiledPlus(cached);
    }
  }

  List<Skin> _compiledPlus(SkinManifest? manifest) {
    final List<Skin> skins = List<Skin>.from(compiledBase);
    if (manifest == null) return skins;
    for (final SkinManifestEntry entry in manifest.entries) {
      if (skins.any((Skin skin) => skin.id == entry.id)) continue;
      skins.add(
        Skin(
          id: entry.id,
          nameKey: entry.nameKey,
          tokens: _tokensFrom(entry.tokens),
          isFree: true,
          source: entry.source,
        ),
      );
    }
    return skins;
  }
}

SkinTokens _tokensFrom(Map<String, Object?> values) {
  Color color(String key) {
    final String hex = values[key]! as String;
    return Color(int.parse('0xFF${hex.substring(1)}'));
  }

  double number(String key) => (values[key]! as num).toDouble();

  return SkinTokens(
    segmentOn: color('segmentOn'),
    displayBackground: color('displayBackground'),
    displayBorder: color('displayBorder'),
    displayRadius: number('displayRadius'),
    displayPadding: EdgeInsets.symmetric(
      horizontal: number('displayPaddingHorizontal'),
      vertical: number('displayPaddingVertical'),
    ),
    digitWidth: number('digitWidth'),
    digitHeight: number('digitHeight'),
    keyBackground: color('keyBackground'),
    keyForeground: color('keyForeground'),
    keyBorder: color('keyBorder'),
    keyRadius: number('keyRadius'),
    keyPadding: number('keyPadding'),
    keyMinHeight: number('keyMinHeight'),
    screenPadding: number('screenPadding'),
    keyboardHeight: number('keyboardHeight'),
  );
}
