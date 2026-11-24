---
name: dispatching-parallel-agents
description: >
  Coordina subagentes que trabajan simultáneamente en tareas independientes de
  RetroCalculator, asignando un worktree y un conjunto de archivos disjunto a cada uno.
  Trigger: varias tareas sin dependencias entre sí, por ejemplo calculator y settings,
  o Android y Windows en fases distintas.
auto_invoke: paralelo, despachar agentes, tareas independientes, simultáneo, worktrees paralelos, coordinar agentes
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [using-git-worktrees, subagent-driven-development, verification-before-completion]
  status: active
  category: workflow
---

## TL;DR

Paraleliza solo lo que no comparte archivos ni decisiones. Cada agente tiene su worktree, su slice y su comando de verificación. Si dos tareas tocan el mismo archivo, se serializan.

## Purpose

Acelerar el trabajo sin crear conflictos de merge ni contradicciones arquitectónicas. En RetroCalculator es útil para combinar, por ejemplo, el motor de cálculo con la configuración de tema, o la documentación con el CI, siempre que no se solapen.

## When to Use

- Dos o más slices de `to-issues` sin dependencia entre sí.
- Un agente investiga (debug) mientras otro documenta un ADR ya decidido.
- Preparar plataformas en worktrees distintos (Android primero; Windows e iOS solo en sus fases).

## Critical Patterns

1. **Matriz de solapes antes de despachar**

   | Agente | Archivos que puede tocar | ¿Compatible en paralelo? |
   |---|---|---|
   | `calculator` | `lib/features/calculator/**`, `test/unit/calculator/**` | Sí con `settings` y `docs` |
   | `skins` | `lib/features/skins/**`, `lib/core/design_system/**` | Sí con `calculator`; No con `monetization` si cambia el contrato de entitlement |
   | `monetization` | `lib/features/monetization/**` | Sí con `calculator`; No con `skins` sobre el mismo modelo |
   | `platform` | `lib/platform/**`, `android/`, `windows/`, `ios/` | Sí con el resto; respeta orden Android → Windows → iOS |
   | `docs` | `docs/**` | Sí con todos |
   | `infra` | `.github/workflows/**` | Sí con todos |

2. **Procedimiento**
   - Comprobar dependencias: si el slice B necesita la salida del A, no paralelizar.
   - Crear un worktree por agente con `using-git-worktrees`.
   - Entregar el texto completo del slice,la restricción de archivos y el comando de verificación.
   - Recoger resultados con estado explícito (`DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED`).
   - Verificar cada worktree individualmente antes de integrar.
   - Integrar en orden y resolver conflictos con el orquestador, nunca con un force-push.

3. **Ejemplo de despacho seguro**

   ```text
   Paralelo A (worktree feature-calculator-engine):
     motor + tests unitarios; flutter test test/unit/calculator/
   Paralelo B (worktree docs-skins-entitlements):
     ADR-0001 y plantilla de plan; sin tocar lib/
   ```

   Ambos pueden avanzar a la vez. En cambio, `skins` y `monetization` no deben modificar simultáneamente la definición de `Entitlement`.

4. **Regla de oro intacta**: ningún agente en paralelo puede añadir bloqueos de anuncios ni cobrar por la calculadora; `spec reviewer` lo comprueba en cada rama.

## Commands

```bash
git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
git worktree add .worktrees/docs-skins-model -b docs/skins-model

# En cada worktree, antes de reportar resultado
flutter pub get
flutter analyze
flutter test

# Inventario de worktrees activos
git worktree list
```

## Anti-Patterns

- Dos agentes editando `entitlement.dart` o cualquier archivo compartido a la vez.
- Paralelizar Windows/iOS antes de que Android y las decisiones de monetización estén cerradas.
- No crear worktree y dejar que dos agentes usen el mismo directorio de trabajo.
- Asumir que "no hay conflictos" sin revisar `git status` en cada rama.
- Integrar cambios sin ejecutar `flutter analyze` y `flutter test` en cada worktree.

## Related Skills

- [using-git-worktrees](../../../.opencode/skills/using-git-worktrees/SKILL.md) — crea el aislamiento de cada agente.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — define el ciclo por slice.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — decide qué se puede paralelizar.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — verificación por rama.
