---
name: using-git-worktrees
description: >
  Aísla cada feature o fix de RetroCalculator en .worktrees/feature-<slug> sobre una rama
  feature/<slug>, verificando primero que .worktrees/ esté ignorado y dejando un baseline
  limpio con flutter pub get, analyze y test. Trigger: empezar una feature, fix o tarea
  con subagentes sin contaminar main.
auto_invoke: worktree, .worktrees, aislar trabajo, rama nueva, feature branch, empezar feature, git worktree add
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 1, last_used: "2026-11-25", success_rate: 1.0 }
  dependencies: [git-github-workflow, writing-plans]
  status: active
  category: workflow
---

## TL;DR

Nunca se implementa en `main`. Se verifica `.worktrees/` en `.gitignore`, se crea el worktree con la rama correspondiente, se valida el baseline y solo entonces se despacha el trabajo. Al cerrar, se limpia el worktree.

## Purpose

Permitir que el motor, las skins y la monetización avancen en branches separadas, con PRs independientes a `main`, sin que un fallo en una rama bloquee a las demás. También hace posible el paralelismo seguro de `dispatching-parallel-agents`.

## When to Use

- Iniciar cualquier slice de un plan de `docs/plans/`.
- Ejecutar tareas con `subagent-driven-development`.
- Probar una decisión de plataforma sin ensuciar la rama protegida.

## Critical Patterns

1. **Verificar el ignore ANTES de crear**

   ```bash
   # .gitignore debe contener .worktrees/
   git check-ignore -v .worktrees/
   # salida esperada: .gitignore:<linea>:.worktrees/    .worktrees/
   ```

   Si no hay salida, añadir `.worktrees/` a `.gitignore` antes de continuar. Nunca commitear un worktree.

2. **Creación y baseline**

   ```bash
   git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
   cd .worktrees/feature-calculator-engine
   flutter pub get
   flutter analyze
   flutter test
   ```

   El baseline debe estar en verde; si no lo está, se documenta y se corrige antes de implementar, para no confundir regresiones propias con fallos previos. Un worktree recién creado no tiene `.dart_tool/package_config.json`: ejecutar siempre `flutter pub get` antes de testear, porque `flutter test --no-pub` sin ese archivo crashea en `testCompilerBuildNativeAssets` con `Bad state: No element` (verificado el 2026-11-25). Tras pub get, restaurar artefactos Windows con `git restore -- windows/flutter/`.

3. **Nomenclatura coherente con el flujo**

   | Tipo | Rama | Directorio |
   |---|---|---|
   | feature | `feature/calculator-engine` | `.worktrees/feature-calculator-engine` |
   | fix | `fix/parser-precedence` | `.worktrees/fix-parser-precedence` |
   | docs | `docs/adr-backend` | `.worktrees/docs-adr-backend` |
   | chore | `chore/android-ci` | `.worktrees/chore-android-ci` |

   Slug en inglés; `main` nunca se checks out para editar.

4. **Reglas para subagentes**
   - Cada agente recibe la ruta absoluta de su worktree y no debe salir de ella.
   - Los archivos de `lib/features/calculator/domain/` no se tocan desde un worktree de skins.
   - Los plugins nativos se aíslan en `lib/platform/` aunque el worktree sea de Android.
   - Los commits siguen `type(scope): summary` en inglés con cuerpo en español.

5. **Cierre**
   - Tras merge del PR, eliminar con `git worktree remove .worktrees/feature-<slug>` y borrar la rama local si ya no se necesita.

## Commands

```bash
git check-ignore -v .worktrees/
git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
git worktree list
git status --short
flutter pub get && flutter analyze && flutter test
git worktree remove .worktrees/feature-calculator-engine
git branch -d feature/calculator-engine
```

## Anti-Patterns

- Crear el worktree sin verificar `.gitignore` y dejar `.worktrees/` en `git status`.
- Implementar directamente sobre `main` "porque es un cambio pequeño".
- Dos worktrees apuntando a la misma rama.
- No ejecutar el baseline y culpar al slice de un fallo que ya existía.
- Saltarse `flutter pub get` en un worktree nuevo y usar `--no-pub` desde el primer test.
- Olvidar eliminar el worktree tras merge, dejando ramas huérfanas.

## Related Skills

- [git-github-workflow](../../../.opencode/skills/git-github-workflow/SKILL.md) — naming de ramas y commits.
- [dispatching-parallel-agents](../../../.opencode/skills/dispatching-parallel-agents/SKILL.md) — un worktree por agente.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — trabajo dentro del worktree.
- [finishing-a-development-branch](../../../.opencode/skills/finishing-a-development-branch/SKILL.md) — cierre y limpieza.
