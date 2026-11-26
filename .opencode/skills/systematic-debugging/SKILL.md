---
name: systematic-debugging
description: >
  Investiga errores de RetroCalculator buscando la causa raíz antes de proponer parches:
  reproducir, aislar la capa (domain/data/presentation/platform), formar hipótesis,
  escribir un test de regresión y verificar con flutter test/analyze. Trigger: cualquier
  error, bug, test rojo, regresión o comportamiento inesperado.
auto_invoke: error, bug, debug, root cause, regresión, test falla, no funciona, excepción, crash
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 2, last_used: "2026-11-25", success_rate: 1.0 }
  dependencies: [verification-before-completion, test-driven-development, flutter-standards]
  status: active
  category: testing
---

## TL;DR

Reproducir → aislar → hipótesis → test de regresión (rojo) → fix mínimo → verificación completa. Nunca se parchea un síntoma sin saber por qué ocurre.

## Purpose

Evitar "fixes" que esconden el problema. En RetroCalculator los fallos suelen venir de precedencia del parser, de un `Entitlement` que expira mal, de un plugin nativo llamado desde la UI o de una skin que altera el motor. Cada capa tiene una causa distinta y un sitio distinto para el test.

## When to Use

- `flutter test` falla y no está claro por qué.
- La app muestra `20` donde debiera mostrar `14` (`2 + 3 * 4`).
- Una skin sigue activa después de su expiración o vuelve el tema gratuito antes de tiempo.
- Un anuncio recompensado termina pero no se otorga la recompensa.
- Un build de Android/Windows/iOS rompe tras un cambio en `lib/platform/`.

## Critical Patterns

1. **Secuencia de investigación**

   ```text
   1. Reproducir: comando o pasos exactos + salida real.
   2. Localizar capa: domain (cálculo) / data (persistencia) /
      presentation (UI) / platform (plugins nativos).
   3. Hipótesis: "creo que X porque Y", una sola variable a la vez.
   4. Test de regresión que falla por la razón esperada.
   5. Fix más pequeño en la capa correcta.
   6. flutter test → verde; flutter analyze → 0 issues.
   ```

2. **Mapa de síntoma → capa**

   | Síntoma | Capa | Dónde poner el test de regresión |
   |---|---|---|
   | Resultado aritmético incorrecto | `lib/features/calculator/domain/` | `test/unit/calculator/` |
   | DEG/RAD no cambia el seno | `domain/` + `presentation/` | `test/unit/calculator/` y `test/widget/` |
   | Skin no expira | `lib/features/monetization/entitlements/` | `test/unit/monetization/` |
   | Recompensa no se otorga | `lib/platform/` + `monetization/` | test del flujo + verificación manual en Android |
   | Widget se reconstruye mal al cambiar tema | `lib/core/design_system/` + `presentation/` | `test/widget/` |
   | Error de compilación nativa | `lib/platform/`, `android/`, `windows/`, `ios/` | build de la plataforma |

3. **Ejemplo concreto: precedencia**

   ```dart
   // 1) test de regresión (RED)
   test('2 + 3 * 4 debe ser 14, no 20', () {
     expect(Evaluator().evaluate('2 + 3 * 4'), 14);
   });
   ```

   ```bash
   flutter test test/unit/calculator/parser_test.dart --plain-name '2 + 3 * 4'
   # solo después de ver el fallo, tocar evaluator.dart
   flutter analyze && flutter test
   ```

4. **Ejemplo concreto: expiración offline**

   ```dart
   test('sin conexión, la skin vence en la fecha local guardada', () {
     final entitlement = Entitlement(expiresAt: DateTime.utc(2026, 11, 23, 12));
     expect(entitlement.isActive(DateTime.utc(2026, 11, 24, 12)), isFalse);
   });
   ```

   Hipótesis típica: se compara contra `DateTime.now()` local en vez de UTC, o se confía en una respuesta de red que no llega. Se aísla antes de tocar la UI.

5. **Migración de UI: los efectos de `initState` también son comportamiento (verificado el 2026-11-25)**

   Al sustituir un widget por un renderer o una pantalla nueva, compara el widget antiguo con el nuevo buscando llamadas con efecto secundario (`loadCatalog`, `addPostFrameCallback`, suscripciones). Un test heredado verde no demuestra que se conservaron: la semilla del repositorio puede enmascarar la pérdida. Reproduce con un test de widget que inyecte una fuente falsa (`SkinManifestSource` en memoria, sin red) y compruebe el efecto observable, por ejemplo que una skin del manifiesto remoto aparece en el selector. Verificado en V3 del Studio: `SkinSelector` era el único punto que llamaba a `loadCatalog`; al cambiarlo por `SkinSelectorScreen` la carga desapareció y el test `test/widget/skin_catalog_load_test.dart` falló con `['classic_amber', 'lcd_classica']` antes del fix.

6. **Worktree nuevo sin package config (verificado el 2026-11-25)**: `flutter test --no-pub` en un worktree recién creado crashea con `Bad state: No element` en `testCompilerBuildNativeAssets`, porque no existe `.dart_tool/package_config.json` con el `root` del proyecto. La capa es de entorno, no de dominio: ejecutar `flutter pub get` en ese worktree y relanzar analyze y test. Si pub get regenera artefactos Windows, restaurarlos con `git restore -- windows/flutter/`. No parchear el test ni cambiar `--no-pub` en el proyecto.

7. **Reglas duras**: no borrar un test que falla; no cambiar la expectativa para que pase; no añadir `try/catch` que trague el error; si después de dos hipótesis no hay causa, escalar con `NEEDS_CONTEXT` o `BLOCKED` al orquestador.

## Commands

```bash
flutter test test/unit/calculator/parser_test.dart
flutter test test/unit/monetization/entitlement_test.dart --plain-name 'sin conexión'
flutter test test/widget/
flutter analyze
flutter build apk --debug
```

## Anti-Patterns

- Cambiar el código sin poder reproducir el fallo.
- Añadir un `if` defensivo en el widget cuando la causa está en `domain/`.
- Parchear el síntoma con un valor hardcodeado (`if (expr == '2 + 3 * 4') return 14;`).
- Borrar o saltar (`skip`) el test que falla.
- Dar por correcta una migración de UI porque los tests heredados pasan, sin comprobar los efectos de `initState` del widget sustituido.
- Culpar a Flutter o al plugin antes de aislar con un test unitario.
- Tratar un crash de `testCompilerBuildNativeAssets` en un worktree nuevo como bug del motor: es falta de `flutter pub get`.
- Reportar "arreglado" sin volver a ejecutar `flutter test` y `flutter analyze`.

## Related Skills

- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — el test de regresión sigue red → green → refactor.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — evidencia de que el fix funcionó.
- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — dónde vive cada capa y sus tests.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — regla de invocar debugging ante cualquier error.
