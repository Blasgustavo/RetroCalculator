# RetroDesign Studio v2 (editor visual, fórmulas, imágenes, publicación y monetización) — Plan de implementación

> Este plan **supera** a `2026-11-24-design-studio-compiler.md` (v1). La v1 queda como registro histórico del compiler, el puente local y los primeros 10 slices; no se debe implementar tal cual.

## Contexto

El MVP Android y la skin LCD están mergeados en `main@4dc11fb` con CI verde (`flutter analyze` 0 issues, `flutter test` 44/44). El usuario pidió una herramienta para diseñar la app y enviar el resultado a dispositivos ya instalados. Tras revisar la v1, corrigió el alcance:

1. La **skin por defecto** también se crea en la herramienta (hoy `SkinTokens.classicAmber` es una constante escrita a mano, con `keyMinHeight: 44`).
2. Debe haber **soporte de imágenes**.
3. La app instalada debe actualizarse desde la herramienta, no solo en `localhost` durante desarrollo.
4. Las **fórmulas de cálculo** también se envían desde la herramienta.
5. El editor debe ser **drag-and-drop intuitivo, similar a Figma**.
6. La herramienta **publica el catálogo** y configura el **tema visual de los anuncios y la presentación de monetización**.

Decisiones load-bearing registradas antes de planificar:

- **ADR-0004**: el contenido del catálogo es dato, nunca código; el generador emite tokens y manifiesto build-time.
- **ADR-0007**: perfiles extensibles con `CapabilityRegistry`; parcialmente superado por ADR-0009.
- **ADR-0008**: sonidos locales con `audioplayers` aislado en `lib/platform/audio/`.
- **ADR-0009**: fórmulas declarativas con variables, parseadas por el motor; sin `eval`.
- **ADR-0010**: publicación remota versionada y firmada; supera el «backend diferido» solo para catálogo, no para entitlements.
- **ADR-0011**: editor visual sobre base Dart (`fluttercanvas`) + adaptador a nuestro esquema; **sin fork** de Penpot/Figma.
- **ADR-0012**: claves ARB en camelCase y placeholders versionados para los assets de la semilla.

Sobre «¿lo soporta nativamente?»: Flutter no trae un editor tipo Figma en el SDK, solo gestos y `CustomPainter`. Se eligió un spike con `fluttercanvas` (MIT, v0.3.0) como base del canvas, con un adaptador a `design/app.design.json`. El preview y la app comparten **nuestro** `SpecRenderer`; el exportador Dart y el renderer del paquete no se usan. Si el spike falla por inmadurez del paquete, se cae a un canvas propio mínimo con el mismo contrato (ADR-0011).

Los mockups visuales se solicitaron pero **no se generaron**: el proveedor de imágenes devolvió `Insufficient balance`. Quedan wireframes de texto en esta sección; los prompts están conservados para regenerarlos cuando haya créditos.

### Wireframe del Studio

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ RetroDesign Studio   [Guardar] [Validar] [Compilar] [Publicar ▾]             │
├────────────┬──────────────────────────────────┬──────────────────────────────┤
│ PALETA     │ CANVAS [mobile][tablet][desktop] │ INSPECTOR                     │
│ Display    │ ┌──────────────────────────────┐ │ selected: display             │
│ Keyboard   │ │ ┌──────────────────────────┐ │ │ key: calc.display             │
│ Key        │ │ │          1234            │ │ │ bg [#1E1B12]  fg [#B8E986]    │
│ Row/Column │ │ └──────────────────────────┘ │ │ radius [8]  pad [16]/[12]     │
│ Image      │ │ ┌───┬───┬───┬───┐  ⟵ arrastrar│ │ imagen [fondo_panel.png ▾]   │
│ Panel      │ │ │ C │ ? │ % │ / │            │ │ fórmula [base*(1+tasa/100)]   │
│            │ │ └───┴───┴───┴───┘            │ │ [Aplicar a selección]         │
├────────────┼──────────────────────────────────┼──────────────────────────────┤
│ CAPAS      │ VISTA PREVIA (SpecRenderer)      │ VALIDACIÓN / PUBLICACIÓN      │
│ ▾ normal   │ [Ámbar] [LCD] [Otra skin]        │ ✓ contraste 7.2:1             │
│   display  │ [▶] reproducir fórmula con inputs│ ✓ teclas 48 dp                │
│   keyboard │                                  │ ✓ fórmulas compile            │
│   history  │                                  │ ✓ firma y checksum listos     │
└────────────┴──────────────────────────────────┴──────────────────────────────┘
```

### Wireframes de pestañas

```
CALCULADORAS                          TAMAÑO
Perfiles: [normal][scientific][+ Nueva] breakpoint: (mobile)(tablet)(desktop)
id [igv]  labelKey [modeIgv]          screenPadding [12]   keyboardHeight [380]
capability [basic ▾]  isScientific [ ] displayRadius [8]   pad H/V [16]/[12]
inputs [base][tasa]                   digit W/H [26]/[48]  key radius/pad [6]/[3]
fórmula resultado [base*(1+tasa/100)] keyMinHeight [48] dp ← mínimo innegociable
[Generar esqueleto de capacidad]      [Ver en goldens]

SONIDOS                               MONETIZACIÓN
habilitado [✓]                        anuncio: (recompensado) ← único permitido
keyTap [key_tap.wav ▾] [▶] 40 ms       color botón [#FFB000]  texto [ads.reward.*]
equals [equals.wav ▾]  [▶] 90 ms       products [skin_lcd_classica] [calculator_pro_30d]
error [error.wav ▾]    [▶] 120 ms      precios: solo copy ARB; autoridad = tienda
skinChange [skin_change.wav ▾] [▶]    entitlements: NO editables desde el catálogo
[Regenerar WAV]

PUBLICAR
prod ▾  versión 3  [Validar] [Firmar] [Publicar] [Ver historial] [Revertir a v2]
```

### Wireframes del app

```
NORMAL / LCD                         CIENTÍFICA
┌───────────────────────┐            ┌───────────────────────┐
│ RetroCalculator   [⇄] │            │ RetroCalculator   [⇄] │
│ ┌───────────────────┐ │            │ ┌───────────────────┐ │
│ │              1234 │ │            │ │            1234.56│ │
│ └───────────────────┘ │            │ └───────────────────┘ │
│ ┌────┬────┬────┬────┐ │            │       ( DEG ) ( RAD ) │
│ │ C  │ ?  │ %  │ /  │ │            │ ┌───┬───┬───┬───┬───┐ │
│ │ 7  │ 8  │ 9  │ *  │ │            │ │sin│cos│tan│ ( │ ) │ │
│ │ 4  │ 5  │ 6  │ -  │ │            │ │ln │log│√  │ ^ │ ! │ │
│ │ 1  │ 2  │ 3  │ +  │ │            │ │pi │e  │MC │MR │M+ │ │
│ │ ±  │ 0  │ .  │ =  │ │            │ └───┴───┴───┴───┴───┘ │
│ └────┴────┴────┴────┘ │            │ ▾ Historial           │
│ ▾ Historial           │            └───────────────────────┘
│ Tema: (LCD)(Ámbar)    │
└───────────────────────┘

SELECTOR                             ERROR / CATÁLOGO
Seleccionar tema                     ┌───────────────────────┐
▣ LCD clásica   [Gratis]             │            Error      │
□ Ámbar clásico [Gratis]             │ No se puede dividir   │
[Restablecer]                        │ entre 0               │
                                     └───────────────────────┘
                                     ✓ Catálogo v3 aplicado
```

## Alcance

### La herramienta hace

- Autoría visual drag-and-drop de nodos, capas, breakpoints y props (ADR-0011).
- Creación y edición de la skin por defecto y de skins nuevas: 16 tokens, contraste ≥ 4.5:1 y teclas ≥ 48 dp.
- Creación de calculadoras con perfiles y **fórmulas declarativas** sobre el motor existente (ADR-0007, ADR-0009).
- Importación de imágenes locales con SHA-256 y límites de tamaño/dimensión.
- Edición de dimensiones visuales (padding, display, teclado, breakpoints) con mínimo táctil innegociable.
- Asignación de sonidos locales a eventos (ADR-0008).
- Configuración **visual** del anuncio recompensado y de los textos/product IDs visibles; nunca precios ni entitlements.
- Validación, compilación idempotente, publicación versionada y revert (ADR-0010).
- Puente local de desarrollo (`localhost:8787`) para iterar sin recompilar.

### La herramienta no hace

- No genera widgets Dart para la app: genera datos que `SpecRenderer` interpreta.
- No ejecuta código del diseño: ni `eval`, ni Dart, ni fórmulas arbitrarias (ADR-0004, ADR-0009).
- No crea anuncios no recompensados, ni cobra por calcular (ADR-0001).
- No fija precios, no otorga entitlements y no reemplaza a la tienda (ADR-0003, ADR-0006).
- No publica imágenes ni sonidos remotos arbitrarios: se validan y versionan como assets.
- No reduce el APK: es configuración de build, no diseño.
- No forkea Penpot/Figma (ADR-0011).

### Flujo de una edición

```
Studio (canvas + inspector)
   │ adaptador fluttercanvas → design/app.design.json (LF, fuente de verdad)
   ▼
validate.dart ──► compile.dart ──► YAML / manifest v2 / *.g.dart / assets
   │                                   │
   │                                   ├─► puente localhost (debug, ~1 s)
   │                                   └─► Publicar → catálogo firmado por canal
   ▼                                          ▼
SpecRenderer (preview = app)          App instalada: fetch → firma → checksum
                                      → valida → aplica → caché → rollback si falla
```

## Arquitectura

```
tool/design/                       ← Studio (Flutter Windows) + compiler + validador
  lib/ (entrypoint tool)
  adapters/fluttercanvas_to_design.dart
  schema.dart, validate.dart, compile.dart, publish.dart, serve.dart
design/app.design.json             ← única fuente de verdad
design/assets/                     ← imágenes fuente
assets/images/ assets/sounds/      ← generados y versionados
assets/catalog/manifest.json       ← v2: version, canal, firma, checksum
lib/core/design_system/generated/  ← design_tokens.dart, skin_tokens_*.dart
lib/features/skins/data/generated/ ← screens.g.dart, profiles.g.dart
lib/platform/catalog/              ← cliente firmado, caché, rollback (ADR-0010)
lib/platform/dev_skin/             ← puente debug (heredado v1)
lib/platform/audio/                ← SoundPlayer aislado (ADR-0008)
lib/features/calculator/domain/    ← VariableNode + evaluate(variables) (ADR-0009)
```

**Regla de oro**: la herramienta y el catálogo producen datos validados; el motor y el renderer son los únicos que interpretan esos datos. Un catálogo nunca altera la lógica de cálculo, los precios ni los entitlements.

## Contrato de datos (semilla v2)

`design/app.design.json` se crea con esta semilla. Los tokens de `lcd_classica` son idénticos al manifiesto actual; la skin `default` replica el ámbar del MVP pero con `keyMinHeight: 48` para cumplir el validador.

```json
{
  "schemaVersion": 2,
  "version": 1,
  "channels": ["prod", "beta"],
  "skins": [
    {
      "id": "default",
      "nameKey": "skinDefaultName",
      "isDefault": true,
      "tokens": {
        "segmentOn": "#FFB000",
        "displayBackground": "#1E1B12",
        "displayBorder": "#3A3320",
        "displayRadius": 8,
        "displayPaddingHorizontal": 16,
        "displayPaddingVertical": 12,
        "digitWidth": 26,
        "digitHeight": 48,
        "keyBackground": "#E8D9A0",
        "keyForeground": "#1E1B12",
        "keyBorder": "#3A3320",
        "keyRadius": 6,
        "keyPadding": 3,
        "keyMinHeight": 48,
        "screenPadding": 12,
        "keyboardHeight": 380
      },
      "images": ["fondo_panel"]
    },
    {
      "id": "lcd_classica",
      "nameKey": "skinLcdClassicaName",
      "isDefault": false,
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
      },
      "images": []
    }
  ],
  "images": [
    {
      "id": "fondo_panel",
      "file": "fondo_panel.png",
      "format": "png",
      "maxWidth": 2048,
      "maxHeight": 2048,
      "checksum": "RELLENAR_POR_EL_COMPILER"
    }
  ],
  "screens": {
    "normal": {
      "mobile": [{"type": "padding", "value": 12, "child": {"type": "display", "key": "calc.display"}}, {"type": "errorText", "when": "hasError"}, {"type": "sizedBox", "height": 380, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}, {"type": "skinSelector"}],
      "tablet": [{"type": "padding", "value": 16, "child": {"type": "display", "key": "calc.display"}}, {"type": "errorText", "when": "hasError"}, {"type": "sizedBox", "height": 420, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}, {"type": "skinSelector"}],
      "desktop": [{"type": "padding", "value": 20, "child": {"type": "display", "key": "calc.display"}}, {"type": "errorText", "when": "hasError"}, {"type": "sizedBox", "height": 460, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}, {"type": "skinSelector"}]
    },
    "scientific": {
      "mobile": [{"type": "padding", "value": 12, "child": {"type": "display", "key": "calc.display"}}, {"type": "row", "alignment": "center", "when": "isScientific", "children": [{"type": "angleChip", "key": "calc.toggle.angle"}]}, {"type": "sizedBox", "height": 380, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}],
      "tablet": [{"type": "padding", "value": 16, "child": {"type": "display", "key": "calc.display"}}, {"type": "row", "alignment": "center", "when": "isScientific", "children": [{"type": "angleChip", "key": "calc.toggle.angle"}]}, {"type": "sizedBox", "height": 420, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}],
      "desktop": [{"type": "padding", "value": 20, "child": {"type": "display", "key": "calc.display"}}, {"type": "row", "alignment": "center", "when": "isScientific", "children": [{"type": "angleChip", "key": "calc.toggle.angle"}]}, {"type": "sizedBox", "height": 460, "child": {"type": "keyboard", "key": "calc.keyboard"}}, {"type": "history", "titleKey": "historyTitle"}]
    },
    "selector": {
      "mobile": [{"type": "skinSelector"}],
      "tablet": [{"type": "skinSelector"}],
      "desktop": [{"type": "skinSelector"}]
    }
  },
  "profiles": [
    {"id": "normal", "labelKey": "modeNormal", "capabilityId": "basic", "isScientific": false, "defaultAngleMode": "degrees", "decimalDigits": 8, "inputs": [], "formulas": {}, "keyRows": [["C", "?", "%", "/"], ["7", "8", "9", "*"], ["4", "5", "6", "-"], ["1", "2", "3", "+"], ["±", "0", ".", "="]]},
    {"id": "scientific", "labelKey": "modeScientific", "capabilityId": "scientific", "isScientific": true, "defaultAngleMode": "degrees", "decimalDigits": 8, "inputs": [], "formulas": {}, "keyRows": [["sin(", "cos(", "tan(", "(", ")"], ["ln(", "log(", "√", "^", "!"], ["pi", "e", "%", "C", "?"], ["7", "8", "9", "/", "*"], ["4", "5", "6", "-", "+"], ["1", "2", "3", "±", "="], ["0", ".", "MC", "MR", "M+"]]},
    {"id": "igv", "labelKey": "modeIgv", "capabilityId": "basic", "isScientific": false, "defaultAngleMode": "degrees", "decimalDigits": 2, "inputs": ["base", "tasa"], "formulas": {"resultado": "base * (1 + tasa / 100)"}, "keyRows": [["7", "8", "9", "C"], ["4", "5", "6", "?"], ["1", "2", "3", "="], ["0", ".", "tasa", "base"]]}
  ],
  "dimensions": {"minTouchTarget": 48, "breakpoints": {"mobile": 0, "tablet": 600, "desktop": 1024}},
  "sounds": {"enabled": true, "events": {"keyTap": "key_tap.wav", "equals": "equals.wav", "error": "error.wav", "skinChange": "skin_change.wav"}},
  "monetization": {
    "ads": {"type": "rewarded", "enabled": true, "theme": {"buttonBackground": "#FFB000", "buttonForeground": "#1E1B12", "copyKey": "adsRewardCopy"}},
    "catalog": {"productIds": {"skinLcdClassica": "skin_lcd_classica", "calculatorPro": "calculator_pro_30d", "subscriptionMonthly": "retro_calculator_monthly", "subscriptionYearly": "retro_calculator_yearly"}, "priceCopyKeys": {"skin": "priceSkin", "calculator": "priceCalculator", "monthly": "priceMonthly", "yearly": "priceYearly"}}
  },
  "publishing": {"channel": "prod", "baseUrl": "https://catalog.example.com/retro", "publicKey": "RELLENAR_CON_LA_CLAVE_PUBLICA_FIJADA"}
}
```

> **Corrección ADR-0012:** las siete claves ARB nuevas van en camelCase (`skinDefaultName`, `modeIgv`, `adsRewardCopy`, `priceSkin`, `priceCalculator`, `priceMonthly`, `priceYearly`) porque `flutter gen-l10n` rechaza los puntos en los nombres de recurso. Se añaden a los cinco ARB (44 → 51) y se actualiza `arb_keys_test.dart`. Los cinco assets referenciados existen como placeholders versionados en `design/assets/`; V6 y V10 los regeneran con el mismo nombre.

**Whitelist de nodos**: `padding`, `display`, `errorText`, `row`, `column`, `sizedBox`, `keyboard`, `key`, `image`, `history`, `skinSelector`, `angleChip`. Cualquier otro tipo se rechaza. Las keys de test (`calc.display`, `calc.key.*`, `calc.toggle.*`, `skin.option.*`) se conservan.

**Textos**: toda etiqueta visible usa clave ARB (`nameKey`, `labelKey`, `titleKey`, `copyKey`, `priceCopyKeys`). No hay literales en el diseño (ADR-0005).

## Validación

`validate.dart` falla con mensaje accionable si:

- Faltan tokens, un color no es `#RRGGBB`, contraste < 4.5:1 o `keyMinHeight < 48`.
- No hay exactamente una skin con `isDefault: true`.
- Un nodo no está en la whitelist o una clave ARB no existe en los tres ARB.
- Un `capabilityId` no está en `CapabilityRegistry`.
- Una fórmula tiene sintaxis inválida, variable no declarada, función no permitida, recursión o supera el presupuesto de pasos.
- Un evento de sonido o una imagen referencia un archivo inexistente, o la imagen excede dimensiones/tamaño.
- `ads.type != 'rewarded'`, o el diseño intenta declarar precios/entitlements.
- Un breakpoint no es `mobile`/`tablet`/`desktop` o `minTouchTarget != 48`.

## Slices y tareas

Orden de ejecución: **V0 → V1 → V2 → V3 → V4 → V5 → V6 → V7 → V8 → V9 → V10 → V11**. No despachar implementers en paralelo sobre los mismos archivos. Plataforma activa: Android; restaurar `windows/flutter/` tras cada `flutter pub get`.

### V0 — Spike de la base Dart (T1–T4)

- [ ] **T1 — Criterios del spike.** Documentar en `docs/design/spike-fluttercanvas.md`: arrastrar desde paleta, mover/redimensionar, capas, undo/redo, serialización JSON estable y nodos whitelist. Timebox: 1 día.
- [ ] **T2 — Probar `fluttercanvas`.** Añadirlo como `dev_dependency` y ejecutar su ejemplo en `tool/spike/`. Registrar API real y versiones. Tras `flutter pub get`: `git restore -- windows/flutter/`.
- [ ] **T3 — Adaptador mínimo.** `tool/design/adapters/fluttercanvas_to_design.dart`: convertir un nodo del canvas a `ScreenSpec` y confirmar que `SpecRenderer` lo dibuja igual. No usar el exportador Dart del paquete.
- [ ] **T4 — Gate.** Si falla cualquier criterio, sustituir por canvas propio (`GestureDetector` + `CustomPainter`) con el mismo contrato; actualizar `docs/design/spike-fluttercanvas.md`. No forkar Penpot/Figma.

### V1 — Semilla y validador v2 (T5–T10)

- [ ] **T5 — Semilla.** Crear `design/app.design.json` con el JSON de arriba, LF canónico y tokens idénticos a los de la LCD clásica. Verificar: `ConvertFrom-Json`/`jsonDecode` válido; 2 skins, 3 pantallas × 3 breakpoints, 3 perfiles, 16 tokens por skin.
- [ ] **T6 — `schema.dart` v2.** Modelos tipados para skins, imágenes, pantallas, perfiles, fórmulas, dimensiones, sonidos, monetización y publicación.
- [ ] **T7 — Validador.** Reutilizar `validateTokens`, `colorKeys` y `minValues` de `token_validation.dart` para no duplicar reglas. Añadir las validaciones de la sección anterior.
- [ ] **T8 — CLI.** `dart run tool/design/validate.dart [archivo]` → `✓ válido` o errores numerados con ruta JSON.
- [ ] **T9 — Tests rojo/verde.** `test/unit/design/validate_test.dart`: contraste, 44 dp, nodo desconocido, ARB faltante, `ads.type` inválido, fórmula rota, imagen inexistente.
- [ ] **T10 — Skin default.** Test que exige exactamente una skin default y que sus tokens pasan `validateTokens`; documentar el cambio 44 → 48 dp y actualizar goldens afectados.

### V2 — Compiler v2 (T11–T15)

- [ ] **T11 — Generador de skins.** Refactorizar `tool/skins/generate.dart` para iterar todas las skins del diseño; conservar el checksum de `lcd_classica` (`26d270cf…bc77aa`) y generar `SkinTokens.generatedDefault`.
- [ ] **T12 — Artefactos.** Emitir `design_tokens.dart`, `screens.g.dart`, `profiles.g.dart`, `images.g.dart`, `sounds.g.dart`; `dart format` sobre cada uno.
- [ ] **T13 — Manifiesto v2.** `version`, `channel`, `entries`, `assets`, `signature`. `definition: path`, LF canónico, checksum calculado sobre la definición estable.
- [ ] **T14 — Idempotencia.** Dos ejecuciones consecutivas sin diff; `git diff --exit-code` sobre artefactos generados.
- [ ] **T15 — Compatibilidad.** `SkinRepository` usa la skin generada; `SkinTokens.classicAmber` queda como alias temporal para no romper tests heredados.

### V3 — `SpecRenderer` y preview compartido (T16–T20)

- [ ] **T16 — Renderer.** `lib/core/widgets/spec_renderer.dart` con la whitelist de nodos; sin `eval` ni `Function.apply`.
- [ ] **T17 — Keys.** Preservar `calc.display`, `calc.key.*`, `calc.toggle.angle`, `skin.option.*` para que los tests widget heredados sigan pasando.
- [ ] **T18 — Migración.** `calculator_page.dart` y el selector renderizan desde `ScreenSpec`; `calculator_keyboard.dart` y `seven_segment_display.dart` siguen consumiendo tokens.
- [ ] **T19 — Tests.** `test/unit/design/spec_renderer_test.dart`: cada nodo, condición `when`, y rechazo de tipo desconocido.
- [ ] **T20 — Goldens.** 9 goldens (3 pantallas × 3 breakpoints) con `--update-goldens` revisado en el PR.

### V4 — Editor visual (T21–T28)

- [ ] **T21 — Shell.** Entrypoint `tool/design/studio/main.dart` (ADR-0014; `flutter run -t tool/design/studio/main.dart`): paleta, canvas, capas, inspector, selector de breakpoint, botones Guardar/Validar/Compilar/Publicar.
- [ ] **T22 — Drag & drop.** Arrastrar un nodo de la paleta al canvas crea un `ScreenSpec` válido; feedback visual inmediato.
- [ ] **T23 — Move/resize.** Manillas, snapping y límites; `keyMinHeight` nunca baja de 48 dp.
- [ ] **T24 — Capas.** Reordenar, ocultar y bloquear nodos; sincronizado con el árbol del spec.
- [ ] **T25 — Inspector.** Campos generados desde `colorKeys`/`minValues` y propiedades del nodo; edición de fórmula con validación en vivo.
- [ ] **T26 — Undo/redo.** Pila de snapshots del documento; atajos de teclado.
- [ ] **T27 — Aplicar.** Adaptador → JSON → `validate.dart` → `compile.dart`; errores se muestran en el panel sin escribir archivos inválidos.
- [ ] **T28 — Persistencia.** Guardar/Recargar con LF canónico; botón «Ver en preview» usa el mismo `SpecRenderer`.

### V5 — Fórmulas declarativas (T29–T34)

- [x] **T29 — `VariableNode`.** Ampliar `ast.dart` y `parser.dart`; el lexer acepta identificadores declarados.
- [x] **T30 — Evaluador.** `evaluate(String expression, {Map<String, num> variables})` con presupuesto de pasos y profundidad máxima.
- [x] **T31 — Tests del motor.** `2+3=5` sigue igual; `base*(1+tasa/100)` con `base=100, tasa=18` da 118; variable no declarada falla con `unknownVariable`.
- [x] **T32 — Editor de fórmulas.** Autocompletado de `inputs` y funciones permitidas; botón «Probar» con valores de ejemplo.
- [x] **T33 - Validación build-time.** El compiler parsea todas las fórmulas y rechaza las inválidas antes de emitir artefactos.
- [ ] **T34 — Validación runtime.** Al aplicar un catálogo, una fórmula inválida se descarta y se conserva el perfil anterior; nunca bloquea la calculación normal.

### V6 — Imágenes (T35–T39)

- [x] **T35 — Importación.** Método `importImage` en el Studio (valida PNG, calcula SHA-256/dimensiones y añade `ImageSpec`).
- [x] **T36 — Validación.** SHA-256 y dimensiones con `crypto` + parser PNG; rechazo > 2048 px o peso excesivo.
- [x] **T37 — Artefactos.** `images.g.dart` con rutas y checksums (emitido por `compile.dart`).
- [x] **T38 — Nodo `image`.** `SpecRenderer` ya resuelve el nodo `image`.
- [ ] **T39 — Idempotencia.** Regenerar imágenes dos veces sin diff; test de checksum y de rechazo de archivo inexistente.

### V7 — Publicación y app instalada (T40–T48)

- [x] **T40 — Paquete.** `tool/design/publish.dart` construye el directorio del canal con manifiesto, assets y versión incrementada.
- [ ] **T41 — Firma.** Ed25519 con `cryptography`; clave pública fijada en `lib/platform/catalog/public_key.dart`. La clave privada nunca entra al repo: se lee de un secreto.
- [x] **T42 — CLI de publicación.** `dart run tool/design/publish.dart --channel prod` y `--rollback <version>`; imprime versión y checksum.
- [ ] **T43 — Hosting estático.** Subida por canal a hosting estático; sin backend stateful. Documentar URL base y permisos.
- [ ] **T44 — Cliente.** `lib/platform/catalog/catalog_client.dart`: fetch, verifica firma y checksum, valida con las mismas reglas, cachea la última versión buena.
- [ ] **T45 — Aplicación.** `CatalogController` inyecta tokens, perfiles, imágenes, sonidos y tema de anuncios; usa `SkinScope(tokensOverride:)` y el registro de capacidades.
- [ ] **T46 — Sondeo.** Al iniciar y periódicamente; opción solo WiFi; sin bloquear el arranque.
- [ ] **T47 — Fallos.** Test de rollback: manifiesto corrupto, firma inválida y red caída conservan la versión local; la app sigue calculando.
- [ ] **T48 — Feedback.** Indicador discreto «Catálogo vN aplicado» y registro de errores sin exponer datos sensibles.

### V8 — Perfiles y capacidades heredado (T49–T54)

- [x] **T49 — Perfil id `String`.** Migrar `CalculatorProfileId`, `isScientific` como flag y `HistoryEntry.fromJson` con fallback a `'normal'`.
- [x] **T50 — `CapabilityRegistry`.** Registro inmutable con `basic` y `scientific`.
- [x] **T51 — `profiles.g.dart`.** Generado desde `profiles[]` por el compiler.
- [x] **T52 — Scaffolding.** `tool/design/new_capability.dart <id>` crea capability + test rojo.
- [ ] **T53 — Pestaña Calculadoras.** Lista de perfiles, campos y botón «Nueva calculadora»; `capabilityId` solo del registro.
- [x] **T54 — Sin regresión.** `flutter test` sobre `engine/` y `capabilities/`: tests en verde.

### V9 — Tamaño y skin por defecto (T55–T57)

- [ ] **T55 — Pestaña Tamaño.** Tokens de shell y breakpoints; 48 dp innegociable validado en vivo.
- [ ] **T56 — Default generado.** `SkinRepository.remote` usa la skin `isDefault`; quitar la dependencia de `classicAmber` fuera del alias temporal.
- [ ] **T57 — Goldens.** Actualizar los 9 goldens por el cambio 44 → 48 dp y por el fondo de la skin default.

### V10 — Sonidos y monetización visual (T58–T62)

- [ ] **T58 — Sonidos heredado.** `audioplayers` aislado; `SoundPlayer` + adaptador; 4 WAV deterministas con `tool/sounds/generate.dart`. Restaurar `windows/flutter/` tras `pub get`.
- [ ] **T59 — Eventos.** `keyTap`, `equals`, `error`, `skinChange` detrás de `sounds.enabled`; fallo de audio nunca retrasa ni altera el cálculo.
- [ ] **T60 — Tema de anuncios.** Validar `ads.type == 'rewarded'` y los colores del botón con el mismo validador de contraste.
- [ ] **T61 — Vista de monetización.** Previsualización del botón y de los textos por clave ARB; product IDs visibles como dato.
- [ ] **T62 — Límite.** Test que demuestra que el catálogo no puede cambiar precios, entitlements ni el tipo de anuncio.

### V11 — CI, documentación y cierre (T63–T67)

- [ ] **T63 — CI.** Añadir a `.github/workflows/android-ci.yml`: validar, compilar, generar sonidos/imágenes y exigir `git diff --exit-code`; fallar si hay archivos nuevos no trackeados.
- [ ] **T64 — Goldens.** Revisión de capturas en el PR; `--update-goldens` solo cuando el cambio de diseño es intencional.
- [ ] **T65 — Documentación.** `docs/design/README.md`: esquema v2, whitelist, spike, editor, fórmulas, imágenes, sonidos, publicación, rollback, comandos, mockups y regla «el diseño nunca contiene lógica de cálculo».
- [ ] **T66 — Verificación final.** `flutter analyze`, `flutter test`, `dart format --output=none --set-exit-if-changed lib test tool`, generadores idempotentes, `git check-attr eol`, `git restore -- windows/flutter/`.
- [ ] **T67 — PR.** Título en inglés y cuerpo en español con módulos tocados y validaciones ejecutadas; PR a `main`, nunca commit directo.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| `fluttercanvas` v0.3.0 inmaduro o con API inestable | Spike con timebox y criterios de abort (T1–T4); fallback a canvas propio con el mismo contrato; nunca forkar Penpot |
| Dos renderers divergentes | El exportador Dart del paquete no se usa; preview y app comparten `SpecRenderer` |
| Catálogo remoto altere el cálculo o la monetización | Fórmulas parseadas, sin `eval`; validación en build-time y runtime; precios/entitlements fuera del catálogo (ADR-0006, ADR-0009, ADR-0010) |
| Firma/checksum mal gestionados | Clave privada en secreto, pública fijada en la app; rollback a última versión válida; tests de corrupción |
| Imágenes pesadas o corruptas | Límites de dimensión/peso, SHA-256 y validación con `image` en la herramienta |
| Audio o publicación bloqueen la app | Todo cosmético y asíncrono; fallos ignorados; la calculadora funciona sin catálogo |
| Cambio 44 → 48 dp del default | Goldens actualizados y revisados; test de `minTouchTarget` |
| Artefactos nativos de Windows | Restaurar `windows/flutter/` tras cada `flutter pub get` mientras la fase activa sea Android |
| LF roto por el editor | `jsonEncode` + `\\n` al escribir; `git check-attr eol` en CI |

## Criterios de aceptación

1. `design/app.design.json` es la única fuente de verdad; contiene skin default generada, imágenes, fórmulas, sonidos, monetización visual y publicación.
2. El Studio permite arrastrar nodos, editar capas/props en el inspector, deshacer y aplicar cambios con un botón; el preview usa el mismo renderer que la app.
3. `dart run tool/design/validate.dart` y `dart run tool/design/compile.dart` son idempotentes y no cambian el checksum de `lcd_classica`.
4. Las fórmulas se envían desde la herramienta, se validan antes de publicar y antes de aplicar; nunca se ejecuta código del catálogo.
5. Una app ya instalada recibe una nueva versión del catálogo, la verifica y la aplica; si falla, conserva la última válida.
6. El editor configura colores/texto del anuncio recompensado, pero no precios, entitlements ni anuncios no recompensados.
7. Imágenes y sonidos son assets locales versionados, validados y cosméticos.
8. `flutter analyze` 0 issues; `flutter test` 44 + nuevos; formato 0 cambios; CI verde; PR a `main`.

## Comandos de verificación

```bash
dart run tool/design/validate.dart
dart run tool/design/compile.dart
dart run tool/design/compile.dart && git diff --exit-code
dart run tool/sounds/generate.dart && git diff --exit-code -- assets/sounds
dart run tool/design/publish.dart --channel beta
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test tool
git check-attr eol -- design/app.design.json tool/skins/definitions/lcd_classica.yaml
git status --short
```

Puente local (solo debug):

```bash
dart run tool/design/serve.dart
curl http://127.0.0.1:8787/health
flutter run -d emulator-5554 --flavor prod \
  --dart-define=DEV_SKIN_URL=http://10.0.2.2:8787/skin
```

**El flavor es obligatorio**: sin `--flavor prod`, Gradle genera el APK con sufijo y Flutter no encuentra `app-debug.apk`.

Criterio final: analyze 0 issues; tests 44 + nuevos; formato 0 cambios; generadores idempotentes; `eol: lf`; worktree limpio tras restaurar `windows/flutter/`; el editor publica una versión y la app instalada la aplica sin recompilar.
