---
name: git-github-workflow
description: >
  Gestiona ramas, Conventional Commits, push y Pull Requests a main en RetroCalculator:
  commits type(scope): summary en inglés con cuerpo en español, ramas feature/fix/docs/chore
  y PR con Summary/Testing/Checklist. Trigger: cualquier operación git, commit, push, PR,
  tag o release.
auto_invoke: git, commit, conventional commits, push, PR, pull request, rama, branch, main, tag, release
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [verification-before-completion, using-git-worktrees]
  status: active
  category: workflow
---

## TL;DR

Título en inglés, cuerpo en español. `main` protegido, PR obligatorio, worktree por rama y checklist antes de commitear. Nada de force-push en `main`, commits vacíos ni `--no-verify`.

## Purpose

Hacer que el historial sea legible y reversible, y que cada cambio pase por verificación y revisión antes de llegar a la rama protegida. El proyecto usa inglés para títulos de commit y PR, y español para documentación, cuerpo de commit y conversación.

## When to Use

- Crear una rama para un slice de `docs/plans/`.
- Commitear avances de motor, skins, monetización, plataforma o docs.
- Abrir o actualizar un PR a `main`.
- Etiquetar versiones y releases.

## Critical Patterns

1. **Nomenclatura**

   | Elemento | Formato | Ejemplo |
   |---|---|---|
   | Rama feature | `feature/<slug>` | `feature/calculator-engine` |
   | Rama fix | `fix/<slug>` | `fix/parser-precedence` |
   | Rama docs | `docs/<slug>` | `docs/adr-backend` |
   | Rama chore | `chore/<slug>` | `chore/android-ci` |
   | Commit | `type(scope): summary` (EN) | `feat(calculator): add scientific mode toggle` |
   | Tag | `vX.Y.Z` | `v0.1.0` |

   Tipos válidos: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`. Scope sugerido: `calculator`, `skins`, `monetization`, `ads`, `iap`, `platform`, `docs`, `ci`, `skills`.

2. **Commit: título inglés, cuerpo español**

   ```text
   feat(calculator): add expression parser with operator precedence

   Implementa el parser del modo científico sin usar eval y sin depender de Flutter.
   Afecta a lib/features/calculator/domain/ y a sus tests unitarios.
   Validado con flutter analyze y flutter test: 42 tests en verde.
   ```

3. **Checklist antes de commit**
   - `git status` sin archivos accidentales.
   - `git diff --stat` revisado.
   - `flutter analyze` y `flutter test` en verde.
   - Sin secretos: `.env`, keystores, credenciales de AdMob/Google Play/App Store.
   - `skill-sync` ejecutado si se crearon o editaron skills.

4. **PR a `main`**

   ```markdown
   ## Summary
   Add rewarded-ad skin renewal with expiry handling.

   ## Testing
   - flutter analyze
   - flutter test (unit + widget)
   - Manual en Android: ver anuncio → skin activa → expira → tema gratuito

   ## Checklist
   - [ ] La calculadora sigue siendo gratuita
   - [ ] Solo anuncios recompensados (sin banners ni intersticiales)
   - [ ] Sin secretos en el diff
   - [ ] Capturas adjuntas si cambia la UI
   ```

   El título del PR es el commit principal. No se force-pushea `main`, no se usan commits vacíos y no se salta el pre-commit hook.

5. **CI por plataforma (orden acordado)**: `android.yml` → `windows.yml` → `ios.yml`. Android dispara con `workflow_dispatch` y tags `v*`; los secrets de keystore y certificados nunca se commitean.

## Commands

```bash
git checkout -b feature/calculator-engine
git status --short
git diff --stat
git add lib/features/calculator/domain/parser.dart test/unit/calculator/parser_test.dart
git commit -m "feat(calculator): add expression parser with precedence" -m "Implementa parser propio sin eval ni dependencias de Flutter. Validado con flutter test."
git push -u origin feature/calculator-engine
git tag v0.1.0
```

## Anti-Patterns

- `git commit -m "arreglos"` o mensajes en español en el título.
- Cuerpo del commit en inglés cuando la regla dice español.
- Commitear `.worktrees/`, `build/`, `.dart_tool/` o credenciales.
- Push directo a `main` o force-push sin acuerdo explícito.
- PR sin `## Summary`, `## Testing` y `## Checklist`.
- `--no-verify` para esquivar `flutter analyze` en el hook pre-commit.

## Related Skills

- [using-git-worktrees](../../../.opencode/skills/using-git-worktrees/SKILL.md) — rama y directorio aislados.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — evidencia previa al commit.
- [finishing-a-development-branch](../../../.opencode/skills/finishing-a-development-branch/SKILL.md) — cierre y merge del PR.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — regla global de Conventional Commits.
