import 'package:flutter/services.dart';

import '../skin_repository.dart';

class AssetManifestSource implements SkinManifestSource {
  const AssetManifestSource(this._assetPath);

  final String _assetPath;

  @override
  Future<String> fetch() => rootBundle.loadString(_assetPath);
}
