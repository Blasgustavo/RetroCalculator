---
name: verification-before-completion
description: >
  Exige evidencia real antes de afirmar que una tarea de RetroCalculator terminó: ejecutar
  flutter analyze, flutter test (unit/widget/integration), revisar git status y citar los
  resultados. Trigger: antes de decir listo, completado, compila o listo para PR.
auto_invoke: verificar, antes de completar, antes de decir listo, flutter analyze, flutter test, evidence, comprobación final
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [flutter-standards]
  status: active
  category: testing
---

## TL;DR

No se reporta éxito sin comandos ejecutados y resultados visibles. Mínimo obligatorio: `flutter analyze` y `flutter test` en verde, `git status --short` revisado y, si cambia la UI, test de widget o captura.

## Purpose

Eliminar afirmaciones sin base. En un proyecto donde el motor se ejecuta en tres plataformas y los entitlements expiran con el tiempo, un "creo que funciona" puede esconder una regresión de precedencia de operadores o una skin que nunca vuelve al tema gratuito.

## When to Use

- Antes de marcar un slice como `DONE` en `subagent-driven-development`.
- Antes de abrir o actualizar un PR a `main`.
- Después de un fix de `systematic-debugging`, para confirmar el test de regresión.
- Antes de responder al usuario que la tarea está terminada.

## Critical Patterns

1. **Secuencia de evidencia**

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   git status --short
   git diff --stat
   ```

   Reportar: comandos ejecutados, número de tests, errores de analyze (0) y archivos modificados.

2. **Verificación por tipo de cambio**

   | Cambio | Evidencia mínima |
   |---|---|
   | Parser / evaluador | `flutter test test/unit/calculator/` con casos de precedencia, DEG/RAD y división por cero |
   | Entitlement de skin | `flutter test test/unit/monetization/` con expiración y renovación |
   | Widget del teclado / tienda | `flutter test test/widget/` |
   | Rewarded ad | Test del flujo de recompensa + revisión de que no hay banner/intersticial |
   | `lib/platform/**` | analyze + test + build de la plataforma correspondiente |
   | Docs / ADR | Enlaces rotos y convención `YYYY-MM-DD-<feature>.md` |
   | Skills | `skill-sync` ejecutado y tabla de `AGENTS.md` actualizada |

3. **Ejemplo de reporte correcto**

   ```text
   Verificado en .worktrees/feature-calculator-engine:
   - flutter analyze → 0 issues
   - flutter test → 42 passed (21 unit calculator, 9 widget, 12 monetization)
   - git status → solo parser.dart y parser_test.dart modificados
   Conclusión: slice S1 listo para spec reviewer.
   ```

4. **Si algo falla**: no se maquilla el resultado; invocar `systematic-debugging`, corregir la causa y volver a ejecutar la verificación completa. Nunca se usa `--no-verify`.

## Commands

```bash
flutter analyze
flutter test
flutter test test/unit/calculator/
flutter test test/unit/monetization/
flutter test test/widget/
git status --short
git diff --stat
```

## Anti-Patterns

- Decir "debería compilar" sin ejecutar `flutter analyze`.
- Reportar "tests pasan" sin decir cuántos ni dónde.
- Saltarse tests de widget cuando se cambió el display o la tienda de skins.
- Ignorar warnings nuevos de analyze porque "son del tema retro".
- Ejecutar la verificación en un directorio distinto al worktree del cambio.
- Usar `--no-verify` para esquivar hooks pre-commit.

## Related Skills

- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — define qué comandos y estructura se verifican.
- [systematic-debugging](../../../.opencode/skills/systematic-debugging/SKILL.md) — qué hacer cuando la verificación falla.
- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — origen de los tests ejecutados.
- [finishing-a-development-branch](../../../.opencode/skills/finishing-a-development-branch/SKILL.md) — consumidor final de la evidencia.
