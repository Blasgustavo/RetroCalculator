---
name: finishing-a-development-branch
description: >
  Cierra una rama de desarrollo de RetroCalculator: ejecuta la verificación final
  (flutter analyze + flutter test), decide entre PR a main, merge tras CI o mantenimiento,
  y limpia el worktree. Trigger: terminar una feature/fix, crear PR, mergear o abandonar una rama.
auto_invoke: terminar rama, cerrar branch, crear PR, merge a main, fin de feature, limpiar worktree, release
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [verification-before-completion, git-github-workflow, using-git-worktrees]
  status: active
  category: workflow
---

## TL;DR

Antes de cerrar: pruebas en verde, diff revisado, PR con Summary/Testing/Checklist, CI en verde, merge a `main`, tag `vX.Y.Z` si corresponde y limpieza del worktree. Nunca se cierra una rama con advertencias sin revisar.

## Purpose

Dar un único punto de decisión para el final de cada rama. Evita que un trabajo con `DONE_WITH_CONCERNS`, tests fallidos o un worktree olvidado acabe en `main`. La rama `main` está protegida: todo llega mediante PR.

## When to Use

- El último slice del plan tiene estado `DONE` y las revisiones están limpias.
- Hay que abrir un PR a `main` o actualizar uno existente.
- El CI terminó y hay que decidir merge, cambios o abandono de la rama.
- Hay que publicar una versión (`v0.1.0`, `v1.0.0`) y su release.

## Critical Patterns

1. **Decisión guiada**

   | Situación | Acción |
   |---|---|
   | Analyze + test en verde, reviews sin issues | Abrir PR a `main` |
   | CI falla | Volver al implementer con `systematic-debugging` |
   | `DONE_WITH_CONCERNS` | Documentar concerns en el PR o resolverlos antes de mergear |
   | La feature se descarta | Cerrar PR sin merge y eliminar worktree y rama |
   | Release | Merge + tag `vX.Y.Z` + release con notas |

2. **Checklist previo al cierre**
   - `git status --short` sin archivos accidentales ni secretos (`.env`, keystores).
   - `git diff --stat` revisado; commits con `type(scope): summary` en inglés y cuerpo en español.
   - `flutter analyze` y `flutter test` ejecutados en el worktree.
   - Cobertura del motor de cálculo sin regresiones.
   - `skill-sync` ejecutado si se crearon o editaron skills.
   - Sin force-push en `main`; sin commits vacíos ni `--no-verify`.

3. **PR a `main` (plantilla mínima)**

   ```markdown
   ## Summary
   Add scientific mode parser with DEG/RAD toggle.

   ## Testing
   - flutter analyze
   - flutter test (unit + widget)
   - Manual: 2 + 3 * 4 = 14 en Android

   ## Checklist
   - [ ] El motor sigue sin depender de Flutter
   - [ ] La calculadora sigue siendo gratuita
   - [ ] Sin banners ni intersticiales
   - [ ] Capturas adjuntas (UI)
   ```

4. **Ejemplo de secuencia completa**

   ```bash
   cd .worktrees/feature-calculator-engine
   flutter analyze && flutter test
   git status --short
   git push -u origin feature/calculator-engine
   # PR a main con Summary / Testing / Checklist
   # tras CI verde y merge:
   git worktree remove .worktrees/feature-calculator-engine
   git checkout main && git pull
   git tag v0.1.0 && git push origin v0.1.0
   ```

5. **Notas de plataforma**: para Android se comprueba el build firmado con secrets de keystore; Windows e iOS se cierran solo en sus fases (MSIX / IPA + ATT).

## Commands

```bash
flutter analyze
flutter test
git diff --stat
git status --short
git push -u origin feature/calculator-engine
git worktree remove .worktrees/feature-calculator-engine
git branch -d feature/calculator-engine
git tag v0.1.0
```

## Anti-Patterns

- Mergear sin PR o con `main` protegido saltado por force-push.
- Cerrar con `flutter analyze` o `flutter test` rojos "porque es un warning".
- PR sin Summary/Testing/Checklist o sin capturas cuando cambia la UI.
- Olvidar limpiar el worktree y la rama local tras merge.
- Taggear una versión que no pasó CI en Android (plataforma inicial).
- Auto-learn antes de que el usuario confirme que el cambio fue correcto.

## Related Skills

- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — aporta la evidencia del cierre.
- [git-github-workflow](../../../.opencode/skills/git-github-workflow/SKILL.md) — formato de commits, ramas y PR.
- [using-git-worktrees](../../../.opencode/skills/using-git-worktrees/SKILL.md) — creación y limpieza del worktree.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — estado previo de los slices.
- [auto-learn](../../../.opencode/skills/auto-learn/SKILL.md) — paso opcional tras release confirmada.
