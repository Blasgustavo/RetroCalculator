import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/design_system/token_validation.dart';

@immutable
class SkinManifestEntry {
  const SkinManifestEntry({
    required this.id,
    required this.nameKey,
    required this.version,
    required this.definition,
    required this.definitionYaml,
    required this.checksum,
    required this.rewardDurationHours,
    required this.capabilities,
    required this.source,
    required this.tokens,
  });

  final String id;
  final String nameKey;
  final int version;
  final String definition;
  final String definitionYaml;
  final String checksum;
  final int rewardDurationHours;
  final List<String> capabilities;
  final String source;
  final Map<String, Object?> tokens;

  bool get hasValidChecksum =>
      sha256.convert(utf8.encode(definitionYaml)).toString() == checksum;

  bool get isCompatible =>
      capabilities.every(
        (String id) => const <String>{'normal', 'scientific'}.contains(id),
      ) &&
      validateTokens(tokens).isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'nameKey': nameKey,
    'version': version,
    'definition': definition,
    'definitionYaml': definitionYaml,
    'checksum': checksum,
    'rewardDurationHours': rewardDurationHours,
    'capabilities': capabilities,
    'source': source,
    'tokens': tokens,
  };
}

@immutable
class SkinManifest {
  const SkinManifest({required this.version, required this.entries});

  final int version;
  final List<SkinManifestEntry> entries;

  factory SkinManifest.fromJson(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El manifiesto debe ser un objeto JSON');
    }
    if (decoded['schemaVersion'] != 1) {
      throw const FormatException('schemaVersion no soportado');
    }
    final List<dynamic> rawEntries = decoded['entries'] as List<dynamic>;
    final int version = (decoded['version'] as num).toInt();
    return SkinManifest(
      version: version,
      entries: rawEntries.map((dynamic item) {
        final Map<String, dynamic> json = item as Map<String, dynamic>;
        return SkinManifestEntry(
          id: json['id'] as String,
          nameKey: json['nameKey'] as String,
          version: (json['version'] as num?)?.toInt() ?? version,
          definition: json['definition'] as String,
          definitionYaml: json['definitionYaml'] as String,
          checksum: json['checksum'] as String,
          rewardDurationHours:
              (json['rewardDurationHours'] as num?)?.toInt() ?? 24,
          capabilities:
              (json['capabilities'] as List<dynamic>?)?.cast<String>() ??
              const <String>[],
          source: json['source'] as String,
          tokens: json['tokens'] as Map<String, Object?>,
        );
      }).toList(),
    );
  }

  String toJson() => jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'version': version,
    'entries': entries
        .map((SkinManifestEntry entry) => entry.toJson())
        .toList(),
  });
}
