# RetroCalculator — Orquestador

Este archivo es el **contrato de trabajo** del proyecto. Define qué skill se invoca automáticamente según la tarea y las reglas globales que todo agente debe respetar.

La configuración operativa de agentes está en [`.opencode/opencode.json`](./.opencode/opencode.json) y los prompts en [`.opencode/agents/`](./.opencode/agents/).

---

## Auto-invoke Skills

| Trigger | Skill | Path |
|---|---|---|
| ADR, decisión arquitectónica, decisión load-bearing, documentar decisión | `adr-recorder` | [.opencode/skills/adr-recorder/SKILL.md](./.opencode/skills/adr-recorder/SKILL.md) |
| Autolearn, patrones aprendidos, actualizar skills tras confirmación | `auto-learn` | [.opencode/skills/auto-learn/SKILL.md](./.opencode/skills/auto-learn/SKILL.md) |
| Agentes, subagentes, ejecutar plan con subagentes, delegar tareas | `subagent-driven-development` | [.opencode/skills/subagent-driven-development/SKILL.md](./.opencode/skills/subagent-driven-development/SKILL.md) |
| Tareas independientes en paralelo, despachar agentes paralelos | `dispatching-parallel-agents` | [.opencode/skills/dispatching-parallel-agents/SKILL.md](./.opencode/skills/dispatching-parallel-agents/SKILL.md) |
| Commits, Git, GitHub, PR, push, conventional commits | `git-github-workflow` | [.opencode/skills/git-github-workflow/SKILL.md](./.opencode/skills/git-github-workflow/SKILL.md) |
| Terminar branch, merge, cerrar desarrollo, crear PR | `finishing-a-development-branch` | [.opencode/skills/finishing-a-development-branch/SKILL.md](./.opencode/skills/finishing-a-development-branch/SKILL.md) |
| Antes de afirmar completitud, verificar tests y analyze | `verification-before-completion` | [.opencode/skills/verification-before-completion/SKILL.md](./.opencode/skills/verification-before-completion/SKILL.md) |
| Worktree, workspace aislado, branch nueva, crear worktree | `using-git-worktrees` | [.opencode/skills/using-git-worktrees/SKILL.md](./.opencode/skills/using-git-worktrees/SKILL.md) |
| Plan, planificación, crear plan, descomponer tarea, plan antes de código | `writing-plans` | [.opencode/skills/writing-plans/SKILL.md](./.opencode/skills/writing-plans/SKILL.md) |
| Issues, vertical slices, tracer bullets, dividir plan | `to-issues` | [.opencode/skills/to-issues/SKILL.md](./.opencode/skills/to-issues/SKILL.md) |
| TDD, test primero, red-green-refactor | `test-driven-development` | [.opencode/skills/test-driven-development/SKILL.md](./.opencode/skills/test-driven-development/SKILL.md) |
| Error, bug, debug, root cause, regresión | `systematic-debugging` | [.opencode/skills/systematic-debugging/SKILL.md](./.opencode/skills/systematic-debugging/SKILL.md) |
| Flutter, Dart, Clean Architecture, MVVM, design system, tests Flutter | `flutter-standards` | [.opencode/skills/flutter-standards/SKILL.md](./.opencode/skills/flutter-standards/SKILL.md) |
| Orquestación, coordinación entre agentes, routing de tareas | `orchestrator-agent` | [.opencode/skills/orchestrator-agent/SKILL.md](./.opencode/skills/orchestrator-agent/SKILL.md) |
| Sincronizar agentes, propagar cambios de skills a prompts | `sync-agents` | [.opencode/skills/sync-agents/SKILL.md](./.opencode/skills/sync-agents/SKILL.md) |
| Crear skill, sincronizar AGENTS.md, regenerar tabla de triggers | `skill-sync` | [.opencode/skills/skill-sync/SKILL.md](./.opencode/skills/skill-sync/SKILL.md) |

---

## Reglas globales

| # | Regla | ¿Por qué? |
|---|---|---|
| 1 | Antes de generar código, cargar `flutter-standards`. | Mantiene Clean + MVVM y evita reinventar convenciones. |
| 2 | Ante cualquier error, invocar `systematic-debugging` antes de proponer fixes. | Evita parches de síntomas; busca root-cause. |
| 3 | Después de generar código, preguntar al usuario si fue correcto; **solo con confirmación explícita** invocar `auto-learn`. | El sistema mejora solo con retroalimentación validada. |
| 4 | Toda operación Git sigue Conventional Commits (`type(scope): summary` en inglés, cuerpo en español). | Changelog automático y revert seguro. |
| 5 | Toda tarea > 15 min pasa por `writing-plans` antes de implementarse. | Evita scope creep y permite ejecución con subagentes. |
| 6 | Antes de afirmar completitud, `verification-before-completion` (`flutter analyze` + `flutter test`). | Evita claims sin evidencia real. |
| 7 | Toda decisión load-bearing se registra con `adr-recorder` en `docs/adr/`. | Evita que futuros agentes re-sugieran lo descartado. |
| 8 | Tareas grandes independientes: `subagent-driven-development` + `using-git-worktrees`. | Aísla contexto y permite review estructurado. |
| 9 | Antes de mergear, review de spec y review de calidad. | Detecta issues antes de llegar a `main`. |
| 10 | Tras crear/editar skills, ejecutar `skill-sync` para actualizar esta tabla. | Mantiene la auto-invocación sincronizada. |

---

## Reglas de arquitectura

- La lógica de cálculo vive en `lib/features/calculator/domain/` y **no depende de Flutter ni de la UI**.
- Las skins **no alteran** el motor: solo consumen `lib/core/design_system/`.
- Los entitlements se validan en `lib/features/monetization/entitlements/`; la UI solo consume su estado.
- Los plugins nativos se aíslan en `lib/platform/`; el resto del código no los importa directamente.
- La calculadora es siempre gratuita: ninguna skin ni anuncio bloquea el cálculo.

---

## Orden de plataformas

Android → Windows → iOS. Ver [ADR-0002](./docs/adr/0002-orden-plataformas.md).
