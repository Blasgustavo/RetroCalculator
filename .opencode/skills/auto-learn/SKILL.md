---
name: auto-learn
description: >
  Actualiza los skills de RetroCalculator con patrones verificados solo después de que el
  usuario confirme explícitamente que el trabajo fue correcto; incrementa usage, propaga
  con sync-agents y regenera AGENTS.md con skill-sync. Trigger: el usuario confirma
  explícitamente un cambio, tras release o tras una corrección validada.
auto_invoke: auto-learn, autolearn, aprendió, actualizar skill tras confirmación, guardar patrón, retroalimentación confirmada
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [orchestrator-agent, skill-sync, sync-agents, systematic-debugging]
  status: active
  category: meta
---

## TL;DR

El orquestador pregunta si el código fue correcto. Sin confirmación explícita del usuario, **no se invoca este skill**. Con confirmación: extraer el patrón, editar el skill correspondiente, actualizar `usage`, sincronizar agentes y tabla de triggers.

## Purpose

Mejorar el sistema con evidencia validada, no con suposiciones del agente. Un patrón aprendido puede ser, por ejemplo, "siempre testear la precedencia del parser antes del toggle científico" o "todo entitlement se prueba con reloj determinista".

## When to Use

- El usuario dice explícitamente que la implementación fue correcta ("sí, está bien", "confírmalo y guárdalo").
- Tras un release `vX.Y.Z` en el que el usuario validó el resultado.
- Después de un debug confirmado, para añadir el test de regresión como patrón.
- Nunca como paso automático al terminar una tarea.

## Critical Patterns

1. **Gate de confirmación**

   ```text
   Agente: "¿Fue correcto el cambio del motor? Si me confirmas, actualizo el skill."
   Usuario: "Sí, guárdalo."   → proceder
   Usuario: "No / dale una vuelta" → NO proceder; usar systematic-debugging
   Usuario: silencio o "ok" ambiguo → NO proceder; volver a preguntar
   ```

2. **Qué se aprende y dónde se guarda**

   | Patrón verificado | Skill a actualizar |
   |---|---|
   | Precedencia, DEG/RAD, sin `eval` | `flutter-standards` o `test-driven-development` |
   | Estructura `lib/core`, `lib/data`, `lib/features`, `lib/platform` | `flutter-standards` |
   | Flujo de recompensa y expiración | skill de fase `rewarded-ads` / `skin-entitlements` cuando exista |
   | Fallo recurrente y su causa raíz | `systematic-debugging` |
   | Formato de commit o PR | `git-github-workflow` |
   | Regla nueva de orquestación | `orchestrator-agent` + `sync-agents` |

3. **Procedimiento de actualización**

   ```yaml
   metadata:
     usage: { count: 1, last_used: "2026-11-24", success_rate: 1.0 }
   version: "1.0.0"   # se incrementa solo si cambia el contrato del skill
   ```

   - Añadir el patrón a `## Critical Patterns` con ejemplo concreto (Dart/git) y a `## Anti-Patterns` si aplica.
   - Si cambia el `description` o el `auto_invoke`, ejecutar `sync-agents`.
   - Ejecutar siempre `skill-sync` para reflejar el skill en `AGENTS.md`.
   - Verificar con `git diff --stat` que solo se tocó el skill y lo derivado.

4. **Ejemplo de patrón confirmado**

   ```markdown
   - Los tests de `Entitlement` usan un reloj inyectado; nunca `DateTime.now()` directo,
     porque la expiración offline debe ser reproducible.
     Verificado en el slice S3 el 2026-11-24 con `flutter test test/unit/monetization/`.
   ```

5. **Límites**: no aprender reglas de stacks ajenos; no contradecir un ADR aceptado (si el patrón lo contradice, proponer un ADR nuevo); no tocar `AGENTS.md` a mano cuando `skill-sync` puede regenerarlo.

## Commands

```bash
# Comprobar el skill antes y después
grep -n 'usage:\|version:' .opencode/skills/flutter-standards/SKILL.md

# Verificar que la lección ya no rompe el build
flutter analyze && flutter test

# Sincronizar tras la edición
# skill-sync → AGENTS.md ; sync-agents → .opencode/agents/*.md
git diff --stat
```

## Anti-Patterns

- Invocar `auto-learn` sin confirmación explícita del usuario.
- Interpretar un "vale" ambiguo como confirmación.
- Aprender de un cambio que tiene `DONE_WITH_CONCERNS` sin revisarlos.
- Guardar preferencias personales como reglas del proyecto.
- Editar skills sin actualizar `usage`/`version` y sin sincronizar.
- Contradecir ADR-0001 (skins temporales, solo anuncios recompensados) con un patrón aprendido.

## Related Skills

- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — impone la confirmación previa.
- [sync-agents](../../../.opencode/skills/sync-agents/SKILL.md) — propaga la regla aprendida a los prompts.
- [skill-sync](../../../.opencode/skills/skill-sync/SKILL.md) — regenera la tabla de triggers.
- [systematic-debugging](../../../.opencode/skills/systematic-debugging/SKILL.md) — fuente de patrones de causa raíz.
- [adr-recorder](../../../.opencode/skills/adr-recorder/SKILL.md) — evita aprender contra una decisión aceptada.
