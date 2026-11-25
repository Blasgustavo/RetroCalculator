// Modelos tipados de design/app.design.json para el validador y el futuro
// compilador. El catálogo es dato: aquí no se ejecuta ninguna fórmula ni se
// generan widgets. Espejo de `designNodeWhitelist` del adaptador V0.

import 'package:retro_calculator/core/design_system/token_validation.dart'
    show minTouchTarget;

const int designSchemaVersion = 2;
const Set<String> designChannels = <String>{'prod', 'beta'};
const Set<String> designBreakpoints = <String>{'mobile', 'tablet', 'desktop'};

/// Copia del contrato de `tool/design/adapters/fluttercanvas_to_design.dart`.
/// El adaptador no se modifica en V1; si cambia la whitelist, cambia aquí también.
const Set<String> designNodeTypes = <String>{
  'padding',
  'display',
  'errorText',
  'row',
  'column',
  'sizedBox',
  'keyboard',
  'key',
  'image',
  'history',
  'skinSelector',
  'angleChip',
};

/// ADR-0007 / V8 T50: `CapabilityRegistry` aún no existe. V1 comprueba los ids
/// reales que ya hay en `lib/features/calculator/domain/capabilities/`.
const Set<String> knownCapabilityIds = <String>{'basic', 'scientific'};

/// Mismo mínimo que `token_validation.dart`; no se redefine la regla.
const double seedMinTouchTarget = minTouchTarget;

/// Límite de peso para assets locales, sin dependencias nuevas.
const int maxAssetBytes = 2 * 1024 * 1024;

/// Presupuesto del validador de fórmulas (solo parseo, nunca ejecución).
const int maxFormulaSteps = 64;
const int maxFormulaDepth = 32;

class DesignSchemaException implements Exception {
  const DesignSchemaException(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => '$path: $reason';
}

class DesignSeed {
  const DesignSeed({
    required this.schemaVersion,
    required this.version,
    required this.channels,
    required this.skins,
    required this.images,
    required this.screens,
    required this.profiles,
    required this.dimensions,
    required this.sounds,
    required this.monetization,
    required this.publishing,
  });

  final int schemaVersion;
  final int version;
  final List<String> channels;
  final List<SkinSpec> skins;
  final List<ImageSpec> images;
  final Map<String, Map<String, List<DesignNode>>> screens;
  final List<ProfileSpec> profiles;
  final DimensionSpec dimensions;
  final SoundSpec sounds;
  final MonetizationSpec monetization;
  final PublishingSpec publishing;

  factory DesignSeed.fromJson(Object? value) {
    final Map<String, Object?> root = _map(value, 'design');
    return DesignSeed(
      schemaVersion: _int(root['schemaVersion'], 'schemaVersion'),
      version: _int(root['version'], 'version'),
      channels: _stringList(root['channels'], 'channels'),
      skins: _objects(root['skins'], 'skins', SkinSpec.fromJson),
      images: _objects(root['images'], 'images', ImageSpec.fromJson),
      screens: _screens(root['screens'], 'screens'),
      profiles: _objects(root['profiles'], 'profiles', ProfileSpec.fromJson),
      dimensions: DimensionSpec.fromJson(root['dimensions'], 'dimensions'),
      sounds: SoundSpec.fromJson(root['sounds'], 'sounds'),
      monetization: MonetizationSpec.fromJson(
        root['monetization'],
        'monetization',
      ),
      publishing: PublishingSpec.fromJson(root['publishing'], 'publishing'),
    );
  }
}

class SkinSpec {
  const SkinSpec({
    required this.id,
    required this.nameKey,
    required this.isDefault,
    required this.tokens,
    required this.images,
  });

  final String id;
  final String nameKey;
  final bool isDefault;
  final Map<String, Object?> tokens;
  final List<String> images;

  factory SkinSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return SkinSpec(
      id: _string(map['id'], '$path.id'),
      nameKey: _string(map['nameKey'], '$path.nameKey'),
      isDefault: _bool(map['isDefault'], '$path.isDefault'),
      tokens: _map(map['tokens'], '$path.tokens'),
      images: _stringList(map['images'], '$path.images'),
    );
  }
}

class ImageSpec {
  const ImageSpec({
    required this.id,
    required this.file,
    required this.format,
    required this.maxWidth,
    required this.maxHeight,
    required this.checksum,
  });

  final String id;
  final String file;
  final String format;
  final int maxWidth;
  final int maxHeight;
  final String checksum;

  factory ImageSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return ImageSpec(
      id: _string(map['id'], '$path.id'),
      file: _string(map['file'], '$path.file'),
      format: _string(map['format'], '$path.format'),
      maxWidth: _int(map['maxWidth'], '$path.maxWidth'),
      maxHeight: _int(map['maxHeight'], '$path.maxHeight'),
      checksum: _string(map['checksum'], '$path.checksum'),
    );
  }
}

class DesignNode {
  const DesignNode({
    required this.type,
    this.key,
    this.titleKey,
    this.when,
    this.value,
    this.height,
    this.alignment,
    this.child,
    this.children,
  });

  final String type;
  final String? key;
  final String? titleKey;
  final String? when;
  final num? value;
  final num? height;
  final String? alignment;
  final DesignNode? child;
  final List<DesignNode>? children;

  factory DesignNode.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return DesignNode(
      type: _string(map['type'], '$path.type'),
      key: map.containsKey('key') ? _string(map['key'], '$path.key') : null,
      titleKey: map.containsKey('titleKey')
          ? _string(map['titleKey'], '$path.titleKey')
          : null,
      when: map.containsKey('when') ? _string(map['when'], '$path.when') : null,
      value: map.containsKey('value')
          ? _num(map['value'], '$path.value')
          : null,
      height: map.containsKey('height')
          ? _num(map['height'], '$path.height')
          : null,
      alignment: map.containsKey('alignment')
          ? _string(map['alignment'], '$path.alignment')
          : null,
      child: map.containsKey('child')
          ? DesignNode.fromJson(map['child'], '$path.child')
          : null,
      children: map.containsKey('children')
          ? _list(map['children'], '$path.children')
                .asMap()
                .entries
                .map(
                  (MapEntry<int, Object?> entry) => DesignNode.fromJson(
                    entry.value,
                    '$path.children[${entry.key}]',
                  ),
                )
                .toList()
          : null,
    );
  }
}

class ProfileSpec {
  const ProfileSpec({
    required this.id,
    required this.labelKey,
    required this.capabilityId,
    required this.isScientific,
    required this.defaultAngleMode,
    required this.decimalDigits,
    required this.inputs,
    required this.formulas,
    required this.keyRows,
  });

  final String id;
  final String labelKey;
  final String capabilityId;
  final bool isScientific;
  final String defaultAngleMode;
  final int decimalDigits;
  final List<String> inputs;
  final Map<String, String> formulas;
  final List<List<String>> keyRows;

  factory ProfileSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    final Map<String, Object?> formulas = _map(
      map['formulas'],
      '$path.formulas',
    );
    final List<Object?> keyRows = _list(map['keyRows'], '$path.keyRows');
    return ProfileSpec(
      id: _string(map['id'], '$path.id'),
      labelKey: _string(map['labelKey'], '$path.labelKey'),
      capabilityId: _string(map['capabilityId'], '$path.capabilityId'),
      isScientific: _bool(map['isScientific'], '$path.isScientific'),
      defaultAngleMode: _string(
        map['defaultAngleMode'],
        '$path.defaultAngleMode',
      ),
      decimalDigits: _int(map['decimalDigits'], '$path.decimalDigits'),
      inputs: _stringList(map['inputs'], '$path.inputs'),
      formulas: formulas.map(
        (String key, Object? formula) => MapEntry<String, String>(
          key,
          _string(formula, '$path.formulas.$key'),
        ),
      ),
      keyRows: keyRows.asMap().entries.map((MapEntry<int, Object?> row) {
        return _stringList(row.value, '$path.keyRows[${row.key}]');
      }).toList(),
    );
  }
}

class DimensionSpec {
  const DimensionSpec({
    required this.minTouchTarget,
    required this.breakpoints,
  });

  final int minTouchTarget;
  final Map<String, int> breakpoints;

  factory DimensionSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    final Map<String, Object?> breakpoints = _map(
      map['breakpoints'],
      '$path.breakpoints',
    );
    return DimensionSpec(
      minTouchTarget: _int(map['minTouchTarget'], '$path.minTouchTarget'),
      breakpoints: breakpoints.map(
        (String key, Object? minWidth) => MapEntry<String, int>(
          key,
          _int(minWidth, '$path.breakpoints.$key'),
        ),
      ),
    );
  }
}

class SoundSpec {
  const SoundSpec({required this.enabled, required this.events});

  final bool enabled;
  final Map<String, String> events;

  factory SoundSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    final Map<String, Object?> events = _map(map['events'], '$path.events');
    return SoundSpec(
      enabled: _bool(map['enabled'], '$path.enabled'),
      events: events.map(
        (String key, Object? file) =>
            MapEntry<String, String>(key, _string(file, '$path.events.$key')),
      ),
    );
  }
}

class MonetizationSpec {
  const MonetizationSpec({required this.ads, required this.catalog});

  final AdSpec ads;
  final CatalogSpec catalog;

  factory MonetizationSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return MonetizationSpec(
      ads: AdSpec.fromJson(map['ads'], '$path.ads'),
      catalog: CatalogSpec.fromJson(map['catalog'], '$path.catalog'),
    );
  }
}

class AdSpec {
  const AdSpec({
    required this.type,
    required this.enabled,
    required this.theme,
  });

  final String type;
  final bool enabled;
  final AdThemeSpec theme;

  factory AdSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return AdSpec(
      type: _string(map['type'], '$path.type'),
      enabled: _bool(map['enabled'], '$path.enabled'),
      theme: AdThemeSpec.fromJson(map['theme'], '$path.theme'),
    );
  }
}

class AdThemeSpec {
  const AdThemeSpec({
    required this.buttonBackground,
    required this.buttonForeground,
    required this.copyKey,
  });

  final String buttonBackground;
  final String buttonForeground;
  final String copyKey;

  factory AdThemeSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return AdThemeSpec(
      buttonBackground: _string(
        map['buttonBackground'],
        '$path.buttonBackground',
      ),
      buttonForeground: _string(
        map['buttonForeground'],
        '$path.buttonForeground',
      ),
      copyKey: _string(map['copyKey'], '$path.copyKey'),
    );
  }
}

class CatalogSpec {
  const CatalogSpec({required this.productIds, required this.priceCopyKeys});

  final Map<String, String> productIds;
  final Map<String, String> priceCopyKeys;

  factory CatalogSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return CatalogSpec(
      productIds: _stringMap(map['productIds'], '$path.productIds'),
      priceCopyKeys: _stringMap(map['priceCopyKeys'], '$path.priceCopyKeys'),
    );
  }
}

class PublishingSpec {
  const PublishingSpec({
    required this.channel,
    required this.baseUrl,
    required this.publicKey,
  });

  final String channel;
  final String baseUrl;
  final String publicKey;

  factory PublishingSpec.fromJson(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    return PublishingSpec(
      channel: _string(map['channel'], '$path.channel'),
      baseUrl: _string(map['baseUrl'], '$path.baseUrl'),
      publicKey: _string(map['publicKey'], '$path.publicKey'),
    );
  }
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw DesignSchemaException(path, 'debe ser un objeto JSON');
  }
  return value;
}

List<Object?> _list(Object? value, String path) {
  if (value is! List<Object?>) {
    throw DesignSchemaException(path, 'debe ser una lista JSON');
  }
  return value;
}

String _string(Object? value, String path) {
  if (value is! String) {
    throw DesignSchemaException(path, 'debe ser una cadena');
  }
  return value;
}

bool _bool(Object? value, String path) {
  if (value is! bool) {
    throw DesignSchemaException(path, 'debe ser booleano');
  }
  return value;
}

int _int(Object? value, String path) {
  if (value is int) return value;
  if (value is double && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw DesignSchemaException(path, 'debe ser un entero');
}

num _num(Object? value, String path) {
  if (value is num) return value;
  throw DesignSchemaException(path, 'debe ser numérico');
}

List<String> _stringList(Object? value, String path) => _list(value, path)
    .asMap()
    .entries
    .map(
      (MapEntry<int, Object?> entry) =>
          _string(entry.value, '$path[${entry.key}]'),
    )
    .toList();

Map<String, String> _stringMap(Object? value, String path) =>
    _map(value, path).map(
      (String key, Object? item) =>
          MapEntry<String, String>(key, _string(item, '$path.$key')),
    );

List<T> _objects<T>(
  Object? value,
  String path,
  T Function(Object?, String) factory,
) => _list(value, path)
    .asMap()
    .entries
    .map(
      (MapEntry<int, Object?> entry) =>
          factory(entry.value, '$path[${entry.key}]'),
    )
    .toList();

Map<String, Map<String, List<DesignNode>>> _screens(
  Object? value,
  String path,
) {
  final Map<String, Object?> screens = _map(value, path);
  return screens.map((String screen, Object? breakpoints) {
    return MapEntry<String, Map<String, List<DesignNode>>>(
      screen,
      _map(breakpoints, '$path.$screen').map((
        String breakpoint,
        Object? nodes,
      ) {
        return MapEntry<String, List<DesignNode>>(
          breakpoint,
          _objects(nodes, '$path.$screen.$breakpoint', DesignNode.fromJson),
        );
      }),
    );
  });
}
