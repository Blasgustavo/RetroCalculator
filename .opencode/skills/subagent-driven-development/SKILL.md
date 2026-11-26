---
name: subagent-driven-development
description: >
  Ejecuta cada slice del plan con un subagente fresco, seguido de review de spec y de
  calidad, con estados DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED antes de pasar al
  siguiente. Trigger: ejecutar planes con subagentes, revisar implementación o cerrar una tarea.
auto_invoke: subagentes, ejecutar con subagentes, spec reviewer, quality reviewer, implementer, DONE_WITH_CONCERNS, BLOCKED
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 1, last_used: "2026-11-25", success_rate: 1.0 }
  dependencies: [to-issues, dispatching-parallel-agents, verification-before-completion, git-github-workflow]
  status: active
  category: workflow
---

## TL;DR

Un subagente por tarea, con contexto limpio. Después de cada implementación: review de spec, review de calidad, verificación con `flutter analyze` + `flutter test`, commit. No se avanza con issues abiertos.

## Purpose

Mantener el contexto de cada agente pequeño y hacer explícita la calidad. En un proyecto con motor de cálculo, skins temporales y anuncios recompensados, un mismo agente que acumula todo el historial termina mezclando dominios; el flujo con reviews evita que un cambio cosmético rompa el parser o que una recompensa desbloquee la calculadora.

## When to Use

- Slices de `to-issues` listos para ejecutar.
- Tareas grandes o independientes que requieren worktree propio.
- Antes de cualquier PR a `main`.

## Critical Patterns

1. **Ciclo por slice**

   ```
   texto completo del slice → implementer (fresh)
     → test falla (red) → código mínimo (green) → refactor → commit
     → spec reviewer (¿cumple criterio?) → issues? volver al implementer
     → quality reviewer (¿arquitectura, tests, analyze?) → issues? volver al implementer
     → verification-before-completion → siguiente slice
   ```

2. **Estados del implementer**

   | Estado | Acción del orquestador |
   |---|---|
   | `DONE` | pasar a spec reviewer |
   | `DONE_WITH_CONCERNS` | revisar concerns; si afectan spec, devolver; si no, documentarlos en el PR |
   | `NEEDS_CONTEXT` | aportar el ADR o el texto del plan que falta |
   | `BLOCKED` | más contexto, modelo más capaz, dividir el slice o escalar al humano |

3. **Prompt del implementer (ejemplo real)**

   ```text
   Slice S3 — Expiración de skin temporal.
   Archivos: lib/features/monetization/entitlements/entitlement.dart,
             test/unit/monetization/entitlement_test.dart.
   Criterio: isActive == false cuando expiresAt <= ahora; la UI consume el estado.
   Restricciones: no tocar lib/features/calculator/domain/; sin plugins nativos fuera de lib/platform/.
   Verificación: flutter test test/unit/monetization/entitlement_test.dart
   Devuelve además: estado (DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED) y comandos ejecutados.
   ```

4. **Checklist del reviewer de calidad**
   - `flutter analyze` sin issues nuevos; `flutter test` en verde.
   - El motor sigue siendo Dart puro, sin `package:flutter/*` en `domain/`.
   - La skin solo toca `lib/core/design_system/`; el entitlement decide en `features/monetization/entitlements/`.
   - Sin anuncios banner/intersticiales; ningún anuncio es obligatorio para calcular.
   - Commit `type(scope): summary` en inglés con cuerpo en español.

5. **Paralelismo seguro**: despachar implementers en paralelo solo si tocan archivos disjuntos (por ejemplo `calculator` y `settings`); usar `dispatching-parallel-agents` y worktrees separados.

6. **Revisiones delegadas en paralelo (verificado el 2026-11-25)**: enviar spec y calidad juntas, en el mismo turno, a `general` con `opencode/beam-free#max` y sin permisos de escritura; incluir el diff y los criterios completos en cada prompt, no solo «lee el plan». Ambas revisiones deben devolver `APPROVED` antes de mergear. Los subagentes corren en background y reportan al quedar idle.

## Commands

```bash
# Worktree del slice
git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
cd .worktrees/feature-calculator-engine
flutter pub get

# Verificación obligatoria antes de pedir review
flutter analyze
flutter test

# Commit del slice
git add lib/features/calculator/domain/parser.dart test/unit/calculator/parser_test.dart
git commit -m "feat(calculator): add expression parser with precedence"
```

## Anti-Patterns

- Un mismo agente para toda la feature acumulando contexto y decisiones ajenas.
- Saltarse review de spec o de calidad porque "el test pasó".
- Avanzar al slice siguiente con `DONE_WITH_CONCERNS` sin revisar los concerns.
- Entregar al subagente solo "lee el plan" en lugar del texto completo.
- Dos implementers editando el mismo archivo en paralelo.
- Pedir al implementer que ejecute `git push` o abra PR: eso lo cierra el orquestador.

## Related Skills

- [to-issues](../../../.opencode/skills/to-issues/SKILL.md) — produce los slices ejecutados aquí.
- [dispatching-parallel-agents](../../../.opencode/skills/dispatching-parallel-agents/SKILL.md) — paralelismo sin solapes.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — prueba antes de reportar DONE.
- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — red → green → refactor de cada slice.
- [using-git-worktrees](../../../.opencode/skills/using-git-worktrees/SKILL.md) — aislamiento del worktree.
