import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';

import '../../../tool/design/schema.dart';
import '../../../tool/design/validate.dart';

void main() {
  final File seedFile = File('design/app.design.json');
  final Directory repositoryAssets = Directory(
    'design${Platform.pathSeparator}assets',
  );

  Map<String, Object?> seed() =>
      jsonDecode(seedFile.readAsStringSync()) as Map<String, Object?>;

  List<ValidationIssue> validate(
    Map<String, Object?> json, {
    Directory? assets,
  }) => validateJson(
    json,
    projectRoot: Directory.current,
    assetsRoot: assets ?? repositoryAssets,
  );

  Map<String, Object?> skinAt(Map<String, Object?> json, int index) =>
      (json['skins']! as List<Object?>)[index] as Map<String, Object?>;

  Map<String, Object?> tokenAt(Map<String, Object?> json, int index) =>
      skinAt(json, index)['tokens']! as Map<String, Object?>;

  Map<String, Object?> mapAt(Map<String, Object?> json, String key) =>
      json[key]! as Map<String, Object?>;

  List<Object?> listAt(Map<String, Object?> json, String key) =>
      json[key]! as List<Object?>;

  Map<String, Object?> elementAt(
    Map<String, Object?> json,
    String key,
    int i,
  ) => listAt(json, key)[i] as Map<String, Object?>;

  test('la semilla es válida y tiene 16 tokens por skin', () {
    final Map<String, Object?> json = seed();
    expect(validate(json), isEmpty);
    expect(tokenAt(json, 0), hasLength(16));
    expect(tokenAt(json, 1), hasLength(16));
  });

  test('rechaza contraste por debajo de 4.5:1', () {
    final Map<String, Object?> json = seed();
    tokenAt(json, 0)['segmentOn'] = '#1E1B12';
    expect(
      validate(json),
      contains(
        isA<ValidationIssue>().having(
          (ValidationIssue issue) => issue.path,
          'path',
          startsWith('skins[0].tokens'),
        ),
      ),
    );
    expect(
      validate(json).map((ValidationIssue issue) => issue.message),
      contains(contains('4.5')),
    );
  });

  test('rechaza keyMinHeight de 44 dp', () {
    final Map<String, Object?> json = seed();
    tokenAt(json, 0)['keyMinHeight'] = 44;
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('skins[0].tokens.keyMinHeight'),
    );
  });

  test('rechaza un nodo fuera de la whitelist', () {
    final Map<String, Object?> json = seed();
    final Map<String, Object?> node =
        (listAt(
              mapAt(json, 'screens')['normal']! as Map<String, Object?>,
              'mobile',
            )[0]
            as Map<String, Object?>);
    node['type'] = 'marquee';
    expect(
      validate(json),
      contains(
        isA<ValidationIssue>().having(
          (ValidationIssue issue) => issue.path,
          'path',
          equals('screens.normal.mobile[0]'),
        ),
      ),
    );
  });

  test('rechaza una clave ARB ausente en los cinco ARB', () {
    final Map<String, Object?> json = seed();
    skinAt(json, 0)['nameKey'] = 'claveQueNoExiste';
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('skins[0].nameKey'),
    );
  });

  test('rechaza ads.type distinto de rewarded', () {
    final Map<String, Object?> json = seed();
    (json['monetization']! as Map<String, Object?>)['ads'] = <String, Object?>{
      ...mapAt(json, 'monetization')['ads']! as Map<String, Object?>,
      'type': 'banner',
    };
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('monetization.ads.type'),
    );
  });

  test('rechaza una fórmula con sintaxis inválida', () {
    final Map<String, Object?> json = seed();
    final Map<String, Object?> profile = elementAt(json, 'profiles', 2);
    profile['formulas'] = <String, Object?>{'resultado': 'base * ('};
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('profiles[2].formulas.resultado'),
    );
  });

  test('rechaza una imagen referenciada que no existe', () {
    final Map<String, Object?> json = seed();
    final Directory temporary = Directory.systemTemp.createTempSync(
      'retro-design-missing-asset-',
    );
    addTearDown(() => temporary.deleteSync(recursive: true));
    elementAt(json, 'images', 0)['file'] = 'no_existe.png';
    expect(
      validate(
        json,
        assets: temporary,
      ).map((ValidationIssue issue) => issue.path),
      contains('images[0].file'),
    );
  });

  test('exige exactamente una skin default con tokens válidos', () {
    final DesignSeed design = DesignSeed.fromJson(seed());
    final List<SkinSpec> defaults = design.skins
        .where((SkinSpec skin) => skin.isDefault)
        .toList();
    expect(defaults, hasLength(1));
    expect(validateTokens(defaults.single.tokens), isEmpty);

    final Map<String, Object?> json = seed();
    skinAt(json, 1)['isDefault'] = true;
    expect(
      validate(json).map((ValidationIssue issue) => issue.message),
      contains(contains('exactamente una')),
    );
  });

  test('rechaza un capabilityId no reconocido', () {
    final Map<String, Object?> json = seed();
    elementAt(json, 'profiles', 0)['capabilityId'] = 'experimental';
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('profiles[0].capabilityId'),
    );
  });

  test('rechaza un breakpoint desconocido y minTouchTarget distinto de 48', () {
    final Map<String, Object?> json = seed();
    final Map<String, Object?> dimensions = mapAt(json, 'dimensions');
    (dimensions['breakpoints']! as Map<String, Object?>)['watch'] = 0;
    dimensions['minTouchTarget'] = 44;
    final List<String> paths = validate(
      json,
    ).map((ValidationIssue issue) => issue.path).toList();
    expect(paths, contains('dimensions.breakpoints.watch'));
    expect(paths, contains('dimensions.minTouchTarget'));
  });

  test('rechaza intentar declarar entitlements desde el diseño', () {
    final Map<String, Object?> json = seed();
    mapAt(json, 'monetization')['entitlements'] = <String, Object?>{
      'freeForever': true,
    };
    expect(
      validate(json).map((ValidationIssue issue) => issue.path),
      contains('monetization.entitlements'),
    );
  });
}
