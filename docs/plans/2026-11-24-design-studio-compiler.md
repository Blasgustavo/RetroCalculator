> **Plan v1 histórico, superado por [`2026-11-24-design-studio-v2.md`](./2026-11-24-design-studio-v2.md).** No implementar tal cual: añade editor visual, fórmulas, imágenes, publicación remota y monetización visual.

# RetroDesign Studio (editor de skin + compiler + puente local) — Plan de implementación

## Contexto

El proyecto tiene una arquitectura sólida (Clean + MVVM, motor Dart puro, skins cosméticas generadas en build-time) pero **no tiene herramienta de diseño ni artefacto de diseño**. Hoy las pantallas se escriben a mano en `lib/core/widgets/` y `lib/features/calculator/presentation/`, y la única definición visual es `tool/skins/definitions/lcd_classica.yaml`, escrita a mano. No hay capturas versionadas ni export desde una herramienta.

El usuario pidió crear la herramienta para automatizar el proceso, con alcance **tokens + layout**, y eligió como primer entregable **compiler + preview** (no un editor drag-and-drop completo). Después precisó el objetivo real: **editar la skin en la herramienta y cargarla en la app desde ahí**, y eligió el modo **editor de tokens + puente local de desarrollo**, de forma que el cambio se vea sin recompilar. La decisión del editor se documenta aquí; las dos decisiones que sí resultaron load-bearing se registraron en ADR-0007 y ADR-0008.

El usuario amplió después el editor para que también **cree calculadoras con lógica nueva**, **ajuste dimensiones visuales** y **configure sonidos**. Las dos primeras implican tocar el motor y añadir una dependencia, por lo que se registraron antes de planear: ADR-0007 (perfiles extensibles con registro de capacidades: el editor referencia lógica escrita en Dart, nunca la ejecuta desde el JSON) y ADR-0008 (sonidos locales con `audioplayers` aislado en `lib/platform/`).

Referencias: ADR-0004 (generador build-time, emite tokens y manifiesto, nunca código del motor), ADR-0005 (textos por clave ARB), ADR-0007, ADR-0008, `docs/architecture.md`.

### Decisión de diseño de la herramienta

**Generar datos de layout, no código de widgets.** La herramienta produce un `ScreenSpec` tipado (árbol de nodos) y un renderizador en la app lo convierte en widgets. No se genera código Dart de widgets: eso haría que cualquier edición manual se perdiera en el próximo build y volvería frágiles los tests de widget.

| Criterio | Generar widgets Dart | Generar datos de layout (elegido) |
|---|---|---|
| Diff revisable | Código repetitivo y ruidoso | JSON de diseño + artefactos pequeños |
| Edición manual | Se sobrescribe | Imposible por diseño |
| Tests | Frágiles | Golden tests por `ScreenSpec` |
| Seguridad | Código arbitrario en el repo | Whitelist de nodos, sin `eval` |
| Idempotencia en CI | Ruidosa | `compile.dart` + `git diff --exit-code` |

## Alcance

**Incluye**

- `design/app.design.json` como fuente de verdad: tokens de skin, pantallas (`normal`, `scientific`, `selector`) y breakpoints (`mobile`, `tablet`, `desktop`).
- Esquema Dart, validador y compiler determinista.
- El compiler reutiliza el generador existente (`tool/skins/generate.dart`) para tokens y manifiesto; añade `design_tokens.dart` y `screens.g.dart`.
- Renderizador genérico de specs y migración de las tres pantallas existentes sin cambiar su apariencia ni sus keys de test.
- Preview local mediante un entrypoint de Windows (herramienta de desarrollo, **no** una quinta plataforma de producto).
- Panel de edición de los 16 tokens dentro del preview: valida antes de escribir, actualiza `design/app.design.json` y ejecuta el compiler desde la propia herramienta.
- Puente local de desarrollo: un servidor `localhost` sirve el manifiesto validado y un `DevSkinBridge` aplica los tokens en la app sin recompilar, solo en `kDebugMode`.
- Bloque `profiles[]` editable: el editor crea calculadoras nuevas referenciando capacidades registradas (ADR-0007); puede generar el esqueleto de una capacidad, nunca su lógica.
- Sección de dimensiones visuales en el editor: tokens de shell y breakpoints, con el mínimo táctil de 48 dp innegociable.
- Bloque `sounds` editable: eventos locales con `audioplayers` aislado en `lib/platform/audio/` (ADR-0008).
- Golden tests y job de CI que exige que el compiler no produzca diff.

**Excluye**

- Editor visual drag-and-drop de nodos/layout (fase posterior sobre el mismo esquema). El editor de esta fase edita **tokens**, no la estructura de pantallas.
- Publicación a catálogo remoto: el manifiesto sigue llevando solo tokens y se sirve únicamente desde `localhost` en esta fase (ADR-0004).
- Catálogo remoto de layouts: un manifiesto descargado nunca cambia la estructura de la app.
- Fuentestipográficas, imágenes, nuevos colores o cambios visuales: el diseño semilla reproduce exactamente el estado actual.
- IAP, ads, entitlements, backend, Windows/iOS de producto. El editor no crea precios ni reglas de monetización (ADR-0003 y ADR-0006).
- Escritura de lógica de cálculo desde el editor: el humano implementa el capability en Dart (ADR-0007).
- Sonidos remotos o descargados del catálogo (ADR-0008).
- Reducción del tamaño del APK: es configuración de build, no competencia del editor.

## Arquitectura y archivos exactos

```text
design/app.design.json                         ← fuente de verdad (nuevo)
tool/design/schema.dart                        ← tipos + fromJson (nuevo)
tool/design/validate.dart                      ← validación de diseño (nuevo)
tool/design/compile.dart                       ← compiler (nuevo)
tool/skins/generate.dart                       ← se refactoriza para iterar todos los YAML
tool/skins/definitions/lcd_classica.yaml       ← generado por el compiler (contenido idéntico)
lib/core/design_system/generated/design_tokens.dart   ← generado (nuevo)
lib/features/skins/data/generated/screens.g.dart      ← generado (nuevo)
lib/core/widgets/layout_spec.dart              ← tipos const del spec (nuevo, escrito a mano)
lib/core/widgets/spec_renderer.dart            ← renderizador (nuevo, escrito a mano)
lib/features/calculator/presentation/calculator_page.dart ← migrado al renderer
lib/tool_preview_main.dart                    ← entrypoint del preview + editor (nuevo)
lib/core/widgets/token_editor.dart             ← panel de edición de los 16 tokens (nuevo)
lib/core/design_system/skin_tokens.dart        ← añade SkinTokens.fromMap
lib/features/skins/presentation/skin_scope.dart ← añade tokensOverride para el puente
lib/platform/dev_skin/dev_skin_bridge.dart     ← inyección debug de tokens remotos (nuevo)
lib/platform/dev_skin/dev_skin_client.dart     ← HttpClient a localhost (nuevo)
lib/app.dart                                   ← cablea el puente solo en debug
tool/design/serve.dart                         ← servidor local del manifiesto (nuevo)
test/unit/design/design_file_test.dart         ← nuevo
test/unit/design/validate_test.dart            ← nuevo
test/unit/design/compile_test.dart             ← nuevo
test/unit/design/spec_renderer_test.dart       ← nuevo
test/unit/design/dev_skin_test.dart            ← nuevo
lib/features/calculator/domain/capabilities/capability_registry.dart ← registro de capacidades (nuevo)
lib/features/calculator/domain/profiles/calculator_profile.dart     ← id String + flag isScientific
lib/features/calculator/domain/profiles/profiles.dart               ← migrado al registro
lib/features/calculator/presentation/viewmodels/calculator_view_model.dart ← adaptado al id String
lib/features/skins/data/generated/profiles.g.dart                  ← generado (nuevo)
tool/design/new_capability.dart               ← genera esqueleto + test rojo (nuevo)
lib/platform/audio/sound_player.dart          ← interfaz cosmética (nuevo)
lib/platform/audio/audioplayers_sound_player.dart ← adaptador del plugin (nuevo)
lib/app.dart                                   ← también cablea SoundPlayer
tool/sounds/generate.dart                      ← WAV deterministas (nuevo)
assets/sounds/*.wav                            ← generados y versionados
test/unit/calculator/capability_registry_test.dart ← nuevo
test/unit/audio/sound_player_test.dart         ← nuevo
test/unit/design/profiles_test.dart            ← nuevo
test/golden/design_preview_test.dart           ← nuevo
test/golden/goldens/*.png                      ← capturas versionadas
.github/workflows/android-ci.yml               ← job de generación
docs/design/README.md                          ← contrato de la herramienta
```

Dependencias: **una nueva**, `audioplayers` (ADR-0008), aislada en `lib/platform/audio/`. Todo lo demás usa lo que ya hay: `dart:convert`, `dart:io` (`HttpClient` y `HttpServer`, sin paquete `http`), `package:yaml` (ya en `dev_dependencies`), `package:crypto` (ya en `dependencies`), `kDebugMode` de `package:flutter/foundation.dart` y `validateTokens` de `lib/core/design_system/token_validation.dart`. Tras `flutter pub get` hay que restaurar `windows/flutter/` mientras la fase activa sea Android.

## Contrato de `design/app.design.json`

### Nodos permitidos (whitelist)

| `type` | Se renderiza como | Propiedades |
|---|---|---|
| `display` | `SevenSegmentDisplay` | `key` |
| `keyboard` | `CalculatorKeyboard` | usa `rows`/`labels` del `SpecRenderData` |
| `errorText` | `Text(errorLabel(...))` | `when: hasError` |
| `angleChip` | `ChoiceChip` DEG/RAD | `key`, `when: isScientific` |
| `history` | `ExpansionTile` + `HistoryPanel` | `titleKey` |
| `skinSelector` | `SkinSelector` | — |
| `modeToggle` | `IconButton` del AppBar | `key`, `tooltipKey` |
| `column` / `row` | `Column` / `Row` | `children`, `alignment` (solo `row`) |
| `padding` | `Padding` | `padding` (dp), `axis`: `all`/`horizontal`/`vertical`, `children` |
| `sizedBox` | `SizedBox` | `height`, `children` |

Condiciones permitidas en `when`: `always`, `isScientific`, `hasError`.
Alineaciones permitidas en `row`: `center`, `start`, `end`, `spaceBetween`.

Un breakpoint puede declarar `{"extends": "mobile"}`; el compiler expande la copia antes de generar el Dart, para que el JSON semilla sea corto y el artefacto generado sea explícito.

### Semilla (contenido inicial de `design/app.design.json`)

Los tokens son los actuales de `lcd_classica`; el layout es una transcripción exacta del `Column` de `calculator_page.dart`. El checksum resultante debe seguir siendo `26d270cf605e455cbbe2f970d915dfefcd18bae6e9dc7b089220e97669bc77aa`.

```json
{
  "schemaVersion": 1,
  "version": 1,
  "skins": [
    {
      "id": "lcd_classica",
      "nameKey": "skinLcdClassicaName",
      "version": 1,
      "rewardDurationHours": 24,
      "source": "compiled",
      "capabilities": [],
      "tokens": {
        "segmentOn": "#B8E986",
        "displayBackground": "#1E2A1F",
        "displayBorder": "#3A3320",
        "displayRadius": 8,
        "displayPaddingHorizontal": 16,
        "displayPaddingVertical": 12,
        "digitWidth": 26,
        "digitHeight": 48,
        "keyBackground": "#E8F0D6",
        "keyForeground": "#1E2A1F",
        "keyBorder": "#4F6F52",
        "keyRadius": 6,
        "keyPadding": 3,
        "keyMinHeight": 48,
        "screenPadding": 12,
        "keyboardHeight": 380
      }
    }
  ],
  "screens": {
    "normal": {
      "appBar": {
        "titleKey": "calculatorTitle",
        "actions": [
          {"type": "modeToggle", "key": "calc.toggle.mode", "tooltipKey": "modeToggleLabel"}
        ]
      },
      "breakpoints": {
        "mobile": {
          "nodes": [
            {"type": "padding", "padding": 12, "children": [
              {"type": "display", "key": "calc.display"}
            ]},
            {"type": "errorText", "when": "hasError"},
            {"type": "padding", "padding": 12, "axis": "horizontal", "when": "isScientific", "children": [
              {"type": "row", "alignment": "center", "children": [
                {"type": "angleChip", "key": "calc.toggle.angle"}
              ]}
            ]},
            {"type": "sizedBox", "height": 380, "children": [
              {"type": "padding", "padding": 12, "children": [
                {"type": "keyboard"}
              ]}
            ]},
            {"type": "history", "titleKey": "historyTitle"},
            {"type": "skinSelector"}
          ]
        },
        "tablet": {"extends": "mobile"},
        "desktop": {"extends": "mobile"}
      }
    },
    "scientific": {
      "appBar": {
        "titleKey": "calculatorTitle",
        "actions": [
          {"type": "modeToggle", "key": "calc.toggle.mode", "tooltipKey": "modeToggleLabel"}
        ]
      },
      "breakpoints": {
        "mobile": {
          "nodes": [
            {"type": "padding", "padding": 12, "children": [
              {"type": "display", "key": "calc.display"}
            ]},
            {"type": "errorText", "when": "hasError"},
            {"type": "padding", "padding": 12, "axis": "horizontal", "children": [
              {"type": "row", "alignment": "center", "children": [
                {"type": "angleChip", "key": "calc.toggle.angle"}
              ]}
            ]},
            {"type": "sizedBox", "height": 380, "children": [
              {"type": "padding", "padding": 12, "children": [
                {"type": "keyboard"}
              ]}
            ]},
            {"type": "history", "titleKey": "historyTitle"},
            {"type": "skinSelector"}
          ]
        },
        "tablet": {"extends": "mobile"},
        "desktop": {"extends": "mobile"}
      }
    },
    "selector": {
      "appBar": {"titleKey": "skinSelectorTitle", "actions": []},
      "breakpoints": {
        "mobile": {"nodes": [{"type": "skinSelector"}]},
        "tablet": {"extends": "mobile"},
        "desktop": {"extends": "mobile"}
      }
    }
  }
}
```

## Tareas (2–5 min cada una)

### S1 — Semilla y esquema

- [ ] **T1 — Test rojo: el archivo de diseño existe y versiona**
  Archivo: `test/unit/design/design_file_test.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    test('design/app.design.json usa schemaVersion 1', () {
      final Map<String, Object?> json =
          jsonDecode(File('design/app.design.json').readAsStringSync())
              as Map<String, Object?>;
      expect(json['schemaVersion'], 1);
      expect(json['version'], 1);
    });
  }
  ```
  Verificar: `flutter test test/unit/design/design_file_test.dart` → rojo (archivo no existe).

- [ ] **T2 — Crear el archivo semilla**
  Archivo: `design/app.design.json`
  Copiar el JSON de la sección anterior literalmente. Sin comentarios (JSON estricto), LF canónico.
  Verificar: `flutter test test/unit/design/design_file_test.dart` → verde.

- [ ] **T3 — Tipos del esquema**
  Archivo: `tool/design/schema.dart`
  ```dart
  import 'dart:convert';

  const int kDesignSchemaVersion = 1;
  const Set<String> kNodeTypes = <String>{
    'display', 'keyboard', 'errorText', 'angleChip', 'history',
    'skinSelector', 'modeToggle', 'column', 'row', 'padding', 'sizedBox',
  };
  const Set<String> kWhenValues = <String>{'always', 'isScientific', 'hasError'};
  const Set<String> kPaddingAxes = <String>{'all', 'horizontal', 'vertical'};
  const Set<String> kRowAlignments = <String>{'center', 'start', 'end', 'spaceBetween'};
  const List<String> kBreakpoints = <String>['mobile', 'tablet', 'desktop'];
  const List<String> kScreens = <String>['normal', 'scientific', 'selector'];

  class DesignNode {
    const DesignNode({
      required this.type,
      this.key,
      this.when = 'always',
      this.padding,
      this.axis = 'all',
      this.height,
      this.alignment = 'start',
      this.titleKey,
      this.tooltipKey,
      this.children = const <DesignNode>[],
    });

    final String type;
    final String? key;
    final String when;
    final double? padding;
    final String axis;
    final double? height;
    final String alignment;
    final String? titleKey;
    final String? tooltipKey;
    final List<DesignNode> children;

    factory DesignNode.fromJson(Map<String, Object?> json) => DesignNode(
          type: json['type']! as String,
          key: json['key'] as String?,
          when: (json['when'] as String?) ?? 'always',
          padding: (json['padding'] as num?)?.toDouble(),
          axis: (json['axis'] as String?) ?? 'all',
          height: (json['height'] as num?)?.toDouble(),
          alignment: (json['alignment'] as String?) ?? 'start',
          titleKey: json['titleKey'] as String?,
          tooltipKey: json['tooltipKey'] as String?,
          children: (json['children'] as List<Object?>? ?? const <Object?>[])
              .map((Object? item) =>
                  DesignNode.fromJson(item! as Map<String, Object?>))
              .toList(),
        );
  }

  class AppBarSpec {
    const AppBarSpec({required this.titleKey, this.actions = const <DesignNode>[]});
    final String titleKey;
    final List<DesignNode> actions;
    factory AppBarSpec.fromJson(Map<String, Object?> json) => AppBarSpec(
          titleKey: json['titleKey']! as String,
          actions: (json['actions'] as List<Object?>? ?? const <Object?>[])
              .map((Object? item) =>
                  DesignNode.fromJson(item! as Map<String, Object?>))
              .toList(),
        );
  }

  class LayoutSpec {
    const LayoutSpec({required this.nodes});
    final List<DesignNode> nodes;
  }

  class ScreenSpecFile {
    const ScreenSpecFile({
      required this.appBar,
      required this.breakpoints,
    });
    final AppBarSpec appBar;
    final Map<String, LayoutSpec> breakpoints;
  }

  class SkinSpec {
    const SkinSpec({required this.id, required this.values});
    final String id;
    final Map<String, Object?> values;
  }

  class DesignFile {
    DesignFile({required this.version, required this.skins, required this.screens});

    final int version;
    final List<SkinSpec> skins;
    final Map<String, ScreenSpecFile> screens;

    factory DesignFile.fromJson(Map<String, Object?> json) {
      final Map<String, Object?> rawScreens = json['screens']! as Map<String, Object?>;
      final Map<String, ScreenSpecFile> screens = <String, ScreenSpecFile>{};
      for (final String name in kScreens) {
        final Map<String, Object?> rawScreen = rawScreens[name]! as Map<String, Object?>;
        final Map<String, Object?> rawBreakpoints =
            rawScreen['breakpoints']! as Map<String, Object?>;
        final Map<String, Object?> mobile =
            rawBreakpoints['mobile']! as Map<String, Object?>;
        final Map<String, LayoutSpec> breakpoints = <String, LayoutSpec>{};
        for (final String bp in kBreakpoints) {
          final Map<String, Object?> raw =
              (rawBreakpoints[bp]? as Map<String, Object?>?) ?? mobile;
          final Map<String, Object?> source =
              raw['extends'] == null ? raw : mobile;
          breakpoints[bp] = LayoutSpec(
            nodes: (source['nodes'] as List<Object?>)
                .map((Object? item) =>
                    DesignNode.fromJson(item! as Map<String, Object?>))
                .toList(),
          );
        }
        screens[name] = ScreenSpecFile(
          appBar: AppBarSpec.fromJson(rawScreen['appBar']! as Map<String, Object?>),
          breakpoints: breakpoints,
        );
      }
      return DesignFile(
        version: (json['version'] as num).toInt(),
        skins: (json['skins'] as List<Object?>)
            .map((Object? item) {
              final Map<String, Object?> raw = item! as Map<String, Object?>;
              return SkinSpec(
                id: raw['id']! as String,
                values: <String, Object?>{
                  'id': raw['id'],
                  'nameKey': raw['nameKey'],
                  'version': raw['version'],
                  'rewardDurationHours': raw['rewardDurationHours'],
                  'source': raw['source'],
                  'capabilities': raw['capabilities'],
                  ...(raw['tokens']! as Map<String, Object?>),
                },
              );
            })
            .toList(),
        screens: screens,
      );
    }
  }
  ```
  Verificar: `dart analyze tool/design && dart format --output=none --set-exit-if-changed tool/design`.

- [ ] **T4 — Test del esquema contra la semilla**
  Archivo: `test/unit/design/design_file_test.dart` (ampliar)
  ```dart
  import '../../../tool/design/schema.dart';

  test('la semilla tiene 16 tokens, 3 pantallas y 3 breakpoints', () {
    final DesignFile file = DesignFile.fromJson(
      jsonDecode(File('design/app.design.json').readAsStringSync())
          as Map<String, Object?>,
    );
    expect(file.skins, hasLength(1));
    expect(file.skins.single.values['keyMinHeight'], 48);
    expect(file.screens.keys.toSet(), kScreens);
    for (final ScreenSpecFile screen in file.screens.values) {
      expect(screen.breakpoints.keys.toSet(), kBreakpoints);
      expect(screen.breakpoints['mobile']!.nodes, isNotEmpty);
    }
  });
  ```
  Verificar: `flutter test test/unit/design/design_file_test.dart` → 2/2.

### S2 — Validador

- [ ] **T5 — Test rojo: contraste por debajo de 4.5:1**
  Archivo: `test/unit/design/validate_test.dart`
  ```dart
  test('rechaza segmento/display con contraste menor a 4.5:1', () {
    final DesignFile file = _fileWithToken('segmentOn', '#1E2A1F');
    expect(validate(file, _arbKeys()), contains(contains('4.5:1')));
  });
  ```
  Verificar: `flutter test test/unit/design/validate_test.dart` → rojo.

- [ ] **T6 — Test rojo: tecla por debajo de 48 dp**
  ```dart
  test('rechaza keyMinHeight 44', () {
    expect(validate(_fileWithToken('keyMinHeight', 44), _arbKeys()),
        contains(contains('48 dp')));
  });
  ```

- [ ] **T7 — Test rojo: nodo desconocido**
  ```dart
  test('rechaza un tipo de nodo fuera de la whitelist', () {
    expect(validate(_fileWithNodeType('quantumDisplay'), _arbKeys()),
        contains(contains('nodo desconocido')));
  });
  ```

- [ ] **T8 — Test rojo: clave ARB inexistente**
  ```dart
  test('rechaza titleKey que no existe en app_en.arb', () {
    expect(validate(_fileWithTitleKey('noExiste'), _arbKeys()),
        contains(contains('ARB')));
  });
  ```

  Los helpers de los cuatro tests se definen una sola vez en ese archivo, partiendo siempre de la semilla sin mutarla:

  ```dart
  Map<String, Object?> _seed() =>
      jsonDecode(File('design/app.design.json').readAsStringSync())
          as Map<String, Object?>;

  DesignFile _fileWithToken(String key, Object value) {
    final Map<String, Object?> json = _seed();
    final Map<String, Object?> skin =
        (json['skins'] as List<Object?>).first! as Map<String, Object?>;
    (skin['tokens'] as Map<String, Object?>)[key] = value;
    return DesignFile.fromJson(json);
  }

  DesignFile _fileWithNodeType(String type) {
    final Map<String, Object?> json = _seed();
    final Map<String, Object?> screen =
        (json['screens'] as Map<String, Object?>)['normal']! as Map<String, Object?>;
    final Map<String, Object?> mobile =
        (screen['breakpoints'] as Map<String, Object?>)['mobile']! as Map<String, Object?>;
    (mobile['nodes'] as List<Object?>).add(<String, Object?>{'type': type});
    return DesignFile.fromJson(json);
  }

  DesignFile _fileWithTitleKey(String key) {
    final Map<String, Object?> json = _seed();
    final Map<String, Object?> screen =
        (json['screens'] as Map<String, Object?>)['normal']! as Map<String, Object?>;
    (screen['appBar'] as Map<String, Object?>)['titleKey'] = key;
    return DesignFile.fromJson(json);
  }

  Set<String> _arbKeys() => arbKeys();
  ```
  Nota: los mensajes reales de `validateTokens` son «segmento/display por debajo de 4.5:1» y «botón por debajo de 48 dp»; los `contains` de T5 y T6 coinciden con esos textos.

- [ ] **T9 — Implementar el validador**
  Archivo: `tool/design/validate.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  import 'package:retro_calculator/core/design_system/token_validation.dart';

  import 'schema.dart';

  Set<String> arbKeys() =>
      (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, Object?>)
          .keys
          .toSet();

  List<String> validate(DesignFile file, Set<String> keys) {
    final List<String> errors = <String>[];
    if (file.version < 1) errors.add('version debe ser >= 1');

    for (final SkinSpec skin in file.skins) {
      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(skin.id)) {
        errors.add('id de skin inválido: ${skin.id}');
      }
      for (final String error in validateTokens(skin.values)) {
        errors.add('${skin.id}: $error');
      }
    }

    void checkNode(DesignNode node) {
      if (!kNodeTypes.contains(node.type)) {
        errors.add('nodo desconocido: ${node.type}');
      }
      if (!kWhenValues.contains(node.when)) {
        errors.add('when inválido: ${node.when}');
      }
      if (!kPaddingAxes.contains(node.axis)) {
        errors.add('axis inválido: ${node.axis}');
      }
      if (node.type == 'row' && !kRowAlignments.contains(node.alignment)) {
        errors.add('alignment inválido: ${node.alignment}');
      }
      for (final String? key in <String?>[node.titleKey, node.tooltipKey]) {
        if (key != null && !keys.contains(key)) {
          errors.add('clave ARB inexistente: $key');
        }
      }
      for (final DesignNode child in node.children) {
        checkNode(child);
      }
    }

    for (final MapEntry<String, ScreenSpecFile> screen in file.screens.entries) {
      if (!keys.contains(screen.value.appBar.titleKey)) {
        errors.add('clave ARB inexistente: ${screen.value.appBar.titleKey}');
      }
      for (final DesignNode action in screen.value.appBar.actions) {
        checkNode(action);
      }
      for (final LayoutSpec layout in screen.value.breakpoints.values) {
        for (final DesignNode node in layout.nodes) {
          checkNode(node);
        }
      }
    }
    return errors;
  }

  void main(List<String> args) {
    final DesignFile file = DesignFile.fromJson(
      jsonDecode(File('design/app.design.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final List<String> errors = validate(file, arbKeys());
    if (errors.isNotEmpty) {
      stderr.writeln(errors.join('\n'));
      exitCode = 1;
      return;
    }
    stdout.writeln('Diseño válido: ${file.skins.length} skin(s), ${file.screens.length} pantallas');
  }
  ```
  Verificar: `flutter test test/unit/design/validate_test.dart` → 4/4; `dart run tool/design/validate.dart` → `Diseño válido: 1 skin(s), 3 pantallas`.

### S3 — Compiler

- [ ] **T10 — Test rojo: idempotencia del compiler**
  Archivo: `test/unit/design/compile_test.dart`
  ```dart
  test('el compiler no produce diff en la semilla', () {
    final ProcessResult result = Process.runSync(
      'dart', <String>['run', 'tool/design/compile.dart'],
    );
    expect(result.exitCode, 0, reason: result.stderr as String?);
    final ProcessResult diff = Process.runSync('git', <String>[
      'diff', '--exit-code', '--',
      'tool/skins/definitions', 'assets/catalog',
      'lib/core/design_system/generated', 'lib/features/skins/data/generated',
    ]);
    expect(diff.exitCode, 0, reason: diff.stdout as String?);
  });
  ```
  Verificar: `flutter test test/unit/design/compile_test.dart` → rojo.

- [ ] **T11 — Refactor del generador de skins existente**
  Archivo: `tool/skins/generate.dart`
  Cambiar `main()` para iterar `Directory('tool/skins/definitions').listSync(followLinks: false).where((e) => e.path.endsWith('.yaml'))` en vez de la ruta fija. Extraer `_generateFor(String path, String raw)` con el cuerpo actual. El archivo generado se llama `lib/core/design_system/generated/skin_tokens_<id>.dart`; el manifiesto acumula una entrada por YAML con `'definition': path` (ruta real del archivo iterado) y `'definitionYaml': raw`. Con un solo YAML la salida es byte-idéntica a la actual.
  Verificar: `dart run tool/skins/generate.dart && git diff --exit-code -- assets/catalog lib/core/design_system/generated` → sin diff, checksum `26d270cf…` intacto.

- [ ] **T12 — Compiler: YAML canónico desde los tokens del diseño**
  Archivo: `tool/design/compile.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  import 'schema.dart';
  import 'validate.dart';

  Future<void> main(List<String> args) async {
    final DesignFile file = DesignFile.fromJson(
      jsonDecode(File('design/app.design.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final List<String> errors = validate(file, arbKeys());
    if (errors.isNotEmpty) {
      stderr.writeln(errors.join('\n'));
      exitCode = 1;
      return;
    }

    for (final SkinSpec skin in file.skins) {
      File('tool/skins/definitions/${skin.id}.yaml')
          .writeAsStringSync(_yaml(skin), flush: true);
    }

    final ProcessResult generated = await Process.run(
      'dart', <String>['run', 'tool/skins/generate.dart'],
    );
    if (generated.exitCode != 0) {
      stderr.writeln(generated.stdout);
      stderr.writeln(generated.stderr);
      exitCode = generated.exitCode;
      return;
    }

    File('lib/core/design_system/generated/design_tokens.dart')
        .writeAsStringSync(_designTokens(), flush: true);
    File('lib/features/skins/data/generated/screens.g.dart')
        .writeAsStringSync(_screens(file), flush: true);
  }
  ```
  `_yaml(SkinSpec skin)` usa esta plantilla literal, con los seis colores y diez números del mapa `skin.values` en el mismo orden que el YAML actual (LF, sin CRLF):
  ```text
  schemaVersion: 1
  id: <id>
  version: <version>
  nameKey: <nameKey>
  rewardDurationHours: <rewardDurationHours>
  source: <source>
  capabilities: []
  modules:
    palette:
      segmentOn: '<segmentOn>'
      displayBackground: '<displayBackground>'
      displayBorder: '<displayBorder>'
      keyBackground: '<keyBackground>'
      keyForeground: '<keyForeground>'
      keyBorder: '<keyBorder>'
    display:
      digitWidth: <digitWidth>
      digitHeight: <digitHeight>
      radius: <displayRadius>
      paddingHorizontal: <displayPaddingHorizontal>
      paddingVertical: <displayPaddingVertical>
    buttons:
      radius: <keyRadius>
      padding: <keyPadding>
      minHeight: <keyMinHeight>
    shell:
      screenPadding: <screenPadding>
      keyboardHeight: <keyboardHeight>
  ```
  Verificar: `dart run tool/design/compile.dart && git diff --exit-code -- tool/skins/definitions/lcd_classica.yaml assets/catalog/manifest.json` → sin diff.
  Nota: la plantilla fija `capabilities: []` porque la semilla no tiene capacidades; al añadir una skin con capacidades, `_yaml()` debe emitir la lista desde `skin.values['capabilities']` en el mismo PR.

- [ ] **T13 — Compiler: `design_tokens.dart`**
  Archivo: `tool/design/compile.dart` (función `_designTokens()`)
  ```dart
  String _designTokens() => '''
// GENERADO: dart run tool/design/compile.dart. No editar a mano.
const double kBreakpointTablet = 600;
const double kBreakpointDesktop = 900;
const double kDesignMinTouchTarget = 48;
''';
  ```
  Verificar: el archivo existe y `dart format --output=none --set-exit-if-changed lib/core/design_system/generated` → 0 cambios.

- [ ] **T14 — Compiler: `screens.g.dart`**
  Archivo: `tool/design/compile.dart` (función `_screens(DesignFile file)`)
  Generar constantes usando `jsonEncode` para escapar cadenas:
  ```dart
  String _q(String? value) => value == null ? 'null' : jsonEncode(value);
  String _n(num? value) => value == null ? 'null' : '$value';

  String _node(DesignNode n) => 'DesignNode('
      'type: ${_q(n.type)}, key: ${_q(n.key)}, when: ${_q(n.when)}, '
      'padding: ${_n(n.padding)}, axis: ${_q(n.axis)}, '
      'height: ${_n(n.height)}, alignment: ${_q(n.alignment)}, '
      'titleKey: ${_q(n.titleKey)}, tooltipKey: ${_q(n.tooltipKey)}, '
      'children: <DesignNode>[${n.children.map(_node).join(', ')}])';

  String _screens(DesignFile file) {
    final StringBuffer out = StringBuffer(
      '// GENERADO: dart run tool/design/compile.dart. No editar a mano.\n'
      "import '../../../../core/widgets/layout_spec.dart';\n\n"
      'const Map<String, ScreenSpec> kScreenSpecs = <String, ScreenSpec>{\n',
    );
    for (final MapEntry<String, ScreenSpecFile> screen in file.screens.entries) {
      out.writeln("  '${screen.key}': ScreenSpec(");
      out.writeln('    appBar: AppBarSpec(');
      out.writeln('      titleKey: ${_q(screen.value.appBar.titleKey)},');
      out.writeln('      actions: <DesignNode>[${screen.value.appBar.actions.map(_node).join(', ')}],');
      out.writeln('    ),');
      out.writeln('    breakpoints: <String, LayoutSpec>{');
      for (final MapEntry<String, LayoutSpec> bp in screen.value.breakpoints.entries) {
        out.writeln("      '${bp.key}': LayoutSpec(nodes: <DesignNode>[${bp.value.nodes.map(_node).join(', ')}]),");
      }
      out.writeln('    },');
      out.writeln('  ),');
    }
    out.writeln('};');
    return out.toString();
  }
  ```
  El `main()` de T12 debe ejecutar `dart format` sobre `design_tokens.dart` y `screens.g.dart` al terminar: `_screens()` emite líneas largas y, sin ese paso, T27 fallaría por formato. El resultado debe compilar con `flutter analyze` sin correcciones manuales posteriores.
  Verificar: `dart run tool/design/compile.dart && flutter analyze --no-pub` → 0 issues.

- [ ] **T15 — Idempotencia real**
  Verificar: `flutter test test/unit/design/compile_test.dart` → verde; ejecutar `dart run tool/design/compile.dart` dos veces y `git diff --check` limpio.

### S4 — Renderizador y migración

- [ ] **T16 — Tipos del spec en la app**
  Archivo: `lib/core/widgets/layout_spec.dart`
  ```dart
  class DesignNode {
    const DesignNode({
      required this.type, this.key, this.when = 'always', this.padding,
      this.axis = 'all', this.height, this.alignment = 'start',
      this.titleKey, this.tooltipKey, this.children = const <DesignNode>[],
    });
    final String type;
    final String? key;
    final String when;
    final double? padding;
    final String axis;
    final double? height;
    final String alignment;
    final String? titleKey;
    final String? tooltipKey;
    final List<DesignNode> children;

    factory DesignNode.fromJson(Map<String, Object?> json) => DesignNode(
          type: json['type']! as String,
          key: json['key'] as String?,
          when: (json['when'] as String?) ?? 'always',
          padding: (json['padding'] as num?)?.toDouble(),
          axis: (json['axis'] as String?) ?? 'all',
          height: (json['height'] as num?)?.toDouble(),
          alignment: (json['alignment'] as String?) ?? 'start',
          titleKey: json['titleKey'] as String?,
          tooltipKey: json['tooltipKey'] as String?,
          children: (json['children'] as List<Object?>? ?? const <Object?>[])
              .map((Object? item) => DesignNode.fromJson(item! as Map<String, Object?>))
              .toList(),
        );
  }

  class AppBarSpec {
    const AppBarSpec({required this.titleKey, this.actions = const <DesignNode>[]});
    final String titleKey;
    final List<DesignNode> actions;
  }

  class LayoutSpec {
    const LayoutSpec({required this.nodes});
    final List<DesignNode> nodes;
  }

  class ScreenSpec {
    const ScreenSpec({required this.appBar, required this.breakpoints});
    final AppBarSpec appBar;
    final Map<String, LayoutSpec> breakpoints;

    factory ScreenSpec.fromJson(Map<String, Object?> json) => ScreenSpec(
          appBar: AppBarSpec(
            titleKey: json['appBar']!['titleKey']! as String,
            actions: (json['appBar']!['actions'] as List<Object?>? ?? const <Object?>[])
                .map((Object? item) => DesignNode.fromJson(item! as Map<String, Object?>))
                .toList(),
          ),
          breakpoints: (json['breakpoints']! as Map<String, Object?>).map(
            (String key, Object? value) => MapEntry<String, LayoutSpec>(
              key,
              LayoutSpec(
                nodes: ((value! as Map<String, Object?>)['nodes'] as List<Object?>)
                    .map((Object? item) =>
                        DesignNode.fromJson(item! as Map<String, Object?>))
                    .toList(),
              ),
            ),
          ),
        );
  }

  Map<String, ScreenSpec> screenSpecsFromJson(Map<String, Object?> json) =>
      (json['screens']! as Map<String, Object?>).map(
        (String key, Object? value) =>
            MapEntry<String, ScreenSpec>(key, ScreenSpec.fromJson(value! as Map<String, Object?>)),
      );
  ```
  Verificar: `flutter analyze --no-pub` → 0 issues.

- [ ] **T17 — Test rojo: el renderer preserva las keys**
  Archivo: `test/unit/design/spec_renderer_test.dart`
  ```dart
  testWidgets('el spec renderiza display, teclado y toggle con sus keys', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _harness(kScreenSpecs['normal']!)));
    expect(find.byKey(const Key('calc.display')), findsOneWidget);
    expect(find.byKey(const Key('calc.key.7')), findsOneWidget);
    expect(find.byKey(const Key('calc.toggle.mode')), findsOneWidget);
  });
  ```
  Verificar: rojo (el renderer no existe).

  El harness y sus imports se definen en el mismo archivo y se reutilizan en T18:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:retro_calculator/core/design_system/skin_tokens.dart';
  import 'package:retro_calculator/core/widgets/spec_renderer.dart';
  import 'package:retro_calculator/features/skins/data/generated/screens.g.dart';

  Widget _harness(ScreenSpec spec) => MaterialApp(
        home: SpecRenderer(
          spec: spec,
          breakpoint: 'mobile',
          tokens: SkinTokens.classicAmber,
          data: const SpecRenderData(
            texts: <String, String>{
              'angleDeg': 'DEG', 'angleRad': 'RAD', 'error': '', '7': '7',
            },
            displayText: '7',
            keyRows: <List<String>>[<String>['7', '8', '9', '+']],
            isScientific: true,
            hasError: true,
            isRadians: false,
            historyBuilder: _empty,
            skinSelectorBuilder: _empty,
          ),
          onKeyTap: (_) {},
          onToggleMode: () {},
          onAngleToggle: () {},
        ),
      );

  Widget _empty(BuildContext context) => const SizedBox.shrink();
  ```

- [ ] **T18 — Renderizador: nodos hoja**
  Archivo: `lib/core/widgets/spec_renderer.dart`
  ```dart
  import 'package:flutter/material.dart';

  import '../design_system/skin_tokens.dart';
  // El renderer no importa features/: recibe builders, no widgets ni entidades concretas.
  import 'calculator_keyboard.dart';
  import 'layout_spec.dart';
  import 'seven_segment_display.dart';

  class SpecRenderData {
    const SpecRenderData({
      required this.texts,
      required this.displayText,
      required this.keyRows,
      required this.isScientific,
      required this.hasError,
      required this.isRadians,
      required this.historyBuilder,
      required this.skinSelectorBuilder,
    });
    final Map<String, String> texts;
    final String displayText;
    final List<List<String>> keyRows;
    final bool isScientific;
    final bool hasError;
    final bool isRadians;
    final WidgetBuilder historyBuilder;
    final WidgetBuilder skinSelectorBuilder;
  }

  class SpecRenderer extends StatelessWidget {
    const SpecRenderer({
      super.key,
      required this.spec,
      required this.breakpoint,
      required this.tokens,
      required this.data,
      required this.onKeyTap,
      required this.onToggleMode,
      required this.onAngleToggle,
    });

    final ScreenSpec spec;
    final String breakpoint;
    final SkinTokens tokens;
    final SpecRenderData data;
    final ValueChanged<String> onKeyTap;
    final VoidCallback onToggleMode;
    final VoidCallback onAngleToggle;

    @override
    Widget build(BuildContext context) {
      final LayoutSpec layout = spec.breakpoints[breakpoint] ??
          spec.breakpoints['mobile']!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final DesignNode node in layout.nodes) _node(context, node),
        ],
      );
    }

    bool _visible(DesignNode node) => switch (node.when) {
          'isScientific' => data.isScientific,
          'hasError' => data.hasError,
          _ => true,
        };

    Widget _node(BuildContext context, DesignNode node) {
      if (!_visible(node)) return const SizedBox.shrink();
      switch (node.type) {
        case 'display':
          return KeyedSubtree(
            key: Key(node.key ?? 'calc.display'),
            child: SevenSegmentDisplay(text: data.displayText, tokens: tokens),
          );
        case 'keyboard':
          return CalculatorKeyboard(
            rows: data.keyRows,
            labels: data.texts,
            onKeyTap: onKeyTap,
            tokens: tokens,
          );
        case 'errorText':
          return Text(
            data.texts['error'] ?? '',
            style: const TextStyle(color: Colors.redAccent),
          );
        case 'angleChip':
          return KeyedSubtree(
            key: Key(node.key ?? 'calc.toggle.angle'),
            child: ChoiceChip(
              label: Text(data.isRadians ? data.texts['angleRad']! : data.texts['angleDeg']!),
              selected: data.isRadians,
              onSelected: (_) => onAngleToggle(),
            ),
          );
        case 'history':
          return data.historyBuilder(context);
        case 'skinSelector':
          return data.skinSelectorBuilder(context);
        default:
          return _container(context, node);
      }
    }

    Widget _container(BuildContext context, DesignNode node) {
      final Widget child = Column(
        children: <Widget>[
          for (final DesignNode item in node.children) _node(context, item),
        ],
      );
      return switch (node.type) {
        'padding' => Padding(
            padding: switch (node.axis) {
              'horizontal' => EdgeInsets.symmetric(horizontal: node.padding ?? 0),
              'vertical' => EdgeInsets.symmetric(vertical: node.padding ?? 0),
              _ => EdgeInsets.all(node.padding ?? 0),
            },
            child: child,
          ),
        'sizedBox' => SizedBox(height: node.height ?? 0, child: child),
        'row' => Row(
            mainAxisAlignment: switch (node.alignment) {
              'center' => MainAxisAlignment.center,
              'end' => MainAxisAlignment.end,
              'spaceBetween' => MainAxisAlignment.spaceBetween,
              _ => MainAxisAlignment.start,
            },
            children: <Widget>[
              for (final DesignNode item in node.children) _node(context, item),
            ],
          ),
        _ => child,
      };
    }
  }
  ```
  **Límite de capas:** el renderer no importa `features/calculator/domain/`; recibe textos y datos ya resueltos. El test `test/unit/skins/boundary_test.dart` se amplía para comprobarlo.
  Verificar: `flutter test test/unit/design/spec_renderer_test.dart` → 3/3.

- [ ] **T19 — AppBar desde el spec**
  Archivo: `lib/features/calculator/presentation/calculator_page.dart`
  Sustituir el `AppBar` actual por uno construido desde el spec activo. La clave del spec es `vm.profile.isScientific ? 'scientific' : 'normal'` (y `'selector'` en la ruta de skins). `AppLocalizations` no tiene operador `[]`, así que se añaden dos helpers privados en `_CalculatorPageState`:

  ```dart
  String _appBarTitle(AppLocalizations l10n, String key) => switch (key) {
        'calculatorTitle' => l10n.calculatorTitle,
        'skinSelectorTitle' => l10n.skinSelectorTitle,
        _ => throw StateError('titleKey no soportado: $key'),
      };

  String _appBarTooltip(AppLocalizations l10n, String key) => switch (key) {
        'modeToggleLabel' => l10n.modeToggleLabel,
        _ => throw StateError('tooltipKey no soportado: $key'),
      };
  ```

  Usar `title: Text(_appBarTitle(l10n, spec.appBar.titleKey))` y, por cada acción `modeToggle` del spec, el mismo `IconButton` de hoy con `key: const Key('calc.toggle.mode')` y `tooltip: _appBarTooltip(l10n, action.tooltipKey!)`. El validador de T8 garantiza que las claves existen en el ARB.
  Verificar: `flutter test test/widget/calculator_page_test.dart` → en verde, `calc.toggle.mode` presente.

- [ ] **T20 — Cuerpo desde el spec**
  Archivo: `lib/features/calculator/presentation/calculator_page.dart`
  Sustituir el `Column` del `body` por `SpecRenderer`, pasando:
  ```dart
  SpecRenderData(
    texts: <String, String>{
      ..._labels(l10n),
      'angleDeg': l10n.angleDeg,
      'angleRad': l10n.angleRad,
      'error': vm.errorKey == null ? '' : errorLabel(vm.errorKey!, l10n),
    },
    displayText: vm.displayText,
    keyRows: vm.profile.keyRows,
    isScientific: vm.profile.isScientific,
    hasError: vm.errorKey != null,
    isRadians: vm.angleMode == AngleMode.radians,
    historyBuilder: (_) => ExpansionTile(
      title: Text(l10n.historyTitle),
      children: <Widget>[HistoryPanel(entries: vm.history, separator: separator, decimalDigits: vm.profile.decimalDigits)],
    ),
    skinSelectorBuilder: (_) => const SkinSelector(),
  )
  ```
  El `LayoutBuilder`/`SingleChildScrollView`/`ConstrainedBox` actual se conserva alrededor del renderer. La rama `selector` de `AppRoutes` usa `kScreenSpecs['selector']`.
  Verificar: `flutter test test/widget/` → en verde.

- [ ] **T21 — Sin regresión visual ni de motor**
  Verificar: `git diff -- lib/features/calculator/domain/` → vacío; `flutter analyze` → 0; `flutter test` → 44 + nuevos.

### S5 — Preview y goldens

- [ ] **T22 — Entrypoint del preview**
  Archivo: `lib/tool_preview_main.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:retro_calculator/core/design_system/generated/skin_tokens_lcd_classica.dart';
  import 'package:retro_calculator/core/design_system/skin_tokens.dart';
  import 'package:retro_calculator/core/widgets/layout_spec.dart';
  import 'package:retro_calculator/core/widgets/spec_renderer.dart';

  void main() => runApp(const PreviewApp());

  class PreviewApp extends StatefulWidget {
    const PreviewApp({super.key});
    @override
    State<PreviewApp> createState() => _PreviewAppState();
  }

  class _PreviewAppState extends State<PreviewApp> {
    late final Map<String, ScreenSpec> specs =
        screenSpecsFromJson(jsonDecode(File('design/app.design.json').readAsStringSync())
            as Map<String, Object?>);
    String _screen = 'normal';
    String _breakpoint = 'mobile';
    bool _lcd = true;

    @override
    Widget build(BuildContext context) => MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('RetroDesign preview')),
            body: Column(
              children: <Widget>[
                Wrap(children: <Widget>[
                  for (final String key in specs.keys)
                    ChoiceChip(label: Text(key), selected: key == _screen,
                      onSelected: (_) => setState(() => _screen = key)),
                ]),
                Wrap(children: <Widget>[
                  for (final String key in const <String>['mobile', 'tablet', 'desktop'])
                    ChoiceChip(label: Text(key), selected: key == _breakpoint,
                      onSelected: (_) => setState(() => _breakpoint = key)),
                ]),
                Switch(value: _lcd, onChanged: (bool v) => setState(() => _lcd = v)),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: _breakpoint == 'mobile' ? 400 : _breakpoint == 'tablet' ? 800 : 1200,
                      child: SpecRenderer(
                        spec: specs[_screen]!,
                        breakpoint: _breakpoint,
                        tokens: _lcd ? skinTokensLcdClasica : SkinTokens.classicAmber,
                        data: const SpecRenderData(
                          texts: <String, String>{'angleDeg': 'DEG', 'angleRad': 'RAD', 'error': '', '7': '7'},
                          displayText: '1234',
                          keyRows: <List<String>>[<String>['7', '8', '9', '+']],
                          isScientific: true,
                          hasError: false,
                          isRadians: false,
                          historyBuilder: _empty,
                          skinSelectorBuilder: _empty,
                        ),
                        onKeyTap: (_) {},
                        onToggleMode: () {},
                        onAngleToggle: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    static Widget _empty(BuildContext context) => const SizedBox.shrink();
  }
  ```
  Ejecutar: `flutter run -d windows -t lib/tool_preview_main.dart` (o `-d chrome` si se añade web más adelante). Documentar que es herramienta de desarrollo, no plataforma de producto.
  Verificar: la ventana muestra las 3 pantallas, los 3 breakpoints y el cambio de skin sin error.

- [ ] **T23 — Golden tests**
  Archivo: `test/golden/design_preview_test.dart`
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:retro_calculator/core/design_system/skin_tokens.dart';
  import 'package:retro_calculator/core/widgets/spec_renderer.dart';
  import 'package:retro_calculator/features/skins/data/generated/screens.g.dart';

  const SpecRenderData _kGoldenData = SpecRenderData(
    texts: <String, String>{'angleDeg': 'DEG', 'angleRad': 'RAD', 'error': ''},
    displayText: '1234',
    keyRows: <List<String>>[<String>['7', '8', '9', '+']],
    isScientific: true,
    hasError: false,
    isRadians: false,
    historyBuilder: _empty,
    skinSelectorBuilder: _empty,
  );

  Widget _empty(BuildContext context) => const SizedBox.shrink();

  void main() {
    for (final String screen in kScreenSpecs.keys) {
      for (final String bp in const <String>['mobile', 'tablet', 'desktop']) {
        testWidgets('$screen/$bp no hace overflow', (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(
            home: SizedBox(
              width: bp == 'mobile' ? 400 : bp == 'tablet' ? 800 : 1200,
              height: 900,
              child: SpecRenderer(
                spec: kScreenSpecs[screen]!,
                breakpoint: bp,
                tokens: SkinTokens.classicAmber,
                data: _kGoldenData,
                onKeyTap: (_) {}, onToggleMode: () {}, onAngleToggle: () {},
              ),
            ),
          ));
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(SpecRenderer),
            matchesGoldenFile('goldens/${screen}_$bp.png'),
          );
        });
      }
    }
  }
  ```
  Generar capturas: `flutter test --update-goldens test/golden/design_preview_test.dart`.
  Verificar: `flutter test test/golden/design_preview_test.dart` → 9/9 y 9 PNG en `test/golden/goldens/`.

- [ ] **T24 — Documentar el flujo de goldens**
  Archivo: `docs/design/README.md`
  Explicar cuándo ejecutar `--update-goldens`, que las capturas se revisan en el PR y que un cambio de diseño sin golden actualizado falla CI.

### S7 — Editor de tokens y puente local (ejecutar después de S5, antes de S6)

- [ ] **T28 — Test rojo: `SkinTokens.fromMap`**
  Archivo: `test/unit/design/dev_skin_test.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:retro_calculator/core/design_system/skin_tokens.dart';
  import 'package:retro_calculator/core/design_system/token_validation.dart';

  void main() {
    test('fromMap construye los mismos valores que el artefacto generado', () {
      final Map<String, Object?> manifest =
          jsonDecode(File('assets/catalog/manifest.json').readAsStringSync())
              as Map<String, Object?>;
      final Map<String, Object?> tokens =
          (manifest['entries'] as List<Object?>).first!['tokens']
              as Map<String, Object?>;
      expect(validateTokens(tokens), isEmpty);
      final SkinTokens skin = SkinTokens.fromMap(tokens);
      expect(skin.segmentOn, const Color(0xFFB8E986));
      expect(skin.displayPadding,
          EdgeInsets.symmetric(horizontal: 16, vertical: 12));
      expect(skin.keyMinHeight, 48);
    });
  }
  ```
  Verificar: `flutter test test/unit/design/dev_skin_test.dart` → rojo (el factory no existe).

- [ ] **T29 — Factory `SkinTokens.fromMap`**
  Archivo: `lib/core/design_system/skin_tokens.dart`. El llamador **debe** ejecutar `validateTokens(map)` antes; el factory usa `!` porque asume datos válidos.
  ```dart
  factory SkinTokens.fromMap(Map<String, Object?> v) => SkinTokens(
        segmentOn: _color(v['segmentOn']! as String),
        displayBackground: _color(v['displayBackground']! as String),
        displayBorder: _color(v['displayBorder']! as String),
        displayRadius: (v['displayRadius']! as num).toDouble(),
        displayPadding: EdgeInsets.symmetric(
          horizontal: (v['displayPaddingHorizontal']! as num).toDouble(),
          vertical: (v['displayPaddingVertical']! as num).toDouble(),
        ),
        digitWidth: (v['digitWidth']! as num).toDouble(),
        digitHeight: (v['digitHeight']! as num).toDouble(),
        keyBackground: _color(v['keyBackground']! as String),
        keyForeground: _color(v['keyForeground']! as String),
        keyBorder: _color(v['keyBorder']! as String),
        keyRadius: (v['keyRadius']! as num).toDouble(),
        keyPadding: (v['keyPadding']! as num).toDouble(),
        keyMinHeight: (v['keyMinHeight']! as num).toDouble(),
        screenPadding: (v['screenPadding']! as num).toDouble(),
        keyboardHeight: (v['keyboardHeight']! as num).toDouble(),
      );

  static Color _color(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '').toUpperCase()}', radix: 16));
  ```
  Verificar: `flutter test test/unit/design/dev_skin_test.dart` → 1/1.

- [ ] **T30 — `SkinScope` acepta override**
  Archivo: `lib/features/skins/presentation/skin_scope.dart`. Añadir `final SkinTokens? tokensOverride` a `SkinScope` y a `_SkinScopeInherited`; `tokensOf` devuelve `scope?.tokensOverride ?? scope?.skin.tokens ?? SkinTokens.classicAmber`; `updateShouldNotify` compara también `tokensOverride`. Sin override el comportamiento es idéntico.
  Verificar: `flutter test test/widget/` → en verde; `flutter test test/unit/skins/` → en verde.

- [ ] **T31 — Servidor local del manifiesto**
  Archivo: `tool/design/serve.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  import 'package:retro_calculator/core/design_system/token_validation.dart';

  Future<void> main(List<String> args) async {
    final String host = args.contains('--host')
        ? args[args.indexOf('--host') + 1]
        : '127.0.0.1';
    final HttpServer server = await HttpServer.bind(host, 8787);
    stdout.writeln('RetroDesign bridge: http://$host:8787/skin');

    await for (final HttpRequest request in server) {
      if (request.uri.path == '/health') {
        request.response
          ..write('ok')
          ..close();
        continue;
      }
      if (request.uri.path != '/skin') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        continue;
      }
      try {
        // Se relee en cada petición: el editor solo necesita pulsar "Aplicar".
        final Map<String, Object?> manifest =
            jsonDecode(File('assets/catalog/manifest.json').readAsStringSync())
                as Map<String, Object?>;
        final Map<String, Object?> entry =
            (manifest['entries'] as List<Object?>).first! as Map<String, Object?>;
        final Map<String, Object?> tokens = entry['tokens']! as Map<String, Object?>;
        final List<String> errors = validateTokens(tokens);
        if (errors.isNotEmpty) throw StateError(errors.join('; '));
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(<String, Object?>{
            'id': entry['id'],
            'tokens': tokens,
          }))
          ..close();
      } on Object catch (error) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('$error')
          ..close();
      }
    }
  }
  ```
  Verificar: `dart run tool/design/serve.dart` en background; `curl http://127.0.0.1:8787/health` → `ok`; `curl http://127.0.0.1:8787/skin` → JSON con `id` y 16 tokens. Para dispositivo físico: `--host 0.0.0.0`.

- [ ] **T32 — `DevSkinBridge` y cableado**
  Archivo: `lib/platform/dev_skin/dev_skin_client.dart`
  ```dart
  import 'dart:convert';
  import 'dart:io';

  Future<Map<String, Object?>> fetchDevSkin(Uri url) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(url);
      request.timeout(const Duration(seconds: 2));
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Puente no disponible: ${response.statusCode}');
      }
      final String body = await response.transform(utf8.decoder).join();
      final Map<String, Object?> json = jsonDecode(body) as Map<String, Object?>;
      return json['tokens']! as Map<String, Object?>;
    } finally {
      client.close();
    }
  }
  ```
  Archivo: `lib/platform/dev_skin/dev_skin_bridge.dart`
  ```dart
  import 'dart:async';
  import 'dart:convert';

  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';

  import '../../core/design_system/skin_tokens.dart';
  import '../../core/design_system/token_validation.dart';
  import 'dev_skin_client.dart';

  class DevSkinBridge extends StatefulWidget {
    const DevSkinBridge({super.key, required this.url, required this.builder});
    final String url;
    final Widget Function(BuildContext context, SkinTokens? tokens) builder;

    @override
    State<DevSkinBridge> createState() => _DevSkinBridgeState();
  }

  class _DevSkinBridgeState extends State<DevSkinBridge> {
    SkinTokens? _tokens;
    String? _signature;
    Timer? _timer;

    @override
    void initState() {
      super.initState();
      if (kDebugMode && widget.url.isNotEmpty) {
        _poll();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
      }
    }

    Future<void> _poll() async {
      try {
        final Map<String, Object?> tokens =
            await fetchDevSkin(Uri.parse(widget.url));
        final List<String> errors = validateTokens(tokens);
        if (errors.isNotEmpty) throw StateError(errors.join('; '));
        final SkinTokens next = SkinTokens.fromMap(tokens);
        // SkinTokens no redefine ==: comparamos la firma del JSON para no
        // reconstruir el árbol en cada sondeo.
        final String signature = jsonEncode(tokens);
        if (signature != _signature && mounted) {
          setState(() {
            _signature = signature;
            _tokens = next;
          });
        }
      } on Object catch (_) {
        // Conserva el último valor válido; el catálogo local sigue operativo.
      }
    }

    @override
    void dispose() {
      _timer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) =>
        widget.builder(context, kDebugMode ? _tokens : null);
  }
  ```
  Archivo: `lib/app.dart`. Leer `const String.fromEnvironment('DEV_SKIN_URL')` y envolver el `SkinScope` actual:
  ```dart
  child: DevSkinBridge(
    url: const String.fromEnvironment('DEV_SKIN_URL'),
    builder: (BuildContext context, SkinTokens? tokens) => SkinScope(
      controller: context.read<SkinController>(),
      tokensOverride: tokens,
      child: MaterialApp(/* sin cambios */),
    ),
  ),
  ```
  Verificar: `flutter analyze` → 0 issues; `flutter test` → en verde; el puente permanece inactivo sin `--dart-define` y en release.
  **Comando Android (obligatorio el flavor):** `flutter run -d emulator-5554 --flavor prod --dart-define=DEV_SKIN_URL=http://10.0.2.2:8787/skin`. Sin `--flavor`, Gradle genera el APK con sufijo y Flutter no encuentra `app-debug.apk`.

- [ ] **T33 — Editor de tokens en el preview**
  Archivo: `lib/core/widgets/token_editor.dart`. Generar los campos desde las constantes existentes (`colorKeys` y `minValues` de `token_validation.dart`) para no duplicar la lista de 16 tokens: seis `TextField` de hex con vista previa de color y diez `TextField` numéricos. Al pulsar **Aplicar**: construir el mapa, ejecutar `validateTokens`, mostrar errores si los hay y, si está limpio, delegar en `onApply`.
  Archivo: `lib/tool_preview_main.dart`. Añadir el editor sobre el `SpecRenderer` y esta acción:
  ```dart
  Future<String?> _apply(Map<String, Object?> tokens) async {
    final Map<String, Object?> json =
        jsonDecode(File('design/app.design.json').readAsStringSync())
            as Map<String, Object?>;
    final Map<String, Object?> skin =
        (json['skins'] as List<Object?>).first! as Map<String, Object?>;
    skin['tokens'] = tokens;
    File('design/app.design.json')
        .writeAsStringSync('${jsonEncode(json)}\n'); // LF canónico
    final ProcessResult result =
        await Process.run('dart', <String>['run', 'tool/design/compile.dart']);
    return result.exitCode == 0 ? null : '${result.stdout}\n${result.stderr}';
  }
  ```
  Botón **Recargar** para descartar cambios locales leyendo el archivo otra vez.
  Verificar: en Windows, `flutter run -d windows -t lib/tool_preview_main.dart`; cambiar `segmentOn`, pulsar Aplicar y comprobar que cambian el YAML, el manifiesto y el Dart generado. Con el puente de T31/T32 activo, la app Android cambia en ~1 s sin reiniciar.

- [ ] **T34 — Prueba del límite del puente**
  Ampliar `test/unit/design/dev_skin_test.dart`: un mapa con `segmentOn` igual al `displayBackground` debe ser rechazado por `validateTokens` **antes** de llegar a `SkinTokens.fromMap`; un valor `keyMinHeight: 44` también. La app nunca aplica tokens no validados, vengan de donde vengan.
  Verificar: `flutter test test/unit/design/dev_skin_test.dart` → 3/3.

### S8 — Calculadoras con lógica nueva (ADR-0007; ejecutar después de D7)

- [ ] **T35 — Test rojo: perfil con id fuera del enum**
  Archivo: `test/unit/calculator/capability_registry_test.dart`
  ```dart
  test('un perfil con id arbitrario se construye y evalúa', () {
    final CalculatorProfile profile = CalculatorProfile(
      id: 'propinas',
      labelKey: 'modeNormal',
      capability: const BasicCapability(),
      defaultAngleMode: AngleMode.degrees,
      decimalDigits: 2,
      keyRows: <List<String>>[<String>['1', '2', '+', '=']],
      isScientific: false,
    );
    expect(profile.id, 'propinas');
    expect(const CalculatorEngine().evaluate('50+10', profile), 60);
  });
  ```
  Verificar: rojo (el id es enum y no existe `isScientific` como parámetro).

- [ ] **T36 — Migration del id a `String` y flag declarativo**
  `CalculatorProfile.id` pasa a `String`; `isScientific` pasa a ser parámetro `required bool`, no un derivado del id. `CalculatorProfiles.normal/scientific` usan `'normal'` y `'scientific'`. Ajustar `calculator_view_model.dart` (`_profile.isScientific` ya funciona igual) y `history_panel.dart` (`entry.profileId == 'scientific'`). En `history_entry.dart`, `profileId` pasa a `String` y el `fromJson` acepta el string guardado, con fallback a `'normal'` si el valor es desconocido, para no perder historial antiguo.
  Verificar: `flutter test` → 44 tests originales en verde (sin cambio de comportamiento).

- [ ] **T37 — `CapabilityRegistry`**
  Archivo: `lib/features/calculator/domain/capabilities/capability_registry.dart`. Mapa inmutable `String → CalculatorCapability Function()` con `normal` y `scientific` precargados, `ids` para el validador y `capabilityFor(String id)` que lanza `CalculatorException('unsupportedCapability')` si no existe. Añadir esa clave al catálogo de errores y su texto a los tres ARB.
  Verificar: `flutter test test/unit/calculator/capability_registry_test.dart` → verde.

- [ ] **T38 — Bloque `profiles[]` y `profiles.g.dart`**
  Ampliar `schema.dart`, `validate.dart` y `compile.dart`: cada perfil lleva `id`, `labelKey`, `capabilityId`, `isScientific`, `defaultAngleMode`, `decimalDigits` y `keyRows`. El validador exige `capabilityId` en `CapabilityRegistry.ids`, `labelKey` en el ARB, `keyRows` no vacío y `decimalDigits` entre 0 y 12. El compiler emite `lib/features/skins/data/generated/profiles.g.dart` con `kProfiles` y ejecuta `dart format` sobre él. `profiles.dart` conserva los dos perfiles semilla con valores idénticos.
  Verificar: `dart run tool/design/compile.dart && git diff --exit-code -- lib/features/skins/data/generated/profiles.g.dart` → sin diff tras la segunda ejecución.

- [ ] **T39 — Pestaña de perfiles en el editor**
  En `token_editor.dart` añadir una pestaña «Calculadoras»: lista de perfiles del JSON, campos para id/nombre/capability/flag/precisión/filas de teclas y botón «Nueva calculadora». Solo se pueden elegir `capabilityId` del registro; cualquier otro valor se rechaza antes de escribir. La semilla respeta los perfiles `normal` y `scientific` actuales.
  Verificar: en Windows, crear un perfil nuevo, aplicar y comprobar que `profiles.g.dart` lo contiene y que el validador lo acepta.

- [ ] **T40 — Scaffolding de una capacidad nueva**
  Archivo: `tool/design/new_capability.dart`. `dart run tool/design/new_capability.dart <id>` crea `lib/features/calculator/domain/capabilities/<id>_capability.dart` con una implementación que lanza `unsupportedFunction` y `test/unit/calculator/<id>_capability_test.dart` en rojo. Imprime la instrucción de registrar el id en `CapabilityRegistry`. **No genera la lógica**: esa la escribe una persona (ADR-0007).
  Verificar: el test generado falla con el mensaje esperado; tras implementar la operación, pasa.

- [ ] **T41 — Sin regresión del motor**
  Verificar: `flutter analyze` → 0; `flutter test` → 44 + nuevos; los tests de `engine/` y `capabilities/` no cambian su comportamiento; `2 + 3 = 5` sigue dando 5 en el emulador.

### S9 — Dimensiones visuales en el editor (ejecutar después de D8)

- [ ] **T42 — Sección «Tamaño» en el editor**
  Exponer en el mismo panel los tokens `screenPadding`, `keyboardHeight`, `displayRadius`, `displayPaddingHorizontal/Vertical`, `digitWidth/Height`, `keyRadius`, `keyPadding`, `keyMinHeight` y el selector de breakpoint (`mobile`, `tablet`, `desktop`). `keyMinHeight` no puede bajar de 48; el validador ya lo comprueba. Los cambios pasan por el mismo botón «Aplicar» y por `compile.dart`.
  Verificar: cambiar `keyboardHeight` de 380 a 420 en el editor, aplicar y confirmar que el Dart generado y el manifiesto cambian y que los 9 goldens siguen pasando.

- [ ] **T43 — Test de dimensión declarativa**
  Ampliar `test/unit/design/spec_renderer_test.dart`: un spec con `sizedBox.height = 420` renderiza un `SizedBox` con esa altura; un `keyMinHeight = 44` es rechazado por el validador.
  Verificar: `flutter test test/unit/design/` → en verde.

### S10 — Sonidos locales (ADR-0008; ejecutar después de D9)

- [ ] **T44 — Test rojo: `SoundPlayer`**
  Archivo: `test/unit/audio/sound_player_test.dart`. Un `SoundPlayer` falso registra los eventos `keyTap`, `equals`, `error` y `skinChange`; un evento desconocido se ignora; un fallo del reproductor no lanza excepción hacia el ViewModel.
  Verificar: rojo (la interfaz no existe).

- [ ] **T45 — Dependencia e interfaz aislada**
  Añadir `audioplayers` al `pubspec.yaml`. Crear `lib/platform/audio/sound_player.dart` con la interfaz `SoundPlayer` y `lib/platform/audio/audioplayers_sound_player.dart` con el adaptador. `lib/app.dart` aporta un `Provider<SoundPlayer>`; el resto del código importa solo la interfaz. Restaurar `windows/flutter/` tras `flutter pub get`.
  Verificar: `flutter analyze` → 0; `flutter test test/unit/audio/` → en verde.

- [ ] **T46 — Assets deterministas**
  Archivo: `tool/sounds/generate.dart`. Genera `assets/sounds/key_tap.wav`, `equals.wav`, `error.wav` y `skin_change.wav` como WAV PCM de menos de 200 ms, a partir de parámetros fijos (frecuencia, duración, atenuación). Declarar `assets/sounds/` en el `pubspec.yaml`. Los binarios se versionan y el generador es idempotente.
  Verificar: dos ejecuciones consecutivas no producen diff; los cuatro archivos existen.

- [ ] **T47 — Bloque `sounds` en el esquema y el validador**
  `design/app.design.json` gana `"sounds": {"enabled": true, "events": {"keyTap": "key_tap.wav", ...}}`. El validador comprueba que cada evento está en la whitelist y que el archivo existe en `assets/sounds/`; `compile.dart` no copia sonidos, solo valida la referencia.
  Verificar: `dart run tool/design/validate.dart` → válido; cambiar una ruta a un archivo inexistente → falla con mensaje claro.

- [ ] **T48 — Cableado de eventos**
  `CalculatorViewModel.input` dispara `keyTap`; el resultado de `=` dispara `equals`; un `errorKey` dispara `error`; `SkinController` dispara `skinChange`. Todo detrás de `sounds.enabled` y de la interfaz `SoundPlayer`. Ningún callback de audio puede impedir ni retrasar el cálculo.
  Verificar: `flutter test test/widget/` → en verde; con sonidos desactivados no se reproduce nada.

- [ ] **T49 — Verificación de audio**
  Verificar: `flutter analyze` → 0; `flutter test` → en verde; `flutter pub get` seguido de `git restore -- windows/flutter/`; en emulador, pulsar una tecla emite sonido y el modo silencio del dispositivo lo atenúa sin afectar al cálculo.

### S6 — CI y cierre

- [ ] **T25 — Job de generación en CI**
  Archivo: `.github/workflows/android-ci.yml`
  Añadir un paso al job existente de analyze/test:
  ```yaml
  - name: Generate design artifacts
    run: |
      dart run tool/design/validate.dart
      dart run tool/design/compile.dart
      git diff --exit-code -- design tool/skins/definitions assets/catalog \
        lib/core/design_system/generated lib/features/skins/data/generated
      test -z "$(git ls-files --others --exclude-standard -- \
        lib/core/design_system/generated lib/features/skins/data/generated)"
  ```
  Verificar: el workflow existente sigue disparándose en `pull_request`; el nuevo paso pasa con la semilla.

- [ ] **T26 — Documentación del contrato**
  Archivo: `docs/design/README.md`
  Incluir: esquema del JSON, whitelist de nodos, cómo ejecutar compiler y preview, cómo editar tokens y pulsar Aplicar, cómo levantar el puente y arrancar Android con `--flavor prod --dart-define=DEV_SKIN_URL=...`, cómo crear una calculadora nueva y generar el esqueleto de su capacidad, cómo ajustar dimensiones, cómo asignar sonidos, cómo actualizar goldens y la regla «el diseño nunca contiene lógica de cálculo» (ADR-0007). Dejar explícito que el puente es solo desarrollo, que el catálogo remoto lleva únicamente tokens validados y que los sonidos son locales y cosméticos (ADR-0008).

- [ ] **T27 — Verificación final**
  ```bash
  flutter pub get --enforce-lockfile
  dart run tool/design/validate.dart
  dart run tool/design/compile.dart
  dart run tool/sounds/generate.dart && git diff --exit-code -- assets/sounds
  dart format --output=none --set-exit-if-changed lib test tool
  flutter gen-l10n && git diff --exit-code -- lib/l10n
  dart run tool/skins/generate.dart && git diff --exit-code -- assets/catalog lib/core/design_system/generated
  flutter analyze
  flutter test
  flutter test test/golden/design_preview_test.dart
  git diff --check
  git check-attr eol -- tool/skins/definitions/lcd_classica.yaml
  ```
  Comprobación manual del puente (no entra en CI porque necesita la app corriendo):
  ```bash
  dart run tool/design/serve.dart
  curl http://127.0.0.1:8787/health   # → ok
  curl http://127.0.0.1:8787/skin      # → id + 16 tokens validados
  flutter run -d emulator-5554 --flavor prod \
    --dart-define=DEV_SKIN_URL=http://10.0.2.2:8787/skin
  ```
  Criterio: analyze 0 issues; tests 44 + nuevos; formato 0 cambios; generadores idempotentes; `eol: lf`; worktree limpio tras restaurar `windows/flutter/`; el editor aplica un cambio y la app lo refleja sin reiniciar.

## Slices para `to-issues`

| Slice | Tareas | Entregable vertical |
|---|---|---|
| D1 | T1–T4 | Archivo de diseño + esquema que modela las 3 pantallas |
| D2 | T5–T9 | Validador con reglas de accesibilidad e i18n |
| D3 | T10–T15 | Compiler determinista e idempotente |
| D4 | T16–T21 | App consumiendo `ScreenSpec` sin cambio visual |
| D5 | T22–T24 | Preview local + 9 goldens |
| D7 | T28–T34 | Editor de tokens + puente local (ejecutar después de D5) |
| D8 | T35–T41 | Calculadoras con lógica nueva vía registro de capacidades (ADR-0007) |
| D9 | T42–T43 | Dimensiones visuales editables y test declarativo |
| D10 | T44–T49 | Sonidos locales con `audioplayers` (ADR-0008) |
| D6 | T25–T27 | CI y documentación (ejecutar al final) |

## Riesgos

| Riesgo | Mitigación |
|---|---|
| El renderer se acopla al ViewModel | `SpecRenderData` y builders: el renderer solo ve strings y callbacks; test de límite |
| El generador de skins cambie la salida y mueva el checksum | La semilla usa los tokens exactos; T11 y T12 exigen `git diff --exit-code` y checksum `26d270cf…` |
| El compiler sobrescriba ediciones manuales | Los archivos bajo `generated/` llevan cabecera «GENERADO» y nadie los edita a mano |
| Golden tests inestables por fuentes del sistema | Fijar `tester.binding.window.physicalSize` y comparar con tolerancia, o usar solo comprobación de overflow si las imágenes difieren entre CI y local |
| `dart:io` en `lib/tool_preview_main.dart` rompe builds web | El entrypoint no se importa desde `main.dart`; web no es plataforma del producto en este alcance |
| Un diseño futuro pida un nodo nuevo | El validador rechaza nodos desconocidos: hay que ampliar esquema + renderer + tests en el mismo PR |
| El puente sirva datos inválidos | `validateTokens()` se ejecuta también en el cliente y se conserva el último tokens válido; si falla, la app sigue con el catálogo local |
| `dart:io` en el puente afecte a otros targets | El cliente vive aislado en `lib/platform/dev_skin/` y solo se activa con `kDebugMode` + `DEV_SKIN_URL` no vacío; release no lo usa |
| El emulador no alcance el servidor | `HttpServer` escucha en `127.0.0.1` por defecto y admite `--host 0.0.0.0` para dispositivo físico; en emulador se usa `10.0.2.2:8787` |
| El editor rompa el LF canónico | `jsonEncode` no emite saltos y se escribe `${jsonEncode(json)}\n`; el compiler y `git check-attr eol` lo verifican |
| El editor intente crear lógica de cálculo | El validador solo acepta `capabilityId` del registro (ADR-0007); el compiler nunca interpreta fórmulas del JSON |
| Migrar el `profileId` del historial rompa datos antiguos | `HistoryEntry.fromJson` acepta el string previo y usa `'normal'` como fallback para valores desconocidos |
| `audioplayers` regenere artefactos nativos | `flutter pub get` va seguido de `git restore -- windows/flutter/` mientras la fase activa sea Android |
| Un fallo de audio afecte al cálculo | `SoundPlayer` es cosmético: los errores se ignoran, el ViewModel no espera al reproductor y el validador exige los assets en build-time |

## Criterio de aceptación del primer entregable

1. `design/app.design.json` es la única fuente de verdad de tokens y layout.
2. `dart run tool/design/compile.dart` es idempotente y no cambia el checksum de la LCD.
3. La app se renderiza desde `ScreenSpec` con el mismo aspecto y las mismas keys de test que antes.
4. Existe un preview local ejecutable en Windows con un comando documentado.
5. El editor permite cambiar los 16 tokens, valida antes de escribir y ejecuta el compiler con un botón.
6. Con `DEV_SKIN_URL` apuntando al puente, un cambio en el editor se ve en la app en ~1 s sin recompilar; en release el puente está inactivo.
7. El editor crea perfiles nuevos apoyados en capacidades registradas; la lógica nueva se escribe en Dart con tests y el JSON nunca la contiene (ADR-0007).
8. Las dimensiones visuales se editan desde el mismo panel y respetan el mínimo de 48 dp.
9. Los sonidos se configuran desde el editor, viven en `assets/sounds/` y fallos de audio nunca afectan al cálculo (ADR-0008).
10. CI falla si el diseño y los artefactos generados divergen.
