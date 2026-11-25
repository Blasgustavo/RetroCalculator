import '../../../../platform/preferences/key_value_store.dart';
import '../remote/skin_manifest.dart';

class SkinCache {
  const SkinCache(this._store);

  static const String key = 'skins.manifest.v1';

  final KeyValueStore _store;

  Future<SkinManifest?> loadValid() async {
    final String? raw = await _store.getString(key);
    if (raw == null) return null;
    try {
      final SkinManifest manifest = SkinManifest.fromJson(raw);
      final List<SkinManifestEntry> valid = manifest.entries
          .where(
            (SkinManifestEntry entry) =>
                entry.hasValidChecksum && entry.isCompatible,
          )
          .toList();
      if (valid.isEmpty) return null;
      return SkinManifest(version: manifest.version, entries: valid);
    } on Object {
      return null;
    }
  }

  Future<void> save(SkinManifest manifest) =>
      _store.setString(key, manifest.toJson());
}
