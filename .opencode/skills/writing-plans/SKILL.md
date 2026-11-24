---
name: writing-plans
description: >
  Escribe planes de implementación exhaustivos y ejecutables para RetroCalculator, con
  tareas de 2-5 minutos, código Dart real, rutas concretas y comandos flutter/dart/git.
  Los guarda en docs/plans/YYYY-MM-DD-<feature>.md. Trigger: tarea > 15 min, feature con
  varias capas Clean+MVVM o antes de crear un worktree.
auto_invoke: plan, planificar, writing-plans, desglosar tarea, docs/plans, feature grande, implementar calculadora
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [adr-recorder, flutter-standards, to-issues]
  status: active
  category: workflow
---

## TL;DR

Todo trabajo mayor de 15 minutos se escribe primero en `docs/plans/YYYY-MM-DD-<feature>.md`: tareas pequeñas, código real y comandos verificables. No se guarda en `.opencode/plans/` (ese directorio es para el plan de la sesión, no para planes de entrega).

## Purpose

Convertir una idea o un ADR en una secuencia de pasos que un subagente pueda ejecutar sin adivinar. El plan elimina la ambigüedad sobre dónde vive cada archivo (`lib/features/.../domain` vs `presentation`), qué test se escribe primero y qué comando demuestra que la tarea terminó.

## When to Use

- Implementar el motor normal/científico con parser propio (sin `eval`).
- Añadir catálogo de skins, tienda o cuenta atrás de expiración.
- Integrar anuncios recompensados o IAP con entitlements temporales.
- Adaptar Android → Windows → iOS, o montar CI por plataforma.
- Antes de `using-git-worktrees` y de `subagent-driven-development`.

## Critical Patterns

1. **Ubicación y nombre**

   ```
   docs/plans/2026-11-24-calculadora-normal-cientifica.md
   docs/plans/2026-11-25-skins-temporales-recompensadas.md
   docs/plans/2026-11-26-android-rewarded-ads.md
   ```

   Formato: `docs/plans/YYYY-MM-DD-<feature>.md`, fecha de creación del plan, slug en inglés o español coherente con el resto del docs.

2. **Estructura mínima del plan**

   ```markdown
   # <Feature> — Plan de implementación

   ## Contexto
   Referencia a docs/adr/000N-*.md y a la idea. Qué problema resuelve.

   ## Alcance
   - Incluye: ...
   - Excluye: ... (ej. "windows queda para la fase 5")

   ## Arquitectura
   Capas tocadas: domain → data → presentation. Archivos exactos.

   ## Tareas (2-5 min cada una)
   - [ ] T1 — Test unitario del parser (red)
         Archivo: test/unit/calculator/parser_test.dart
         Verificar: flutter test test/unit/calculator/parser_test.dart
   - [ ] T2 — Parser mínimo sin Flutter
         Archivo: lib/features/calculator/domain/parser.dart
         Verificar: flutter test test/unit/calculator/parser_test.dart

   ## Verificación final
   flutter analyze && flutter test

   ## Riesgos
   Precedencia DEG/RAD, expiración offline, políticas de tienda.
   ```

3. **Reglas de contenido**
   - Cada tarea tiene **un** archivo principal, un criterio de aceptación y un comando de verificación.
   - El código se escribe literalmente en el plan (no "añadir la lógica aquí").
   - El motor se planifica en Dart puro: `lib/features/calculator/domain/` no importa `package:flutter/*`.
   - Las skins se planifican contra `lib/core/design_system/`, nunca contra el motor.
   - Los entitlements se planifican en `lib/features/monetization/entitlements/`; la UI solo consume estado.
   - Si una decisión es load-bearing (duración de skin, backend, orden de plataformas), primero `adr-recorder`.
   - Los planes se entregan a `to-issues` como slices verticales; el texto completo se pasa al subagente.

4. **Ejemplo concreto (motor)**

   ```dart
   // test/unit/calculator/parser_test.dart
   test('respeta precedencia: 2 + 3 * 4 == 14', () {
     expect(Evaluator().evaluate('2 + 3 * 4'), 14);
   });
   ```

   Comando de verificación: `flutter test test/unit/calculator/parser_test.dart`.

## Commands

```bash
# Crear el plan (fecha real de la sesión)
mkdir -p docs/plans
# docs/plans/2026-11-24-calculadora-normal-cientifica.md

# Verificar que el plan referencia rutas existentes o por crear
grep -o 'lib/[a-z_/]*\.dart' docs/plans/2026-11-24-calculadora-normal-cientifica.md

# Checkout previsto para ejecutarlo
git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
```

## Anti-Patterns

- Planes con tareas de "investigar", "mejorar" o "implementar feature" sin criterio medible.
- Escribir el plan en `.opencode/plans/` y llamarlo plan de entrega.
- Copia de patrones de NestJS/Angular/Leaflet o de FieldOps: aquí solo Clean+MVVM Flutter.
- Planificar anuncios banner/intersticiales o cobrar por usar la calculadora.
- Dejar que la skin modifique el motor de cálculo.
- Saltarse el plan porque "es solo un archivo" cuando la tarea afecta a tres capas.

## Related Skills

- [adr-recorder](../../../.opencode/skills/adr-recorder/SKILL.md) — decide lo load-bearing antes de planificar.
- [to-issues](../../../.opencode/skills/to-issues/SKILL.md) — convierte el plan en slices verticales.
- [using-git-worktrees](../../../.opencode/skills/using-git-worktrees/SKILL.md) — aísla la ejecución del plan.
- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — red → green → refactor por tarea.
- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — define dónde va cada archivo Dart.
