---
name: to-issues
description: >
  Convierte un plan de docs/plans/ en vertical slices end-to-end (tracer bullets) listos
  para subagentes, con modo HITL o AFK, criterios de aceptación y contexto completo.
  Trigger: pasar de writing-plans a ejecución, dividir un plan en issues o preparar tareas
  para subagent-driven-development.
auto_invoke: issues, vertical slices, tracer bullet, dividir plan, convertir plan en tareas, HITL, AFK
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [writing-plans, subagent-driven-development]
  status: active
  category: workflow
---

## TL;DR

Un slice vertical es un camino completo y verificable de punta a punta: test → dominio → UI → comando verde. No se crean issues "por capa" (todos los dominios, después todos los tests). Cada issue se entrega con su texto completo al subagente.

## Purpose

Reducir el contexto que necesita un subagente y hacer que cada tarea termine en un estado demostrable. En RetroCalculator un slice puede ser "2 + 3 * 4 respeta precedencia" o "una skin vence y vuelve el tema gratuito", nunca "arreglar el parser" sin criterio.

## When to Use

- Ya existe `docs/plans/YYYY-MM-DD-<feature>.md` y hay que ejecutarlo.
- Hay que decidir qué se supervisa (HITL) y qué se delega sin intervención (AFK).
- Se van a despachar implementers con `subagent-driven-development`.

## Critical Patterns

1. **Corte vertical, no horizontal**

   ❌ Mal: "T1 tests del motor, T2 parser, T3 ViewModel, T4 widgets, T5 entitlements".
   ✅ Bien:

   | Slice | Camino completo | Verificación |
   |---|---|---|
   | S1 | test `2 + 3 * 4 == 14` → parser → estado del display | `flutter test test/unit/calculator/parser_test.dart` |
   | S2 | test DEG/RAD → convertidor → toggle en UI | `flutter test && flutter analyze` |
   | S3 | test expiración → `Entitlement` → cuenta atrás en tienda | `flutter test test/unit/monetization/` |
   | S4 | test recompensa → rewarded ad → entitlement renovado | `flutter test test/unit/monetization/` |

2. **Plantilla de issue**

   ```markdown
   ## Slice S3 — Expiración de skin temporal
   Modo: HITL | AFK
   Contexto: ADR-0001 (skins por tiempo limitado), plan 2026-11-25-skins-temporales.md
   Archivos: lib/features/monetization/entitlements/entitlement.dart,
             test/unit/monetization/entitlement_test.dart
   Criterio de aceptación:
     - isActive es false cuando expiresAt <= DateTime.now()
     - la UI muestra el tema gratuito al vencer
   Comando: flutter test test/unit/monetization/entitlement_test.dart
   Restricción: no tocar lib/features/calculator/domain/
   ```

3. **HITL vs AFK**
   - **HITL**: decisiones load-bearing (duración de la skin, proveedor de ads, backend, precio). Requieren confirmación del usuario y probable ADR previo.
   - **AFK**: tareas con criterio objetivo y comando de verificación: parser, tests, refactors, formatting, CI ya decidido.
   - Regla: si el slice necesita elegir entre "anuncio o pago" o definir duración, es HITL. Si solo implementa lo ya decidido, es AFK.

4. **Entrega al subagente**
   - Pegar el texto íntegro del slice en el prompt; **no** decir "lee el plan desde disco".
   - Incluir la restricción arquitectónica vigente (motor sin Flutter, plugins en `lib/platform/`).
   - Un slice por implementer; dos implementers nunca sobre los mismos archivos.

## Commands

```bash
# Localizar el plan de origen
ls docs/plans

# Verificar que los paths del slice existen o son nuevos previstos
grep -n 'lib/features/monetization/entitlements' docs/plans/2026-11-25-skins-temporales.md

# Comando de aceptación del slice antes de despachar
flutter test test/unit/monetization/entitlement_test.dart
```

## Anti-Patterns

- Issues por capa en lugar de por funcionalidad completa.
- Decir al subagente "abre docs/plans/... y hazlo" en vez de entregar el texto.
- Marcar como AFK una decisión de negocio (duración, precio, backend).
- Crear slices que tocan simultáneamente calculadora y monetización sin un contrato claro.
- Olvidar la restricción de que ninguna skin bloquea el cálculo.

## Related Skills

- [writing-plans](../../../.opencode/skills/writing-plans/SKILL.md) — fuente de los slices.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — ejecuta cada slice con reviews.
- [dispatching-parallel-agents](../../../.opencode/skills/dispatching-parallel-agents/SKILL.md) — reparte slices independientes.
- [adr-recorder](../../../.opencode/skills/adr-recorder/SKILL.md) — resuelve lo HITL antes de dividir.
