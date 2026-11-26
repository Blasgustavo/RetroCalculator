---
name: flutter-standards
description: >
  Define las convenciones Flutter de RetroCalculator: Clean Architecture + MVVM, estructura
  lib/core, lib/data, lib/features, lib/platform, design system retro, tests con flutter
  analyze/flutter test y la regla de que el motor de cálculo no depende de Flutter.
  Trigger: escribir o revisar código Dart, crear archivos en lib/, decidir dónde va una clase.
auto_invoke: Flutter, Dart, Clean Architecture, MVVM, design system, flutter analyze, flutter test, widget, motor de cálculo, nueva clase
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 6, last_used: "2026-11-26", success_rate: 1.0 }
  dependencies: []
  status: active
  category: flutter
---

## TL;DR

Antes de escribir Dart, cargar este skill. El motor vive en `lib/features/calculator/domain/` y es Dart puro (sin `package:flutter/*`, sin `BuildContext`, sin `eval`). Las skins solo cambian `lib/core/design_system/`. Los plugins nativos solo se importan desde `lib/platform/`. Verificar siempre con `flutter analyze` y `flutter test`.

## Purpose

Fijar una única estructura para que calculadora, skins, monetización y plataformas no se mezclen. Permite que el mismo equipo (o subagentes distintos) trabaje en paralelo sin pisarse y que la calculadora siga siendo gratuita y funcional incluso sin backend ni anuncios.

## When to Use

- Crear cualquier archivo bajo `lib/` o `test/`.
- Añadir una operación científica, un widget, un repositorio o un adaptador nativo.
- Revisar un diff antes de pedir `spec reviewer`/`quality reviewer`.
- Definir tokens de color/tipografía del tema retro.

## Critical Patterns

1. **Estructura y responsabilidades**

   ```text
   lib/
   ├── main.dart                 # entry point + errores globales
   ├── app.dart                  # MaterialApp + tema + rutas
   ├── config/                   # routes.dart, theme/
   ├── core/
   │   ├── design_system/        # colores, tipografía, spacing, radius, sombras
   │   ├── widgets/              # display, teclado, botones reutilizables
   │   ├── utils/ errors/ constants/
   ├── data/
   │   ├── models/ repositories/ services/ local/
   ├── features/
   │   ├── calculator/
   │   │   ├── domain/           # parser, evaluador, científicas  ← SIN Flutter
   │   │   ├── data/
   │   │   └── presentation/     # normal/científico, ViewModels, widgets
   │   ├── skins/
   │   │   ├── domain/           # Skin, Entitlement (contrato)
   │   │   ├── data/             # catálogo, repositorio
   │   │   └── presentation/     # tienda, preview, cuenta atrás
   │   ├── monetization/
   │   │   ├── ads/ iap/ entitlements/
   │   └── settings/
   └── platform/                 # adaptadores Android / Windows / iOS
   ```

   Tests espejo: `test/unit/calculator/`, `test/unit/monetization/`, `test/widget/`, `test/integration/`.

2. **Regla de oro del motor (Dart puro)**

   ```dart
   // lib/features/calculator/domain/evaluator.dart
   // ✅ correcto: solo dart:core, sin Flutter, sin UI
   class Evaluator {
     double evaluate(String expression) { /* parser propio, sin eval */ }
   }
   ```

   ```dart
   // ❌ incorrecto en domain/
   import 'package:flutter/material.dart';
   import 'package:shared_preferences/shared_preferences.dart';
   ```

   La UI de `presentation/` llama al `ViewModel`, el `ViewModel` llama al `domain/`; nunca al revés.

3. **Clean + MVVM en la feature calculator**

   - `domain/`: entidades y casos de uso (`EvaluateExpression`, `ToggleAngleMode`).
   - `data/`: implementaciones de repositorio (historial, preferencias).
   - `presentation/`: `CalculatorViewModel` con `ChangeNotifier` o el patrón elegido, expone `display`, `mode`, `memory`; el widget solo escucha y envía eventos (`onKeyPressed`).
   - Comando: `flutter test test/unit/calculator/` y `flutter test test/widget/`.

4. **Skins y monetización sin contaminar el cálculo**

   - Una skin es cosmética: paleta, tipografía, textura y sonido eventual; **no añade operaciones de pago**.
   - La skin se aplica desde `lib/core/design_system/`; el resultado de `Evaluator` no cambia con el tema.
   - `Entitlement` se valida en `lib/features/monetization/entitlements/` con `expiresAt`; la UI consume `isActive` y muestra la cuenta atrás.
   - Solo anuncios recompensados, voluntarios y con recompensa explícita: prohibidos banners e intersticiales.
   - El motor nunca consulta si hay entitlement: calcular siempre funciona.

5. **Plataforma**

   - `lib/platform/` expone una interfaz (`RewardedAdService`, `BillingService`) y adaptadores por plataforma; el resto del código importa la interfaz, nunca el plugin directo.
   - Orden: Android (AdMob + Play Billing) → Windows (sin AdMob/IAP móvil) → iOS (ATT, privacy manifest, IAP de App Store).
   - Builds: `flutter build apk --release`, `flutter build windows`, `flutter build ios`.

6. **Dependencias de herramientas confinadas a `tool/` (verificado el 2026-11-25)**

   Las librerías de edición visual (por ejemplo `fluttercanvas` 0.3.0) se declaran como `dev_dependencies` y **solo se importan desde `tool/`**; nunca desde `lib/`. Su modelo es un formato de autoría temporal: un adaptador con whitelist *deny-by-default* lo convierte a nuestro esquema (`design/app.design.json`), rechazando tipos sin mapeo o con código incrustado. No se usa el renderer ni el exportador Dart del paquete en la app: el preview y la app comparten nuestro renderer, aunque llegue en un slice posterior. Verificado en V0 del Studio con `flutter analyze` 0 issues, 44/44 tests y 8/8 tests del spike.

7. **Compiladores de diseño: validar antes de escribir y ser idempotente (verificado el 2026-11-25)**

   Los artefactos generados desde `design/app.design.json` salen de una única fuente de verdad con un gate previo: `dart run tool/design/compile.dart` valida con `validate.dart`/`schema.dart` y **no escribe nada** si la semilla es inválida. La salida es determinista: LF canónico antes de calcular el SHA-256 (mismo bytes en Windows, macOS y CI Linux) y cabecera `// GENERADO: ... No editar a mano.`; dos ejecuciones consecutivas deben dar `git diff --exit-code` limpio. En una migración de formato, el manifiesto v1 que ya consume la app queda intacto y el v2 se emite como archivo nuevo (`manifest.v2.json`); la migración del cliente y del skin default se programa en un slice posterior, con `SkinTokens.generatedDefault` añadido de forma aditiva hasta entonces. `signature` se documenta vacío mientras no exista la clave: nunca se versiona material privado. Verificado en V2 del Studio con 61/61 tests, `flutter analyze` 0 issues y compile idempotente.

8. **Verificación obligatoria**

   ```bash
   flutter pub get
   flutter analyze          # cero issues nuevos
   flutter test             # unit + widget + integration
   flutter test --coverage  # cobertura del motor y entitlements
   dart format lib test     # formato consistente
   ```

9. **Renderer de specs y goldens deterministas (verificado el 2026-11-25)**

   Un renderer que consume `screenSpecs` vive en `lib/core/widgets/` y **no importa `features/`**: recibe un contexto inyectado (`tokens`, display, filas de teclas, callbacks, condición `when`) para evitar dependencias inversas. La whitelist de nodos es deny-by-default y las keys heredadas (`calc.display`, `calc.key.*`, `calc.toggle.angle`, `skin.option.*`) se preservan en el renderer o en los widgets inyectados. Los goldens se generan en el **entorno canónico de CI (Ubuntu + Flutter 3.44)**: fijar fuente `Ahem`, `devicePixelRatio = 1.0`, escala de texto y texto ASCII no basta para que Windows y Linux rastericen igual; los PNG creados en Windows fallaron en Linux con diferencias de 0,27 % a 1,03 %. Regenerar con `flutter test --update-goldens` en Linux, verificar que CI quede en verde y no esperar que los mismos PNG pasen en Windows. Verificado en V3 del Studio: 78/78 tests, 9 goldens regenerados en Linux y `Analyze and test` en verde.

10. **Ejecución en Android con flavors (verificado el 2026-11-24)**

   El proyecto declara flavors Android `dev`, `staging` y `prod` en `android/app/build.gradle.kts`. Sin `--flavor`, `flutter run` genera `app-dev-debug.apk`, `app-staging-debug.apk` y `app-prod-debug.apk`, pero Flutter busca `app-debug.apk` y falla con `Gradle build failed to produce an .apk file`. No es un error de Dart ni del emulador.

   ```bash
   flutter devices                      # identificar el id del emulador
   flutter run -d emulator-5554 --flavor prod
   ```

   Con `flutter pub get` en este entorno se regeneran `windows/flutter/generated_plugin_registrant.{cc,h}` y `generated_plugins.cmake`. Windows es fase 2 (ADR-0002): restaurarlos con `git restore -- windows/flutter/` antes de committear. El usuario validó manualmente el MVP en Android con este comando el 2026-11-24: `2 + 3 = 5`, modo científico e historial global.

11. **Studio: aplicar y persistir son operaciones distintas (verificado el 2026-11-26)**

    `Aplicar` es el único gate que serializa, valida con `validate.dart` y compila: si hay issues no escribe nada. `Guardar` solo persiste el JSON canónico (LF y un único `\n` final); `Recargar` sustituye el documento con `loadDocument`, limpia historial y descarta el feedback de `Aplicar` del documento anterior. Los módulos de herramienta bajo `tool/design/studio/` que serializan o escriben son Dart puro: toman la ruta por defecto de `compile.dart` (`defaultDesignPath`) y nunca importan `studio_controller.dart`, porque arrastra Flutter y crea un ciclo innecesario. El feedback de validar/aplicar/guardar/recargar queda fuera del snapshot de undo (ADR-0015). El preview usa `SpecRenderer` con `currentSpec`, sin aplicar el filtro de nodos ocultos del editor. Verificado en V4 T27/T28: 156/156 y 169/169 en unit+widget, `flutter analyze` 0 issues y CI Linux en verde.

12. **Studio V1: semilla única, validación compartida y ARB camelCase (verificado el 2026-11-25, confirmado el 2026-11-26)**

    `design/app.design.json` es la única fuente de verdad y `dart run tool/design/validate.dart [archivo]` responde `✓ válido` o errores numerados con ruta JSON. El validador reutiliza `validateTokens`, `colorKeys` y `minValues` de `token_validation.dart` en lugar de duplicar las reglas de contraste y 48 dp. Las claves ARB van en camelCase porque `flutter gen-l10n` rechaza puntos (ADR-0012), y los cinco assets referenciados por la semilla se versionan como placeholders para que la validación de existencia sea real. `default` usa `keyMinHeight: 48` mientras `SkinTokens.classicAmber` sigue en 44 y los goldens se difieren a V9: la migración visual no se adelanta al slice que la valida. Verificado en V1 del Studio (PR #10): 56/56 tests, `flutter analyze` 0 issues, `dart format` sin cambios y `✓ válido`.

## Commands

```bash
# Estructura y análisis
find lib -type d | sort
flutter analyze
dart format --output=none --set-exit-if-changed lib test

# Tests por capa
flutter test test/unit/calculator/
flutter test test/unit/monetization/
flutter test test/widget/
flutter test --coverage

# Builds por plataforma (en su fase)
flutter build apk --release
flutter build windows
flutter build ios --no-codesign
```

## Anti-Patterns

- Importar `package:flutter/*` en `lib/features/calculator/domain/`.
- Usar `eval`, `dart:mirrors` o un paquete externo para evaluar la expresión.
- Meter la lógica de cálculo en un `StatefulWidget` o en el `ViewModel`.
- Hacer que una skin desbloquee el modo científico o cambie el resultado.
- Llamar a AdMob, Google Play Billing o complementos nativos desde `presentation/` sin pasar por `lib/platform/`.
- Añadir banners o intersticiales, o exigir un anuncio para calcular.
- Commitear sin `flutter analyze` y `flutter test` en verde.
- Ejecutar `flutter run` en Android sin `--flavor` cuando el proyecto declara flavors: genera tres APK con nombre distinto y Flutter no encuentra `app-debug.apk`.
- Commitear artefactos Windows regenerados por `pub get` en una rama Android-first.
- Importar `features/` desde `lib/core/widgets/` en un renderer compartido.
- Versionar goldens generados en Windows y darlos por válidos porque pasan localmente: la fuente canónica es CI Linux; regenerar allí y exigir `Analyze and test` en verde.
- Generar artefactos con CRLF en Windows o calcular el checksum después de escribir: el SHA-256 cambia entre plataformas y rompe la idempotencia.
- Hacer que Guardar valide/compile o que Aplicar escriba sin pasar por `validate.dart`: son flujos distintos del Studio.
- Importar `studio_controller.dart` desde un módulo de persistencia/serialización bajo `tool/` para reutilizar una constante: usar `defaultDesignPath` de `compile.dart` y mantener el módulo Dart puro.
- Conservar `lastApplyResult` tras Recargar o meter el feedback de validar/aplicar/guardar/recargar en el historial de undo.
- Usar puntos en claves ARB (flutter gen-l10n las rechaza) o referenciar assets no versionados y relajar la validación de existencia para que pase el CLI.
- Duplicar en el validador del Studio las reglas de tokens/contraste que ya están en `token_validation.dart`.
- Reemplazar en un slice de migración un manifiesto o una skin que ya consume la app: emitir el formato nuevo en paralelo y migrar al cliente en su slice.
- Copiar convenciones de NestJS, Angular, Leaflet o del dominio FieldOps de ElectroSys.

## Related Skills

- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — tests primero para motor y entitlements.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — analyze + test antes de reportar.
- [writing-plans](../../../.opencode/skills/writing-plans/SKILL.md) — planes que respetan esta estructura.
- [adr-recorder](../../../.opencode/skills/adr-recorder/SKILL.md) — decisiones que fijan el diseño retro y las plataformas.
- [systematic-debugging](../../../.opencode/skills/systematic-debugging/SKILL.md) — aislamiento por capa cuando falla algo.
