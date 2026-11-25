# LCD clásica — Plan de implementación (primera skin configurable)

- **Fecha del plan:** 2026-11-25
- **Rama de ejecución:** `feature/skins-lcd-classica` (creada desde `main` **después** de mergear PR #4)
- **Orden de plataformas:** Android primero; Windows e iOS quedan fuera (ADR-0002)
- **Entrega:** PR posterior al MVP (PR #4). No se abre este PR hasta que PR #4 esté mergeado en `main`.

## Contexto

El usuario quiere **skins por combinación de módulos** (paletas × displays × botones × fondos), no un rediseño puntual de la pantalla actual. La primera skin será una calculadora clásica de **LCD verde**, sin usar marcas comerciales en el nombre: se llama **«LCD clásica»** (`lcd_classica`).

Decisiones que gobiernan este plan:

- **ADR-0001:** la calculadora es 100 % gratuita y siempre funcional; las skins son cosméticas; solo anuncios recompensados; al expirar vuelve el tema gratuito.
- **ADR-0003:** el generador de skins es herramienta **de equipo en build-time**, no editor de usuario ni requisito del MVP; la tienda agrupa skins, variantes cosméticas y calculadoras funcionales.
- **[ADR-0004](../adr/0004-arquitectura-modular-y-generador.md):** un solo motor en Dart puro; perfiles declarativos con IDs de capacidades; skins por combinación de módulos con validación de contraste y tamaño táctil; generador manual `dart run tool/skins/generate.dart` que publica Dart en `lib/core/design_system/generated/` y un manifiesto descargable, **nunca código del motor**; catálogo mixto (base compilada con tema LCD clásico + ampliado descargable con checksum, caché de última versión válida y control de versión); contenido descargado es **dato, nunca código**.
- **ADR-0005:** claves ARB idénticas en los cinco locales, Dart generado en `lib/l10n/` se commitea, `flutter gen-l10n`.
- **ADR-0006:** S/ 0.90 por 30 días, recompensa = 24 h por defecto si el manifiesto no declara otra duración, renovación desde expiración, gracia offline, historial de 50, contadores locales. **Este plan no implementa monetización, IAP ni anuncios**: solo prepara la base cosmética, el selector y el manifiesto con su duración declarada. Los entitlements reales son un plan posterior.

### Punto de partida verificado antes de redactar

| Elemento | Estado real |
|---|---|
| Worktree de redacción | `docs/skins-lcd-classica` sobre `docs/skins-lcd-classica`, limpio (`git status --short --branch` → `## docs/skins-lcd-classica`) |
| `main` en `13ef355` | 1 test (`test/widget/app_test.dart`); `calculator_page.dart` es un placeholder; **no existen** `seven_segment_display.dart`, `tool/skins/`, `lib/features/skins/` ni `assets/catalog/` |
| `feature/calculator-engine` en `91515d4` (PR #4) | 29 tests; aquí están los archivos que este plan refactoriza |
| `lib/core/design_system/ds_colors.dart` | `primary #4F6F52`, `secondary #D4A373`, `display #1E2A1F`, `displayText #B8E986`, `lightBackground #F5F1E8`, `darkBackground #131A14` |
| `seven_segment_display.dart` (PR #4) | segmento `#FFB000` hardcodeado (línea 9), fondo `#1E1B12` (línea 23), borde `#3A3320`, radio 8, padding 16/12, dígitos 26×48, `FittedBox` + `CustomPaint` |
| `calculator_page.dart` (PR #4) | `Key('calc.display')` en la línea 90, `SizedBox(height: 380)` en la línea 123, `ExpansionTile` de historial, keys `calc.key.*` y `calc.history.0` |
| `calculator_keyboard.dart` (PR #4) | `ElevatedButton` con `padding: EdgeInsets.all(3)` y `minimumSize: Size(0, 44)` |
| ARB | 5 archivos con **40** claves idénticas; `test/unit/i18n/arb_keys_test.dart` exige `hasLength(40)` |
| CI (PR #4) | `.github/workflows/android-ci.yml`: `flutter pub get --enforce-lockfile`, `flutter gen-l10n`, `git diff --exit-code -- lib/l10n`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` |

**Consecuencia operativa:** este plan se redacta sobre `main`, pero sus T1-T21 se ejecutan sobre el `main` **post-PR #4**. Si PR #4 cambia keys, textos o la forma de `CalculatorPage`, se actualiza este plan en la misma tarea antes de continuar (regla de documentación viva).

### Inconsistencia detectada: `minimumSize` 44 dp vs 48 dp

El código del MVP tiene `minimumSize: Size(0, 44)`, mientras ADR-0004 exige tamaño táctil **≥ 48 dp**. Para cumplir «S1 sin cambio visual», S1 conserva **44** en el tema heredado (`SkinTokens.classicAmber`). La validación ≥48 se aplica a **toda skin publicada por el generador** (la LCD clásica usa 48). El tema gratuito queda como excepción heredada documentada en [Riesgos](#riesgos); elevarlo a 48 sería un cambio visual separado, fuera de este plan. No se debe «arreglar silenciosamente» en S1.

## Alcance

### Incluye

- S1 — tokenizar colores, radios, padding, tamaño de dígito y altura de tecla en `SkinTokens`, refactorizando display, teclado y página **sin cambio visual**.
- S2 — definición modular `lcd_classica.yaml`, validación de contraste y tamaño táctil, generador manual, tokens Dart generados y manifiesto con checksum/versión/duración; CI que verifica regeneración determinista.
- S3 — entidad `Skin`, `SkinController`, `SkinScope`, selector en la UI, 4 claves ARB nuevas en los 5 locales y cableado en `app.dart` / `calculator_page.dart`, sin entitlements.
- S4 — cobertura de widget: skin aplicada, vuelta al tema gratuito, integridad del motor y de las keys/textos del MVP.
- S5 — catálogo descargable como **dato**: DTO de manifiesto, verificación de checksum en runtime, caché de última versión válida, control de versión, perfiles incompatibles ignorados y funcionamiento sin red.
- Tareas agrupadas para `to-issues` + `subagent-driven-development`: **un implementer por slice S1-S5**, con el texto completo del slice (T1-T5, T6-T11, …) como contexto. Las 25 tareas siguen siendo las unidades de verificación dentro de cada slice; se entregan juntas al mismo implementer para preservar continuidad de archivos y revisar el slice como un todo.

### Excluye

- IAP, anuncios recompensados, entitlements, expiración, renovación acumulada, gracia offline y contadores de monetización (ADR-0006, plan posterior).
- Cambios en `lib/features/calculator/domain/`: ni una línea del motor, ni perfiles de calculadora nuevos, ni capacidades nuevas.
- Windows e iOS: adaptaciones, permisos y plugins nativos.
- `.github/workflows/android.yml` (release con keystore): no se toca.
- Generador en runtime / editor de skins para el usuario (ADR-0003 y ADR-0004 lo descartan).
- Cambios de marca o nombres comerciales: la skin se llama siempre «LCD clásica».

## Arquitectura

### Capas y archivos exactos

```text
lib/
├── app.dart                                   # T17: SkinController + SkinRepository + SkinScope
├── core/
│   ├── design_system/
│   │   ├── skin_tokens.dart                    # T2: contrato de tokens + classicAmber
│   │   ├── token_validation.dart               # T8: 16 claves (tipo/formato/rango), contraste ≥ 4.5:1 y botón ≥ 48 dp (Dart puro)
│   │   └── generated/
│   │       └── skin_tokens_lcd_classica.dart   # T9: GENERADO, no editar a mano
│   └── widgets/
│       ├── seven_segment_display.dart          # T3: consume SkinTokens
│       └── calculator_keyboard.dart            # T4: consume SkinTokens
├── features/
│   ├── calculator/presentation/calculator_page.dart  # T5, T18: consume SkinScope.tokensOf
│   └── skins/
│       ├── domain/skin.dart                    # T13: entidad inmutable
│       ├── data/
│       │   ├── remote/skin_manifest.dart       # T23: DTO + checksum + compatibilidad
│       │   ├── remote/asset_manifest_source.dart # T25: rootBundle como fuente de dato
│       │   ├── local/skin_cache.dart           # T23: caché de última versión válida
│       │   └── skin_repository.dart            # T14: esqueleto con la base → T24: versión, checksum, fallback
│       ├── presentation/
│       │   ├── skin_controller.dart            # T14: selección + carga del catálogo
│       │   ├── skin_scope.dart                 # T15: InheritedWidget de tokens
│       │   └── skin_selector.dart              # T16: UI sin entitlements
├── l10n/                                       # T12: 5 ARB + Dart generado (44 claves)
└── platform/preferences/key_value_store.dart   # T23: abstracción de persistencia existente
tool/skins/
├── definitions/lcd_classica.yaml               # T7: módulos declarativos
├── generate.dart                               # T9: entrypoint manual
└── (token_validation se reusa desde lib/core)
assets/catalog/manifest.json                    # T9: manifiesto descargable (dato)
test/
├── unit/design_system/skin_tokens_test.dart    # T1
├── unit/skins/{token_validation,manifest,manifest_checksum,skin_controller,boundary,skin_repository}_test.dart
├── unit/i18n/arb_keys_test.dart                # T12: 40 → 44
└── widget/{calculator_page_test,skin_selector}_test.dart
.github/workflows/android-ci.yml                # T11: paso de regeneración (NO android.yml)
pubspec.yaml / pubspec.lock                     # T6 (yaml + crypto dev), T9 (asset), T22 (crypto runtime)
.gitattributes                                  # T7: eol=lf para la definición YAML (checksum estable)
```

### Reglas de dependencia

1. `lib/features/calculator/domain/` **no importa** Flutter ni `lib/core/design_system/`; el plan no lo toca.
2. Las skins consumen `lib/core/design_system/`; `lib/features/skins/` **nunca** importa `lib/features/calculator/domain/` (verificado por T21).
3. `tool/skins/` corre con `dart run` y reusa `lib/core/design_system/token_validation.dart` (Dart puro). **Nunca** emite código al motor.
4. El contenido descargado es JSON **dato**: tokens como valores, nunca fragmentos de Dart ejecutables. Toda entrada pasa por `validateTokens` antes de aplicarse: presencia, tipo, formato `#RRGGBB` y rango de las 16 claves, además de contraste y tamaño táctil.
5. La base (`Skin.classicAmber`, `Skin.lcdClasica`) está compilada y funciona sin red.

### Slices para `to-issues`

| Slice | Tareas | Vertical slice (tracer bullet) | Commit sugerido (`type(scope): summary` + cuerpo en español) |
|---|---|---|---|
| S1 | T1–T5 | Tokens heredados sin cambio visual; display + teclado + página consumen tokens | `refactor(design_system): tokenize calculator visuals` / Cuerpo: «Extrae colores y medidas a SkinTokens sin alterar el aspecto actual ni las keys del MVP.» |
| S2 | T6–T11 | Definición LCD → generador → tokens + manifiesto + CI | `feat(skins): generate classic lcd tokens` / Cuerpo: «Añade generador manual, validación de contraste y manifiesto con checksum y versión.» |
| S3 | T12–T18 | Skin seleccionable y aplicada desde ARB hasta la UI | `feat(skins): add cosmetic skin selector` / Cuerpo: «Añade entidad Skin, SkinScope y selector sin entitlements; la calculadora sigue gratuita.» |
| S4 | T19–T21 | Cobertura de widget y límites arquitectónicos | `test(skins): cover skin switching` / Cuerpo: «Verifica aplicación, vuelta al tema gratuito, integridad del motor y de las keys.» |
| S5 | T22–T25 | Catálogo descargable con checksum, caché y versión | `feat(skins): validate downloadable catalog` / Cuerpo: «Valida el manifiesto descargado, conserva la caché válida e ignora perfiles incompatibles.» |

> **Para `to-issues` + `subagent-driven-development`:** se crea **un issue por slice** y se asigna a **un implementer por slice S1-S5**. Cada issue incluye el texto íntegro de sus tareas (archivo principal, código literal, criterio y comando) más las tres etiquetas obligatorias `Modo`, `Contexto` y `Restricción` declaradas en cada slice. Las tareas no se reparten entre implementers distintos porque comparten los mismos archivos y un subagente fresco por T perdería el estado de la refactorización; la desviación respecto a la entrega por tarea está justificada aquí. Entre slices se ejecuta review de spec y de calidad.

## Tareas

### S1 — Tokenizar sin cambio visual (T1–T5)

- **Modo:** HITL (revisar con capturas antes/después; AFK solo si no hay cambio visual)
- **Contexto:** el MVP tiene los colores y medidas hardcodeados en `seven_segment_display.dart`, `calculator_keyboard.dart` y `calculator_page.dart`; las keys `calc.display`, `calc.key.*`, `calc.history.0` y los textos l10n son contrato.
- **Restricción:** cero cambio visual y cero toques en `lib/features/calculator/domain/`; los campos opcionales de botón de `SkinTokens.classicAmber` deben seguir en `null`.

#### T1 — Test de regresión de los tokens heredados (red)

- **Archivo principal:** `test/unit/design_system/skin_tokens_test.dart`
- **Criterio de aceptación:** el test falla porque `SkinTokens` aún no existe; documenta exactamente los valores actuales de ámbar/marrón y medidas.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/skin_tokens.dart';

void main() {
  test('los tokens heredados reproducen el aspecto actual sin cambios', () {
    const SkinTokens tokens = SkinTokens.classicAmber;
    expect(tokens.segmentOn, const Color(0xFFFFB000));
    expect(tokens.displayBackground, const Color(0xFF1E1B12));
    expect(tokens.displayBorder, const Color(0xFF3A3320));
    expect(tokens.displayRadius, 8);
    expect(
      tokens.displayPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    expect(tokens.digitWidth, 26);
    expect(tokens.digitHeight, 48);
    expect(tokens.keyPadding, 3);
    expect(tokens.keyMinHeight, 44);
    expect(tokens.screenPadding, 12);
    expect(tokens.keyboardHeight, 380);
    expect(tokens.keyBackground, isNull);
    expect(tokens.keyForeground, isNull);
    expect(tokens.keyBorder, isNull);
    expect(tokens.keyRadius, isNull);
  });
}
```

- **Verificar:** `flutter test test/unit/design_system/skin_tokens_test.dart` → falla en tiempo de compilación por `SkinTokens` inexistente (estado rojo esperado).

#### T2 — Definir `SkinTokens` (green)

- **Archivo principal:** `lib/core/design_system/skin_tokens.dart`
- **Criterio de aceptación:** contrato inmutable con valores por defecto idénticos a los hardcodeos actuales; los campos opcionales de botón son `null` para no alterar el estilo Material por defecto.
- **Código literal:**

```dart
import 'package:flutter/material.dart';

/// Valores puramente visuales de una skin. Nunca contiene lógica de cálculo.
@immutable
class SkinTokens {
  const SkinTokens({
    required this.segmentOn,
    required this.displayBackground,
    required this.displayBorder,
    required this.displayRadius,
    required this.displayPadding,
    required this.digitWidth,
    required this.digitHeight,
    this.keyBackground,
    this.keyForeground,
    this.keyBorder,
    this.keyRadius,
    required this.keyPadding,
    required this.keyMinHeight,
    required this.screenPadding,
    required this.keyboardHeight,
  });

  final Color segmentOn;
  final Color displayBackground;
  final Color displayBorder;
  final double displayRadius;
  final EdgeInsetsGeometry displayPadding;
  final double digitWidth;
  final double digitHeight;
  final Color? keyBackground;
  final Color? keyForeground;
  final Color? keyBorder;
  final double? keyRadius;
  final double keyPadding;
  final double keyMinHeight;
  final double screenPadding;
  final double keyboardHeight;

  /// Tema gratuito heredado. Sus valores son los del MVP antes de las skins.
  static const SkinTokens classicAmber = SkinTokens(
    segmentOn: Color(0xFFFFB000),
    displayBackground: Color(0xFF1E1B12),
    displayBorder: Color(0xFF3A3320),
    displayRadius: 8,
    displayPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    digitWidth: 26,
    digitHeight: 48,
    keyPadding: 3,
    keyMinHeight: 44,
    screenPadding: 12,
    keyboardHeight: 380,
  );
}
```

- **Verificar:** `flutter test test/unit/design_system/skin_tokens_test.dart && flutter analyze`.

#### T3 — Display consume tokens

- **Archivo principal:** `lib/core/widgets/seven_segment_display.dart`
- **Criterio de aceptación:** desaparecen los colores hardcodeados del constructor y del `BoxDecoration`; `text` sigue siendo la propiedad pública y el painter queda intacto.
- **Código literal (sustituye líneas 1-45; `_SevenSegmentPainter` se conserva literal desde la línea 47):**

```dart
import 'package:flutter/material.dart';

import '../design_system/skin_tokens.dart';

class SevenSegmentDisplay extends StatelessWidget {
  const SevenSegmentDisplay({
    super.key,
    required this.text,
    this.tokens = SkinTokens.classicAmber,
  });

  final String text;
  final SkinTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: tokens.displayPadding,
      decoration: BoxDecoration(
        color: tokens.displayBackground,
        borderRadius: BorderRadius.circular(tokens.displayRadius),
        border: Border.all(color: tokens.displayBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: CustomPaint(
          painter: _SevenSegmentPainter(
            text: text,
            digitWidth: tokens.digitWidth,
            digitHeight: tokens.digitHeight,
            color: tokens.segmentOn,
          ),
          size: Size(
            tokens.digitWidth * (text.isEmpty ? 1 : text.length),
            tokens.digitHeight,
          ),
        ),
      ),
    );
  }
}
```

- **Verificar:** `flutter test test/widget/calculator_page_test.dart test/unit/design_system/skin_tokens_test.dart` (los 3 tests de widget y el de tokens en verde).

#### T4 — Teclado consume tokens

- **Archivo principal:** `lib/core/widgets/calculator_keyboard.dart`
- **Criterio de aceptación:** las keys `calc.key.<id>` no cambian; con `SkinTokens.classicAmber` el `ElevatedButton` mantiene colores y forma por defecto (los campos opcionales son `null`).
- **Código literal (sustituye el archivo completo):**

```dart
import 'package:flutter/material.dart';

import '../design_system/skin_tokens.dart';

class CalculatorKeyboard extends StatelessWidget {
  const CalculatorKeyboard({
    super.key,
    required this.rows,
    required this.labels,
    required this.onKeyTap,
    this.tokens = SkinTokens.classicAmber,
  });

  final List<List<String>> rows;
  final Map<String, String> labels;
  final ValueChanged<String> onKeyTap;
  final SkinTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final List<String> row in rows)
          Expanded(
            child: Row(
              children: <Widget>[
                for (final String key in row)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.keyPadding),
                      child: ElevatedButton(
                        key: Key('calc.key.$key'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, tokens.keyMinHeight),
                          backgroundColor: tokens.keyBackground,
                          foregroundColor: tokens.keyForeground,
                          side: tokens.keyBorder == null
                              ? null
                              : BorderSide(color: tokens.keyBorder!),
                          shape: tokens.keyRadius == null
                              ? null
                              : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    tokens.keyRadius!,
                                  ),
                                ),
                        ),
                        onPressed: () => onKeyTap(key),
                        child: FittedBox(child: Text(labels[key] ?? key)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
```

- **Verificar:** `dart format --output=none --set-exit-if-changed lib test && flutter test test/widget/calculator_page_test.dart`.

#### T5 — Página consume tokens de padding y altura

- **Archivo principal:** `lib/features/calculator/presentation/calculator_page.dart`
- **Criterio de aceptación:** `EdgeInsets.all(12)` y `SizedBox(height: 380)` pasan a leerse de tokens; en T18 se sustituirán por `tokens` del `SkinScope`. Keys y textos intactos.
- **Código literal (añadir import y sustituir dos literales):**

```dart
import '../../../core/design_system/skin_tokens.dart';
```

```dart
                    Padding(
                      padding: EdgeInsets.all(
                        SkinTokens.classicAmber.screenPadding,
                      ),
                      child: SevenSegmentDisplay(
                        key: const Key('calc.display'),
                        text: vm.displayText,
                      ),
                    ),
```

```dart
                    SizedBox(
                      height: SkinTokens.classicAmber.keyboardHeight,
                      child: Padding(
                        padding: EdgeInsets.all(
                          SkinTokens.classicAmber.screenPadding,
                        ),
                        child: CalculatorKeyboard(
                          rows: vm.profile.keyRows,
                          labels: _labels(l10n),
                          onKeyTap: vm.input,
                        ),
                      ),
                    ),
```

- **Verificar:** `flutter analyze && flutter test` → 30 tests en verde (29 del MVP + el nuevo).

---

### S2 — Definición y generador (T6–T11)

- **Modo:** HITL (el generador y `.gitattributes` cambian artefactos versionados; verificar el diff generado)
- **Contexto:** ADR-0004 exige skins por módulos, generador manual, validación de contraste/tamaño y manifiesto con checksum; CI ya existe en `android-ci.yml` y no debe duplicarse.
- **Restricción:** el generador corre con `dart run`, nunca escribe en `lib/features/calculator/domain/`, y el contenido descargado es dato; no se modifica `.github/workflows/android.yml`.

#### T6 — Dependencias de build-time

- **Archivo principal:** `pubspec.yaml` + `pubspec.lock`
- **Criterio de aceptación:** `yaml` y `crypto` disponibles para el generador; lockfile commiteado para `--enforce-lockfile`.
- **Código literal:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  yaml: ^3.1.2
  crypto: ^3.0.3
```

- **Verificar:**

```bash
flutter pub get
git status --short windows/flutter        # si aparece generated_plugins.cmake, restaurarlo: git checkout -- windows/flutter/generated_plugins.cmake
flutter pub get --enforce-lockfile
flutter analyze
```

> No ejecutar `flutter pub get` desde el worktree de redacción del plan; sí en la rama de implementación. La restauración de `windows/flutter/` evita artefactos Windows no deseados en un plan Android-first.

#### T7 — Definición modular de la LCD clásica

- **Archivo principal:** `tool/skins/definitions/lcd_classica.yaml` (+ `.gitattributes`)
- **Criterio de aceptación:** cuatro módulos (paleta, display, botones, carcasa), sin lógica de cálculo; `capabilities: []` referencia IDs ya compilados; etiqueta traducible por clave; duración declarada 24 h; la definición se versiona con **LF obligatorio** para que el checksum sea idéntico en Windows y Linux.
- **Código literal:**

```yaml
schemaVersion: 1
id: lcd_classica
version: 1
nameKey: skinLcdClassicaName
rewardDurationHours: 24
source: compiled
capabilities: []
modules:
  palette:
    segmentOn: '#B8E986'
    displayBackground: '#1E2A1F'
    displayBorder: '#3A3320'
    keyBackground: '#E8F0D6'
    keyForeground: '#1E2A1F'
    keyBorder: '#4F6F52'
  display:
    digitWidth: 26
    digitHeight: 48
    radius: 8
    paddingHorizontal: 16
    paddingVertical: 12
  buttons:
    radius: 6
    padding: 3
    minHeight: 48
  shell:
    screenPadding: 12
    keyboardHeight: 380
```

Contrastes verificados: `#B8E986` sobre `#1E2A1F` = **10.69:1**; `#1E2A1F` sobre `#E8F0D6` = **12.71:1**. Ambos ≥ 4.5:1.

Añadir en `.gitattributes` (raíz del repositorio), para fijar EOL en checkout y evitar que el checksum cambie entre Windows y CI Linux:

```gitattributes
tool/skins/definitions/lcd_classica.yaml text eol=lf
```

- **Verificar:** `git diff --check -- tool/skins/definitions/lcd_classica.yaml .gitattributes && dart format --output=none --set-exit-if-changed lib test`.

#### T8 — Validación de contraste y tamaño táctil (red → green)

- **Archivo principal:** `lib/core/design_system/token_validation.dart`
- **Criterio de aceptación:** Dart puro (sin Flutter); valida presencia, tipo, formato `#RRGGBB` y rango de las **16** claves del manifiesto, además de contraste ≥ 4.5:1 y botones ≥ 48 dp; se reutiliza en el generador y en el catálogo descargado.
- **Código literal:**

```dart
import 'dart:math' as math;

const double minContrastRatio = 4.5;
const double minTouchTarget = 48;

const List<String> colorKeys = <String>[
  'segmentOn',
  'displayBackground',
  'displayBorder',
  'keyBackground',
  'keyForeground',
  'keyBorder',
];

const Map<String, num> minValues = <String, num>{
  'displayRadius': 0,
  'displayPaddingHorizontal': 0,
  'displayPaddingVertical': 0,
  'digitWidth': 8,
  'digitHeight': 16,
  'keyRadius': 0,
  'keyPadding': 0,
  'keyMinHeight': minTouchTarget,
  'screenPadding': 0,
  'keyboardHeight': 200,
};

const Map<String, num> maxValues = <String, num>{
  'displayRadius': 64,
  'displayPaddingHorizontal': 64,
  'displayPaddingVertical': 64,
  'digitWidth': 80,
  'digitHeight': 120,
  'keyRadius': 64,
  'keyPadding': 32,
  'keyMinHeight': 200,
  'screenPadding': 64,
  'keyboardHeight': 2000,
};

final RegExp hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

double relativeLuminance(String hex) {
  final String value = hex.replaceFirst('#', '');
  if (value.length != 6) {
    throw FormatException('Color debe ser #RRGGBB: $hex');
  }
  return 0.2126 * _channel(value, 0) +
      0.7152 * _channel(value, 2) +
      0.0722 * _channel(value, 4);
}

double contrastRatio(String foregroundHex, String backgroundHex) {
  final double a = relativeLuminance(foregroundHex);
  final double b = relativeLuminance(backgroundHex);
  final double high = math.max(a, b);
  final double low = math.min(a, b);
  return (high + 0.05) / (low + 0.05);
}

List<String> validateTokens(Map<String, Object?> values) {
  final List<String> errors = <String>[];
  for (final String key in colorKeys) {
    final Object? value = values[key];
    if (value == null) {
      errors.add('$key ausente');
    } else if (value is! String || !hexColorPattern.hasMatch(value)) {
      errors.add('$key debe ser #RRGGBB');
    }
  }
  for (final String key in minValues.keys) {
    final Object? value = values[key];
    if (value == null) {
      errors.add('$key ausente');
    } else if (value is! num) {
      errors.add('$key debe ser numérico');
    } else if (value < minValues[key]! || value > maxValues[key]!) {
      errors.add('$key fuera de rango');
    }
  }
  final Object? segmentOn = values['segmentOn'];
  final Object? displayBackground = values['displayBackground'];
  if (segmentOn is String &&
      displayBackground is String &&
      hexColorPattern.hasMatch(segmentOn) &&
      hexColorPattern.hasMatch(displayBackground) &&
      contrastRatio(segmentOn, displayBackground) < minContrastRatio) {
    errors.add('segmento/display por debajo de 4.5:1');
  }
  final Object? keyForeground = values['keyForeground'];
  final Object? keyBackground = values['keyBackground'];
  if (keyForeground is String &&
      keyBackground is String &&
      hexColorPattern.hasMatch(keyForeground) &&
      hexColorPattern.hasMatch(keyBackground) &&
      contrastRatio(keyForeground, keyBackground) < minContrastRatio) {
    errors.add('texto/botón por debajo de 4.5:1');
  }
  final Object? minHeight = values['keyMinHeight'];
  if (minHeight is num && minHeight < minTouchTarget) {
    errors.add('botón por debajo de 48 dp');
  }
  return errors;
}

double _channel(String hex, int offset) {
  final int value = int.parse(hex.substring(offset, offset + 2), radix: 16);
  final double channel = value / 255;
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4) as double;
}
```

```dart
// test/unit/skins/token_validation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';

const Map<String, Object?> lcdTokens = <String, Object?>{
  'segmentOn': '#B8E986',
  'displayBackground': '#1E2A1F',
  'displayBorder': '#3A3320',
  'displayRadius': 8,
  'displayPaddingHorizontal': 16,
  'displayPaddingVertical': 12,
  'digitWidth': 26,
  'digitHeight': 48,
  'keyBackground': '#E8F0D6',
  'keyForeground': '#1E2A1F',
  'keyBorder': '#4F6F52',
  'keyRadius': 6,
  'keyPadding': 3,
  'keyMinHeight': 48,
  'screenPadding': 12,
  'keyboardHeight': 380,
};

void main() {
  test('blanco sobre negro da 21:1', () {
    expect(contrastRatio('#FFFFFF', '#000000'), closeTo(21, 0.01));
  });

  test('la LCD clásica cumple las 16 claves, contraste y tamaño táctil', () {
    expect(lcdTokens, hasLength(16));
    expect(validateTokens(lcdTokens), isEmpty);
  });

  test('rechaza ausencias, formato, rango, contraste bajo y botón pequeño', () {
    final Map<String, Object?> missing = Map<String, Object?>.from(lcdTokens)
      ..remove('displayBorder');
    expect(validateTokens(missing), contains('displayBorder ausente'));

    final Map<String, Object?> malformed = Map<String, Object?>.from(lcdTokens)
      ..['keyForeground'] = 'verde';
    expect(
      validateTokens(malformed),
      contains('keyForeground debe ser #RRGGBB'),
    );

    final Map<String, Object?> outOfRange = Map<String, Object?>.from(lcdTokens)
      ..['digitWidth'] = 2;
    expect(validateTokens(outOfRange), contains('digitWidth fuera de rango'));

    final Map<String, Object?> lowContrast =
        Map<String, Object?>.from(lcdTokens)
          ..['segmentOn'] = '#777777'
          ..['displayBackground'] = '#888888';
    expect(
      validateTokens(lowContrast),
      contains('segmento/display por debajo de 4.5:1'),
    );

    final Map<String, Object?> smallKey =
        Map<String, Object?>.from(lcdTokens)..['keyMinHeight'] = 44;
    expect(
      validateTokens(smallKey),
      contains('botón por debajo de 48 dp'),
    );
  });
}
```

- **Verificar:** `flutter test test/unit/skins/token_validation_test.dart && flutter analyze`.

#### T9 — Generador manual y artefactos generados

- **Archivo principal:** `tool/skins/generate.dart`
- **Criterio de aceptación:** `dart run tool/skins/generate.dart` produce `lib/core/design_system/generated/skin_tokens_lcd_classica.dart` y `assets/catalog/manifest.json`; el manifiesto incluye `checksum` SHA-256 calculado sobre el YAML **normalizado a LF**, `version`, `definitionYaml`, `tokens` y `rewardDurationHours`; el Dart emitido es `dart format`-clean sin post-proceso; una segunda ejecución no cambia nada; el generador no escribe en el motor.
- **Código literal:**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';
import 'package:yaml/yaml.dart';

const String _definitionPath = 'tool/skins/definitions/lcd_classica.yaml';
const String _dartOutput =
    'lib/core/design_system/generated/skin_tokens_lcd_classica.dart';
const String _manifestOutput = 'assets/catalog/manifest.json';

void main() {
  // LF canónico: el mismo SHA-256 en Windows, macOS y CI Linux.
  final String raw = File(_definitionPath)
      .readAsStringSync()
      .replaceAll('\r\n', '\n');
  final YamlMap doc = loadYaml(raw) as YamlMap;
  if (doc['schemaVersion'] != 1) {
    throw StateError('schemaVersion no soportado: ${doc['schemaVersion']}');
  }
  final YamlMap modules = doc['modules'] as YamlMap;
  final YamlMap palette = modules['palette'] as YamlMap;
  final YamlMap display = modules['display'] as YamlMap;
  final YamlMap buttons = modules['buttons'] as YamlMap;
  final YamlMap shell = modules['shell'] as YamlMap;

  final Map<String, Object?> tokens = <String, Object?>{
    'segmentOn': palette['segmentOn'],
    'displayBackground': palette['displayBackground'],
    'displayBorder': palette['displayBorder'],
    'displayRadius': display['radius'],
    'displayPaddingHorizontal': display['paddingHorizontal'],
    'displayPaddingVertical': display['paddingVertical'],
    'digitWidth': display['digitWidth'],
    'digitHeight': display['digitHeight'],
    'keyBackground': palette['keyBackground'],
    'keyForeground': palette['keyForeground'],
    'keyBorder': palette['keyBorder'],
    'keyRadius': buttons['radius'],
    'keyPadding': buttons['padding'],
    'keyMinHeight': buttons['minHeight'],
    'screenPadding': shell['screenPadding'],
    'keyboardHeight': shell['keyboardHeight'],
  };
  final List<String> errors = validateTokens(tokens);
  if (errors.isNotEmpty) {
    throw StateError('Definición inválida: ${errors.join('; ')}');
  }

  final String dart = '''
// GENERADO: dart run tool/skins/generate.dart. No editar a mano.
import 'package:flutter/material.dart';
import '../skin_tokens.dart';

const SkinTokens skinTokensLcdClasica = SkinTokens(
  segmentOn: ${_color(tokens['segmentOn'] as String)},
  displayBackground: ${_color(tokens['displayBackground'] as String)},
  displayBorder: ${_color(tokens['displayBorder'] as String)},
  displayRadius: ${tokens['displayRadius']},
  displayPadding: EdgeInsets.symmetric(horizontal: ${tokens['displayPaddingHorizontal']}, vertical: ${tokens['displayPaddingVertical']}),
  digitWidth: ${tokens['digitWidth']},
  digitHeight: ${tokens['digitHeight']},
  keyBackground: ${_color(tokens['keyBackground'] as String)},
  keyForeground: ${_color(tokens['keyForeground'] as String)},
  keyBorder: ${_color(tokens['keyBorder'] as String)},
  keyRadius: ${tokens['keyRadius']},
  keyPadding: ${tokens['keyPadding']},
  keyMinHeight: ${tokens['keyMinHeight']},
  screenPadding: ${tokens['screenPadding']},
  keyboardHeight: ${tokens['keyboardHeight']},
);
''';
  File(_dartOutput)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(dart);

  final Map<String, Object?> manifest = <String, Object?>{
    'schemaVersion': 1,
    'version': doc['version'],
    'entries': <Object?>[
      <String, Object?>{
        'id': doc['id'],
        'nameKey': doc['nameKey'],
        'definition': _definitionPath,
        'definitionYaml': raw,
        'checksum': sha256.convert(utf8.encode(raw)).toString(),
        'rewardDurationHours': doc['rewardDurationHours'] ?? 24,
        'capabilities': (doc['capabilities'] as YamlList).toList(),
        'source': doc['source'],
        'tokens': tokens,
      },
    ],
  };
  File(_manifestOutput)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(manifest)}\n');
}

String _color(String hex) {
  return 'Color(0xFF${hex.replaceFirst('#', '').toUpperCase()})';
}
```

Añadir en `pubspec.yaml` la sección de assets (el archivo ya existe tras ejecutar el generador):

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/catalog/manifest.json
```

- **Verificar:**

```bash
dart run tool/skins/generate.dart
dart format --output=none --set-exit-if-changed lib/core/design_system/generated
flutter analyze
dart run tool/skins/generate.dart && git diff --exit-code -- lib/core/design_system/generated assets/catalog
```

> `definitionYaml` viaja en el manifiesto normalizado a LF para poder recalcular el checksum con solo el JSON descargado. Los `tokens` son datos (colores y medidas), nunca código. `.gitattributes` (T7) fija `eol=lf` en la definición para que el checkout de CI coincida con el local.

#### T10 — Test del manifiesto generado

- **Archivo principal:** `test/unit/skins/manifest_test.dart`
- **Criterio de aceptación:** checksum coincide con `definitionYaml` (comparado contra el YAML normalizado a LF leído desde disco), versión 1, duración 24 h por defecto declarada, nombre por clave ARB.
- **Código literal:**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el manifiesto declara checksum, versión y duración', () {
    final Map<String, dynamic> manifest = jsonDecode(
      File('assets/catalog/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(manifest['schemaVersion'], 1);
    final List<dynamic> entries = manifest['entries'] as List<dynamic>;
    final Map<String, dynamic> entry = entries.single as Map<String, dynamic>;
    expect(entry['id'], 'lcd_classica');
    expect(entry['nameKey'], 'skinLcdClassicaName');
    expect(entry['rewardDurationHours'], 24);
    final String yaml = entry['definitionYaml'] as String;
    expect(
      yaml,
      File(entry['definition'] as String)
          .readAsStringSync()
          .replaceAll('\r\n', '\n'),
    );
    expect(
      sha256.convert(utf8.encode(yaml)).toString(),
      entry['checksum'],
    );
    expect(entry['capabilities'], isEmpty);
  });
}
```

- **Verificar:** `flutter test test/unit/skins/manifest_test.dart`.

#### T11 — CI: regeneración determinista

- **Archivo principal:** `.github/workflows/android-ci.yml`
- **Criterio de aceptación:** nuevo paso `Generate skins` tras `Check generated localizations are committed`; `dart format` incluye `tool`; no se toca `.github/workflows/android.yml`.
- **Código literal (bloque nuevo):**

```yaml
      - name: Generate skins
        run: |
          dart run tool/skins/generate.dart
          dart format --output=none --set-exit-if-changed lib/core/design_system/generated
          git diff --exit-code -- lib/core/design_system/generated assets/catalog
```

```yaml
      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed lib test tool
```

- **Justificación de la elección:** se amplía `android-ci.yml` en lugar de crear un workflow separado porque es la compuerta ya existente para Android y comparte setup de Flutter, dependencias y caché; un workflow aparte duplicaría el setup y no podría comparar artefactos generados en el mismo job. El workflow de release (`android.yml`, keystore) queda intacto.
- **Verificar:** `git diff --check && git grep -n -e 'Generate skins' -e 'git diff --exit-code' -e 'dart format' -- .github/workflows/android-ci.yml`.

---

### S3 — Selector de skin (T12–T18)

- **Modo:** HITL (los ARB y el Dart generado se commitean juntos; revisar que los 5 locales tengan 44 claves)
- **Contexto:** hay 5 ARB con 40 claves idénticas y `app.dart` ya usa Provider; el selector debe ser cosmético y no consultar entitlements.
- **Restricción:** ninguna referencia a IAP, anuncios ni `lib/features/calculator/domain/`; la LCD es gratuita en este plan y el tema base siempre puede calcular.

#### T12 — Claves ARB traducibles (40 → 44)

- **Archivo principal:** `lib/l10n/app_en.arb` (y `app_es.arb`, `app_es_PE.arb`, `app_pt.arb`, `app_pt_BR.arb`) + `test/unit/i18n/arb_keys_test.dart`
- **Criterio de aceptación:** las mismas 4 claves nuevas en los 5 ARB, **JSON válido con 44 claves** (la última clave existente `errorNonFiniteResult` debe llevar coma); Dart generado commiteado; test actualizado a 44.
- **Código literal (cola exacta de `app_en.arb`; en los otros 4 ARB se cambian solo los valores según la tabla, sin quitar comas):**

```json
  "errorNonFiniteResult": "Non-finite result",
  "skinSelectorTitle": "Skin selector",
  "skinClassicName": "Classic amber",
  "skinLcdClassicaName": "Classic LCD",
  "skinResetLabel": "Reset theme"
```

| Clave | `es` / `es_PE` | `pt` / `pt_BR` |
|---|---|---|
| `skinSelectorTitle` | `Selector de skins` | `Seletor de skins` |
| `skinClassicName` | `Ámbar clásico` | `Âmbar clássico` |
| `skinLcdClassicaName` | `LCD clásica` | `LCD clássica` |
| `skinResetLabel` | `Restablecer tema` | `Restaurar tema` |

```dart
    expect(keySets.first, hasLength(44));
```

- **Verificar:**

```bash
flutter gen-l10n
flutter test test/unit/i18n/arb_keys_test.dart
git diff --exit-code -- lib/l10n    # tras commitear el Dart generado, en el segundo checkout
```

#### T13 — Entidad `Skin`

- **Archivo principal:** `lib/features/skins/domain/skin.dart`
- **Criterio de aceptación:** entidad inmutable; la base y la LCD son gratuitas en este plan (sin entitlements); la LCD usa tokens generados.
- **Código literal:**

```dart
import 'package:flutter/foundation.dart';

import '../../../core/design_system/generated/skin_tokens_lcd_classica.dart';
import '../../../core/design_system/skin_tokens.dart';

@immutable
class Skin {
  const Skin({
    required this.id,
    required this.nameKey,
    required this.tokens,
    required this.isFree,
    required this.source,
  });

  final String id;
  final String nameKey;
  final SkinTokens tokens;
  final bool isFree;
  final String source;

  static const Skin classicAmber = Skin(
    id: 'classic_amber',
    nameKey: 'skinClassicName',
    tokens: SkinTokens.classicAmber,
    isFree: true,
    source: 'compiled',
  );

  /// Gratuita mientras no haya entitlements; la monetización llega en otro plan.
  static const Skin lcdClasica = Skin(
    id: 'lcd_classica',
    nameKey: 'skinLcdClassicaName',
    tokens: skinTokensLcdClasica,
    isFree: true,
    source: 'compiled',
  );
}
```

Archivo secundario `lib/features/skins/data/skin_repository.dart`: esqueleto con la base compilada. T24 **conserva el constructor `const SkinRepository()`** y añade `SkinRepository.remote(...)`; así T14/T16/T17 siguen compilando cuando llega el catálogo.

```dart
import '../domain/skin.dart';

class SkinRepository {
  const SkinRepository();

  Future<List<Skin>> load() async => const <Skin>[
        Skin.classicAmber,
        Skin.lcdClasica,
      ];
}
```

- **Verificar:** `flutter analyze && flutter test`.

#### T14 — `SkinController` (selección)

- **Archivo principal:** `lib/features/skins/presentation/skin_controller.dart`
- **Criterio de aceptación:** selección por ID; ID desconocido se ignora; `reset()` vuelve siempre a la base gratuita; `loadCatalog` sustituye el catálogo por el que entregue el repositorio (esqueleto en T13, completo en T24).
- **Código literal:**

```dart
import 'package:flutter/foundation.dart';

import '../data/skin_repository.dart';
import '../domain/skin.dart';

class SkinController extends ChangeNotifier {
  Skin _selected = Skin.classicAmber;
  List<Skin> _catalog = const <Skin>[
    Skin.classicAmber,
    Skin.lcdClasica,
  ];

  Skin get selected => _selected;

  List<Skin> get catalog => List<Skin>.unmodifiable(_catalog);

  Future<void> loadCatalog(SkinRepository repository) async {
    _catalog = await repository.load();
    notifyListeners();
  }

  void select(String id) {
    for (final Skin skin in catalog) {
      if (skin.id == id) {
        _selected = skin;
        notifyListeners();
        return;
      }
    }
  }

  void reset() => select(Skin.classicAmber.id);
}
```

```dart
// test/unit/skins/skin_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/skins/data/skin_repository.dart';
import 'package:retro_calculator/features/skins/presentation/skin_controller.dart';

void main() {
  test('selecciona LCD, ignora IDs desconocidos y vuelve al tema gratuito', () async {
    final SkinController controller = SkinController();
    await controller.loadCatalog(const SkinRepository());
    expect(controller.catalog, hasLength(2));
    controller.select('lcd_classica');
    expect(controller.selected.id, 'lcd_classica');
    expect(
      controller.selected.tokens.segmentOn,
      const Color(0xFFB8E986),
    );
    controller.select('inexistente');
    expect(controller.selected.id, 'lcd_classica');
    controller.reset();
    expect(controller.selected.id, 'classic_amber');
    expect(
      controller.selected.tokens.segmentOn,
      const Color(0xFFFFB000),
    );
  });
}
```

- **Verificar:** `flutter test test/unit/skins/skin_controller_test.dart`.

#### T15 — `SkinScope`

- **Archivo principal:** `lib/features/skins/presentation/skin_scope.dart`
- **Criterio de aceptación:** expone los tokens de la skin seleccionada a los widgets; sin scope devuelve `SkinTokens.classicAmber` (nunca bloquea el cálculo).
- **Código literal:**

```dart
import 'package:flutter/material.dart';

import '../../../core/design_system/skin_tokens.dart';
import '../domain/skin.dart';
import 'skin_controller.dart';

class SkinScope extends StatelessWidget {
  const SkinScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final SkinController controller;
  final Widget child;

  static SkinTokens tokensOf(BuildContext context) {
    final _SkinScopeInherited? scope = context
        .dependOnInheritedWidgetOfExactType<_SkinScopeInherited>();
    return scope?.skin.tokens ?? SkinTokens.classicAmber;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => _SkinScopeInherited(
        skin: controller.selected,
        child: child!,
      ),
      child: child,
    );
  }
}

class _SkinScopeInherited extends InheritedWidget {
  const _SkinScopeInherited({
    required this.skin,
    required super.child,
  });

  final Skin skin;

  @override
  bool updateShouldNotify(_SkinScopeInherited oldWidget) =>
      oldWidget.skin != skin;
}
```

- **Verificar:** `flutter analyze`.

#### T16 — Selector visual

- **Archivo principal:** `lib/features/skins/presentation/skin_selector.dart`
- **Criterio de aceptación:** `StatefulWidget` con `State<_SkinSelectorState>` y `createState`; `initState` carga el catálogo vía `SkinRepository`; keys `skin.selector`, `skin.option.<id>`, `skin.reset`; nombres desde ARB; sin referencias a monetización.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

import '../data/skin_repository.dart';
import '../domain/skin.dart';
import 'skin_controller.dart';

class SkinSelector extends StatefulWidget {
  const SkinSelector({super.key});

  @override
  State<SkinSelector> createState() => _SkinSelectorState();
}

class _SkinSelectorState extends State<SkinSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SkinController>().loadCatalog(
            context.read<SkinRepository>(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SkinController controller = context.watch<SkinController>();
    return ExpansionTile(
      key: const Key('skin.selector'),
      title: Text(l10n.skinSelectorTitle),
      children: <Widget>[
        for (final Skin skin in controller.catalog)
          ListTile(
            key: Key('skin.option.${skin.id}'),
            title: Text(_name(l10n, skin.nameKey)),
            trailing: controller.selected.id == skin.id
                ? const Icon(Icons.check)
                : null,
            onTap: () => context.read<SkinController>().select(skin.id),
          ),
        ListTile(
          key: const Key('skin.reset'),
          title: Text(l10n.skinResetLabel),
          onTap: () => context.read<SkinController>().reset(),
        ),
      ],
    );
  }

  String _name(AppLocalizations l10n, String key) {
    return switch (key) {
      'skinClassicName' => l10n.skinClassicName,
      'skinLcdClassicaName' => l10n.skinLcdClassicaName,
      _ => key,
    };
  }
}
```

- **Verificar:** `flutter analyze && flutter test test/widget/app_test.dart`.

#### T17 — Cablear `SkinController` y `SkinScope` en `app.dart`

- **Archivo principal:** `lib/app.dart`
- **Criterio de aceptación:** el provider vive por encima de `MaterialApp`; `Builder` permite leer el controller antes de crear el scope.
- **Código literal (añadir imports, provider y envolver `MaterialApp`):**

```dart
import 'features/skins/data/skin_repository.dart';
import 'features/skins/presentation/skin_controller.dart';
import 'features/skins/presentation/skin_scope.dart';
```

```dart
        Provider<SkinRepository>(create: (_) => const SkinRepository()),
        ChangeNotifierProvider<SkinController>(
          create: (_) => SkinController(),
        ),
```

```dart
      child: Builder(
        builder: (BuildContext context) => SkinScope(
          controller: context.read<SkinController>(),
          child: MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appName,
            debugShowCheckedModeBanner: false,
            locale: LocaleResolver.initial(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: DSTheme.toMaterialTheme(Brightness.light),
            darkTheme: DSTheme.toMaterialTheme(Brightness.dark),
            themeMode: ThemeMode.system,
            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      ),
```

- **Verificar:** `flutter test test/widget/app_test.dart test/widget/calculator_page_test.dart` (keys y textos del MVP intactos).

#### T18 — Página aplica tokens y muestra el selector

- **Archivo principal:** `lib/features/calculator/presentation/calculator_page.dart`
- **Criterio de aceptación:** `Key('calc.display')`, keys de teclas, `ExpansionTile` de historial y textos l10n permanecen; el selector se añade al final.
- **Código literal (sustituir el import de tokens y fragmentos):**

```dart
import '../../../core/design_system/skin_tokens.dart';
import '../../../features/skins/presentation/skin_scope.dart';
import '../../../features/skins/presentation/skin_selector.dart';
```

```dart
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final CalculatorViewModel vm = context.watch<CalculatorViewModel>();
    final SkinTokens tokens = SkinScope.tokensOf(context);
```

```dart
                    Padding(
                      padding: EdgeInsets.all(tokens.screenPadding),
                      child: SevenSegmentDisplay(
                        key: const Key('calc.display'),
                        text: vm.displayText,
                        tokens: tokens,
                      ),
                    ),
```

```dart
                    SizedBox(
                      height: tokens.keyboardHeight,
                      child: Padding(
                        padding: EdgeInsets.all(tokens.screenPadding),
                        child: CalculatorKeyboard(
                          rows: vm.profile.keyRows,
                          labels: _labels(l10n),
                          onKeyTap: vm.input,
                          tokens: tokens,
                        ),
                      ),
                    ),
                    ExpansionTile(
                      title: Text(l10n.historyTitle),
                      children: <Widget>[
                        HistoryPanel(
                          entries: vm.history,
                          separator: separator,
                          decimalDigits: vm.profile.decimalDigits,
                        ),
                      ],
                    ),
                    const SkinSelector(),
```

- **Verificar:** `dart format --output=none --set-exit-if-changed lib test && flutter test` → 35 tests en verde (29 del MVP + 6 nuevos hasta T14).

---

### S4 — Cobertura de widget (T19–T21)

- **Modo:** AFK (verificación automatizada; HITL si el recuento de tests difiere del esperado)
- **Contexto:** el selector ya aplica tokens; hay que demostrar que cambiar de skin no altera el cálculo, el historial ni las keys del MVP.
- **Restricción:** no añadir dependencias de UI al motor; los tests deben usar las keys públicas y comparar `SkinTokens`, nunca píxeles.

#### T19 — Skin LCD aplicada

- **Archivo principal:** `test/widget/skin_selector_test.dart`
- **Criterio de aceptación:** al tocar `skin.option.lcd_classica` el display usa `#B8E986`, el teclado usa ≥48 dp y el resultado calculado sigue siendo `5`.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/core/widgets/calculator_keyboard.dart';
import 'package:retro_calculator/core/widgets/seven_segment_display.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';

void main() {
  testWidgets('aplica la LCD clásica sin alterar el cálculo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );
    await tester.tap(find.byKey(const Key('skin.selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skin.option.lcd_classica')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .tokens
          .segmentOn,
      const Color(0xFFB8E986),
    );
    expect(
      tester.widget<CalculatorKeyboard>(find.byType(CalculatorKeyboard)).tokens.keyMinHeight,
      greaterThanOrEqualTo(48),
    );
    for (final String key in <String>['2', '+', '3', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .text,
      '5',
    );
  });
}
```

- **Verificar:** `flutter test test/widget/skin_selector_test.dart`.

#### T20 — Vuelta al tema gratuito y base siempre funcional

- **Archivo principal:** `test/widget/skin_selector_test.dart` (segundo `testWidgets`)
- **Criterio de aceptación:** `skin.reset` devuelve `#FFB000`; el historial y los textos localizados siguen visibles; calcular después del reset da `5`.
- **Código literal (añadir al archivo):**

```dart
  testWidgets('restablecer vuelve al tema gratuito y el historial sigue funcionando', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );
    await tester.tap(find.byKey(const Key('skin.selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skin.option.lcd_classica')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skin.reset')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .tokens
          .segmentOn,
      const Color(0xFFFFB000),
    );
    for (final String key in <String>['2', '+', '3', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .text,
      '5',
    );
    expect(find.byKey(const Key('calc.history.0')), findsOneWidget);
  });
```

- **Verificar:** `flutter test test/widget/skin_selector_test.dart test/widget/calculator_page_test.dart`.

#### T21 — Límite arquitectónico: skins no tocan el motor

- **Archivo principal:** `test/unit/skins/boundary_test.dart`
- **Criterio de aceptación:** ningún archivo de skins/design_system importa el motor; el motor sigue sin importar Flutter.
- **Código literal:**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las skins no importan el motor y el motor no importa Flutter', () {
    final List<File> skinFiles = <Directory>[
      Directory('lib/features/skins'),
      Directory('lib/core/design_system'),
    ].expand(
      (Directory directory) =>
          directory.listSync(recursive: true).whereType<File>(),
    ).where((File file) => file.path.endsWith('.dart')).toList();
    for (final File file in skinFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('features/calculator/domain')),
        reason: file.path,
      );
    }
    final List<File> engineFiles = Directory('lib/features/calculator/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();
    for (final File file in engineFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains("package:flutter")),
        reason: file.path,
      );
    }
  });
}
```

- **Verificar:** `flutter test test/unit/skins/boundary_test.dart && flutter analyze && flutter test` → 38 tests en verde.

---

### S5 — Catálogo descargable como dato (T22–T25)

- **Modo:** HITL (checksum, caché y versión son load-bearing; revisar los casos offline y corrupto)
- **Contexto:** el manifiesto generado en S2 viaja como JSON; `KeyValueStore` ya existe en `lib/platform/preferences/` y la base compilada funciona sin red.
- **Restricción:** el contenido descargado es dato, nunca código; no se implementan entitlements reales y las entradas incompatibles se filtran una a una, sin descartar las válidas.

#### T22 — Checksum disponible en runtime

- **Archivo principal:** `pubspec.yaml` + `test/unit/skins/manifest_checksum_test.dart`
- **Criterio de aceptación:** `crypto` pasa de `dev_dependencies` a `dependencies` (la app verifica checksum en ejecución); el test demuestra que el manifiesto es autocontenido.
- **Código literal:**

Secciones completas tras el cambio (se **añade/mueve** `crypto`; el resto de dependencias se conserva, incluidas `provider` y `cupertino_icons`, necesarias en T16/T17):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
  cupertino_icons: ^1.0.8
  provider: ^6.1.5+1
  shared_preferences: ^2.5.6
  crypto: ^3.0.3
```

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  yaml: ^3.1.2
```

```dart
// test/unit/skins/manifest_checksum_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el JSON descargado basta para recalcular el checksum', () {
    final Map<String, dynamic> manifest = jsonDecode(
      File('assets/catalog/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final Map<String, dynamic> entry =
        (manifest['entries'] as List<dynamic>).single as Map<String, dynamic>;
    final String yaml = File(entry['definition'] as String)
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    expect(entry['definitionYaml'], yaml);
    expect(
      sha256.convert(utf8.encode(entry['definitionYaml'] as String)).toString(),
      entry['checksum'],
    );
  });
}
```

- **Verificar:**

```bash
flutter pub get
git status --short windows/flutter
flutter pub get --enforce-lockfile
flutter test test/unit/skins/manifest_checksum_test.dart
```

#### T23 — DTO de manifiesto y caché de última versión válida

- **Archivo principal:** `lib/features/skins/data/remote/skin_manifest.dart`
- **Criterio de aceptación:** `fromJson` valida `schemaVersion`, calcula checksum, marca incompatibles (IDs de capacidades desconocidos o tokens inválidos) y `toJson` conserva **todos** los campos, incluido `definition`; la caché filtra entrada por entrada con `where` y descarta solo las inválidas.
- **Código literal:**

```dart
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
        (String id) =>
            const <String>{'normal', 'scientific'}.contains(id),
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
          capabilities: (json['capabilities'] as List<dynamic>?)
                  ?.cast<String>() ??
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
```

```dart
// lib/features/skins/data/local/skin_cache.dart
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
    } on FormatException {
      return null;
    }
  }

  Future<void> save(SkinManifest manifest) =>
      _store.setString(key, manifest.toJson());
}
```

- **Verificar:** `flutter analyze && flutter test test/unit/skins/manifest_checksum_test.dart`.

#### T24 — Repositorio con versión, checksum y fallback

- **Archivo principal:** `lib/features/skins/data/skin_repository.dart`
- **Criterio de aceptación:** se conserva `const SkinRepository()` de T13 (catálogo base sin red) y se añade `SkinRepository.remote(...)`; cada entrada remota se filtra con `where` por checksum y compatibilidad, sin descartar las válidas del mismo manifiesto; si no queda ninguna entrada válida o no hay red → catálogo base + caché válida; versión remota menor o igual → se conserva la caché; contenido tratado como dato.
- **Código literal:**

```dart
import 'package:flutter/material.dart';

import '../../../core/design_system/skin_tokens.dart';
import '../domain/skin.dart';
import 'local/skin_cache.dart';
import 'remote/skin_manifest.dart';

abstract interface class SkinManifestSource {
  Future<String> fetch();
}

class SkinRepository {
  /// Constructor de T13: base compilada, sin manifiesto ni caché.
  const SkinRepository() : _source = null, _cache = null;

  const SkinRepository.remote(this._source, this._cache);

  final SkinManifestSource? _source;
  final SkinCache? _cache;

  Future<List<Skin>> load() async {
    if (_source == null || _cache == null) {
      return const <Skin>[Skin.classicAmber, Skin.lcdClasica];
    }
    final SkinManifest? cached = await _cache!.loadValid();
    try {
      final SkinManifest parsed =
          SkinManifest.fromJson(await _source!.fetch());
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
      await _cache!.save(remote);
      return _compiledPlus(remote);
    } on FormatException {
      return _compiledPlus(cached);
    } on Object {
      return _compiledPlus(cached);
    }
  }

  List<Skin> _compiledPlus(SkinManifest? manifest) {
    final List<Skin> skins = <Skin>[Skin.classicAmber, Skin.lcdClasica];
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
```

```dart
// test/unit/skins/skin_repository_test.dart
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
}
```

- **Verificar:** `flutter test test/unit/skins/skin_repository_test.dart`.

#### T25 — Catálogo descargado en el selector (sin red)

- **Archivo principal:** `lib/features/skins/data/remote/asset_manifest_source.dart`
- **Criterio de aceptación:** `AssetManifestSource` lee el manifiesto como dato (`rootBundle`); este slice sustituye el `Provider<SkinRepository>` del esqueleto por `SkinRepository.remote(...)`; `SkinController.loadCatalog` y el `initState` de `SkinSelector` **ya existen desde T13/T14/T16 y no se duplican**; si la fuente falla el repositorio devuelve la base; sin entitlements.
- **Código literal:**

```dart
import 'package:flutter/services.dart';

import '../skin_repository.dart';

class AssetManifestSource implements SkinManifestSource {
  const AssetManifestSource(this._assetPath);

  final String _assetPath;

  @override
  Future<String> fetch() => rootBundle.loadString(_assetPath);
}
```

En `lib/app.dart`, `features/skins/data/skin_repository.dart` ya fue importado en T17 y `platform/preferences/shared_preferences_key_value_store.dart` ya estaba en el MVP (línea 12): **no duplicar esos imports**. Añadir solo:

```dart
import 'features/skins/data/local/skin_cache.dart';
import 'features/skins/data/remote/asset_manifest_source.dart';
```

Sustituir el provider del esqueleto:

```dart
        Provider<SkinRepository>(
          create: (_) => SkinRepository.remote(
            const AssetManifestSource('assets/catalog/manifest.json'),
            SkinCache(SharedPreferencesKeyValueStore.create()),
          ),
        ),
```

> No hay cambios en `SkinController` ni en `SkinSelector`: T14 ya define `loadCatalog` y T16 ya define `initState` con `mounted` y `context.read`. El constructor `const SkinRepository()` sigue disponible para los tests que no necesitan catálogo remoto.

- **Verificar:** `dart format --output=none --set-exit-if-changed lib test tool && flutter analyze && flutter test` → 42 tests en verde.

## Verificación final

Ejecutar en la rama `feature/skins-lcd-classica`, con PR #4 ya mergeado, justo antes de la review de spec/calidad:

```bash
# 1. Dependencias y artefactos (vigilar windows/flutter/generated_plugins.cmake)
flutter pub get
git status --short windows/flutter
flutter pub get --enforce-lockfile

# 2. Localizaciones: claves idénticas y Dart generado commiteado
flutter gen-l10n
git diff --exit-code -- lib/l10n
flutter test test/unit/i18n/arb_keys_test.dart

# 3. Generador manual: reproducible y sin derivas
dart run tool/skins/generate.dart
dart format --output=none --set-exit-if-changed lib/core/design_system/generated
git diff --exit-code -- lib/core/design_system/generated assets/catalog

# 4. Formato, análisis y toda la suite
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test

# 5. Límites y estado
git diff --check
git check-attr eol -- tool/skins/definitions/lcd_classica.yaml
git status --short --branch
git grep -n 'lib/features/calculator/domain' -- lib/features/skins lib/core/design_system || true
```

Criterio de salida: comandos 2-5 en verde, sin cambios en `lib/features/calculator/domain/`, sin `android.yml` modificado y sin artefactos Windows versionados. Número esperado de tests al cierre: **42** (29 del MVP + 13 nuevos: 1 de tokens, 3 de validación, 1 de manifiesto, 1 de controller, 2 de widget de selector, 1 de boundary, 1 de checksum, 3 de repositorio; el test de ARB ya existía y solo cambia su expectativa de 40 a 44 claves). Si el recuento difiere, revisar el desglose antes de anunciar completitud.

> Nota: el recuento anterior es una guía, no una excusa. La evidencia válida es la salida real de `flutter test`; si hay más o menos tests, se corrige este plan en la misma tarea.

## Riesgos

1. **Altura táctil del tema heredado (44 dp vs 48 dp de ADR-0004).** S1 conserva 44 para no cambiar el aspecto; la LCD generada usa 48 y el validador rechaza cualquier skin publicada por debajo de 48. Si se decide elevar también la base, hacerlo en un commit separado con capturas antes/después y actualizar T1/T4 en consecuencia. **No arreglarlo en silencio en S1.**
2. **PR #4 aún no mergeado.** La redacción se hizo sobre `main@13ef355` (1 test, página placeholder); los hechos del MVP se leyeron en `feature/calculator-engine@91515d4` (29 tests). Si PR #4 cambia keys, textos o estructura, actualizar este plan antes de ejecutar T1.
3. **`flutter pub get` en Windows.** Puede reescribir `windows/flutter/generated_plugins.cmake` (ya ocurrió en el worktree del MVP). Restaurarlo en T6 y T22; este plan no adapta Windows.
4. **Determinismo del generador.** `jsonEncode` conserva el orden de inserción, pero un cambio de orden en el YAML o en el mapa `tokens` rompe `git diff --exit-code` en CI. El generador construye el mapa explícitamente; cualquier reordenación debe regenerarse y commitearse en la misma tarea.
5. **Caché y versión.** Cada entrada se filtra por checksum y `validateTokens`: una entrada inválida no descarta las válidas del mismo manifiesto. Si no queda ninguna entrada válida o no hay red, vuelve la base compilada más la caché válida; si la `version` remota es igual o menor que la de la caché, se conserva la caché. Una caché corrupta se descarta por completo. No se implementa gracia offline de entitlements (ADR-0006) porque aquí no hay entitlements.
6. **Contenido descargado como dato.** Los tokens remotos se convierten a `SkinTokens` mediante `Color(int.parse('0xFF${hex.substring(1)}'))`, después de validar las 16 claves; nunca se evalúa código. Cualquier nombre de clave nueva debe añadirse a `token_validation.dart`, al generador y a `_tokensFrom` en la misma tarea.
7. **ARB.** Subir de 40 a 44 claves obliga a actualizar los 5 ARB y el Dart generado; olvidar `flutter gen-l10n` rompe la CI en `git diff --exit-code -- lib/l10n`.
8. **Monetización diferida.** `Skin.lcdClasica.isFree == true` mientras no haya entitlements. Cuando se implemente IAP/anuncios (plan posterior), cambiar ese flag y conectar `SkinScope` con `lib/features/monetization/entitlements/`; la base `classicAmber` nunca debe dejar de ser gratuita (ADR-0001).
9. **Sin backend.** `AssetManifestSource` es la fuente inicial del manifiesto; sustituirlo por HTTP en el plan de catálogo remoto sin tocar `SkinRepository` ni la UI.
