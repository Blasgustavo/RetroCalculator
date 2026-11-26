// Adaptador y gate de aplicación del RetroDesign Studio (T27, plan V4).
//
// Dart puro de herramienta: ni Flutter ni UI. Serializa el `DesignSeed` con la
// misma forma que consume `DesignSeed.fromJson`, valida antes de escribir y
// delega la generación de artefactos en `compile.dart`. Un documento inválido
// no produce ni el JSON ni ningún artefacto (ADR-0004).

import 'dart:convert';
import 'dart:io';

import '../artifacts.dart' show designNodeToJson;
import '../compile.dart' show CompileReport, compileDesign, defaultDesignPath;
import '../schema.dart';
import '../validate.dart' show ValidationIssue, validateJson;

/// Serialización completa y round-trip de [seed].
///
/// Reutiliza `designNodeToJson` para los nodos: el Studio no duplica la
/// conversión del spec que ya consumen el validador, el compiler y el renderer.
Map<String, Object?> studioSeedToJson(DesignSeed seed) => <String, Object?>{
  'schemaVersion': seed.schemaVersion,
  'version': seed.version,
  'channels': <Object?>[...seed.channels],
  'skins': <Object?>[
    for (final SkinSpec skin in seed.skins)
      <String, Object?>{
        'id': skin.id,
        'nameKey': skin.nameKey,
        'isDefault': skin.isDefault,
        'tokens': <String, Object?>{...skin.tokens},
        'images': <Object?>[...skin.images],
      },
  ],
  'images': <Object?>[
    for (final ImageSpec image in seed.images)
      <String, Object?>{
        'id': image.id,
        'file': image.file,
        'format': image.format,
        'maxWidth': image.maxWidth,
        'maxHeight': image.maxHeight,
        'checksum': image.checksum,
      },
  ],
  'screens': <String, Object?>{
    for (final MapEntry<String, Map<String, List<DesignNode>>> screen
        in seed.screens.entries)
      screen.key: <String, Object?>{
        for (final MapEntry<String, List<DesignNode>> breakpoint
            in screen.value.entries)
          breakpoint.key: <Object?>[
            for (final DesignNode node in breakpoint.value)
              designNodeToJson(node),
          ],
      },
  },
  'profiles': <Object?>[
    for (final ProfileSpec profile in seed.profiles)
      <String, Object?>{
        'id': profile.id,
        'labelKey': profile.labelKey,
        'capabilityId': profile.capabilityId,
        'isScientific': profile.isScientific,
        'defaultAngleMode': profile.defaultAngleMode,
        'decimalDigits': profile.decimalDigits,
        'inputs': <Object?>[...profile.inputs],
        'formulas': <String, Object?>{
          for (final MapEntry<String, String> formula
              in profile.formulas.entries)
            formula.key: formula.value,
        },
        'keyRows': <Object?>[
          for (final List<String> row in profile.keyRows) <Object?>[...row],
        ],
      },
  ],
  'dimensions': <String, Object?>{
    'minTouchTarget': seed.dimensions.minTouchTarget,
    'breakpoints': <String, Object?>{
      for (final MapEntry<String, int> breakpoint
          in seed.dimensions.breakpoints.entries)
        breakpoint.key: breakpoint.value,
    },
  },
  'sounds': <String, Object?>{
    'enabled': seed.sounds.enabled,
    'events': <String, Object?>{
      for (final MapEntry<String, String> event in seed.sounds.events.entries)
        event.key: event.value,
    },
  },
  'monetization': <String, Object?>{
    'ads': <String, Object?>{
      'type': seed.monetization.ads.type,
      'enabled': seed.monetization.ads.enabled,
      'theme': <String, Object?>{
        'buttonBackground': seed.monetization.ads.theme.buttonBackground,
        'buttonForeground': seed.monetization.ads.theme.buttonForeground,
        'copyKey': seed.monetization.ads.theme.copyKey,
      },
    },
    'catalog': <String, Object?>{
      'productIds': <String, Object?>{
        for (final MapEntry<String, String> product
            in seed.monetization.catalog.productIds.entries)
          product.key: product.value,
      },
      'priceCopyKeys': <String, Object?>{
        for (final MapEntry<String, String> copy
            in seed.monetization.catalog.priceCopyKeys.entries)
          copy.key: copy.value,
      },
    },
  },
  'publishing': <String, Object?>{
    'channel': seed.publishing.channel,
    'baseUrl': seed.publishing.baseUrl,
    'publicKey': seed.publishing.publicKey,
  },
};

/// Resultado de una validación o aplicación del Studio.
class StudioApplyResult {
  const StudioApplyResult({required this.issues, required this.written});

  final List<ValidationIssue> issues;
  final List<String> written;

  bool get ok => issues.isEmpty;
}

/// Serializa, valida y —solo si es válido y [write]— escribe [document].
///
/// [designPath] se resuelve dentro de [projectRoot] cuando es relativo, igual
/// que `compileDesign`; los assets se buscan junto al archivo de diseño.
/// `write: false` ejecuta únicamente la barrera de validación: no crea ni
/// modifica archivos.
StudioApplyResult applyStudioDocument(
  DesignSeed document, {
  required Directory projectRoot,
  String designPath = defaultDesignPath,
  bool write = true,
  bool formatOutput = true,
}) {
  final Map<String, Object?> json = studioSeedToJson(document);
  final File file = _designFile(projectRoot, designPath);
  final Directory assetsRoot = Directory(
    _join(file.parent.path, <String>['assets']),
  );

  final List<ValidationIssue> issues = validateJson(
    json,
    projectRoot: projectRoot,
    assetsRoot: assetsRoot,
  );
  if (issues.isNotEmpty) {
    return StudioApplyResult(issues: issues, written: const <String>[]);
  }
  if (!write) {
    return const StudioApplyResult(
      issues: <ValidationIssue>[],
      written: <String>[],
    );
  }

  file.parent.createSync(recursive: true);
  final String encoded = jsonEncode(json).replaceAll('\r\n', '\n');
  file.writeAsStringSync('$encoded\n');

  final CompileReport report = compileDesign(
    projectRoot: projectRoot,
    designFile: file,
    formatOutput: formatOutput,
  );
  return StudioApplyResult(issues: report.issues, written: report.written);
}

File _designFile(Directory projectRoot, String designPath) {
  final File direct = File(designPath);
  if (direct.isAbsolute) return direct;
  return File(_join(projectRoot.path, designPath.split(RegExp(r'[\\/]'))));
}

String _join(String root, List<String> parts) =>
    <String>[root, ...parts].join(Platform.pathSeparator);
