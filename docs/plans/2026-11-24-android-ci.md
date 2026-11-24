# Android CI — Plan de implementación

## Contexto

El PR #4 entrega el MVP Android (motor puro, i18n, historial local y UI MVVM) pero GitHub no reporta checks porque no existe `.github/workflows/`. `AGENTS.md` exige verificación antes de mergear y `finishing-a-development-branch` exige CI verde. ADR-0002 fija Android como primera plataforma, así que se configura primero el workflow de Android; Windows e iOS quedan para sus fases.

## Alcance

- Incluye: un workflow de GitHub Actions que ejecuta `flutter pub get --enforce-lockfile`, `flutter gen-l10n`, comprobación del Dart generado, `dart format`, `flutter analyze` y `flutter test` en Ubuntu.
- Excluye: builds firmados, publicación a Google Play, secrets de keystore, Windows, iOS y cambios en código Dart.

## Arquitectura

Capas tocadas: solo infraestructura de repositorio.

- Archivo nuevo: `.github/workflows/android.yml`.
- Sin cambios en `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, ADRs ni planes existentes.

## Tareas

### T1 — Workflow de Android

- **Archivo principal:** `.github/workflows/android.yml` (nuevo).
- **Criterio de aceptación:** dispara en `push` a `main`, `pull_request` a `main` y `workflow_dispatch`; usa `actions/checkout@v4`, `actions/setup-java@v4` con Temurin 17, `subosito/flutter-action@v2` con Flutter 3.44.0 y caché; permisos `contents: read`.
- **Código literal:**

```yaml
name: Android CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  analyze-and-test:
    name: Analyze and test
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter 3.44.0
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.0'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get --enforce-lockfile

      - name: Generate localizations
        run: flutter gen-l10n

      - name: Check generated localizations are committed
        run: git diff --exit-code -- lib/l10n

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed lib test

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test
```

- **Verificar:** `git diff --check -- .github/workflows/android.yml` y revisión manual del YAML.

### T2 — Verificación local equivalente

- **Archivo principal:** ninguno (comandos).
- **Criterio de aceptación:** los mismos comandos que ejecutará CI pasan en el worktree; `windows/flutter/generated_plugins.cmake` se restaura a HEAD después de `pub get` porque Windows es fase 2.
- **Comandos:**

```powershell
flutter pub get --enforce-lockfile
git restore -- windows/flutter/generated_plugins.cmake
flutter gen-l10n
git diff --exit-code -- lib/l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git status --short --branch --untracked-files=all
```

### T3 — Publicación y comprobación de checks

- **Archivo principal:** ninguno (Git/GitHub).
- **Criterio de aceptación:** el workflow se commitea en `feature/calculator-engine`, se pushea y el PR #4 reporta el check `Analyze and test` en verde antes de cualquier merge.
- **Comandos:**

```bash
git add .github/workflows/android.yml
git commit -m "ci(android): add analyze and test workflow"
git push
gh pr checks 4 --repo Blasgustavo/RetroCalculator
```

## Verificación final

- `flutter analyze` → 0 issues.
- `flutter test` → 29/29.
- `dart format --output=none --set-exit-if-changed lib test` → 0 changed.
- `git diff --exit-code -- lib/l10n` → 0.
- `gh pr checks 4` → `Analyze and test` en verde.

## Riesgos

- `flutter-action@v2` puede tardar en descargar el SDK en el primer run; la caché mitiga ejecuciones posteriores.
- `git diff --exit-code -- lib/l10n` fallaría si `flutter gen-l10n` no es determinista; en local se verificó idempotente.
- No se comprime ni firma el APK: la validación manual en Android sigue siendo responsabilidad del humano antes del release.
