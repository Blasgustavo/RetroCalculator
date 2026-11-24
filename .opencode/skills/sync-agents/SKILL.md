---
name: sync-agents
description: >
  Propaga cambios de descripción, triggers o reglas de los skills a los prompts de los agentes
  (.opencode/agents/*.md) y a .opencode/opencode.json, manteniendo alineados orchestrator,
  calculator, skins, monetization, platform, testing, docs e infra. Trigger: editar un skill,
  cambiar un trigger o crear un subagente; siempre junto a skill-sync.
auto_invoke: sincronizar agentes, actualizar prompts, triggers de agentes, nuevo subagente, propagar skill
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [skill-sync, orchestrator-agent]
  status: active
  category: meta
---

## TL;DR

Si cambia un skill, cambian también los prompts que lo invocan. Actualiza `.opencode/agents/*.md` y `.opencode/opencode.json`, y ejecuta `skill-sync` para regenerar la tabla de `AGENTS.md`.

## Purpose

Evitar que los agentes del proyecto sigan instrucciones obsoletas. Los prompts de los subagentes deben reflejar las reglas vigentes de los skills: motor sin Flutter, skins cosméticas, solo anuncios recompensados, entitlements con expiración, plataformas Android → Windows → iOS, commits en inglés con cuerpo en español.

## When to Use

- Se crea o edita el `description` o el `auto_invoke` de un `SKILL.md`.
- Se añade una regla que afecta a un dominio (por ejemplo, "toda skin vence y se renueva").
- Se crea un subagente nuevo o cambian sus permisos (`skill`, `bash`, `task`).
- El orquestador delega una tarea y el subagente no conoce el skill que debe cargar.

## Critical Patterns

1. **Mapa skill → agente (fuente de verdad)**

   | Skill | Agente(s) que deben conocerlo |
   |---|---|
   | `orchestrator-agent` | `orchestrator` |
   | `flutter-standards`, `test-driven-development` | `calculator`, `skins`, `monetization`, `platform`, `testing` |
   | `adr-recorder`, `writing-plans`, `to-issues` | `docs`, `orchestrator` |
   | `using-git-worktrees`, `git-github-workflow` | `infra`, `orchestrator` |
   | `systematic-debugging` | todos |
   | `verification-before-completion` | todos |
   | `auto-learn` | `orchestrator` únicamente |

2. **Procedimiento**
   - Leer el frontmatter del skill modificado (`description`, `auto_invoke`, `dependencies`).
   - Buscar referencias al skill en `.opencode/agents/` y `.opencode/opencode.json`.
   - Reemplazar la regla antigua por la nueva sin inventar dominio ajeno (nada de NestJS/Angular/FieldOps).
   - Verificar que el agente `orchestrator` sigue en modo `primary` y los demás en `subagent`.
   - Ejecutar `skill-sync` para actualizar `AGENTS.md`.
   - Validar con `git diff --stat` que solo cambiaron prompts/configuración previstos.

3. **Ejemplo de regla propagada**

   Si `flutter-standards` incorpora "el motor de cálculo no importa `package:flutter/*`", el prompt de `calculator` debe incluir:

   ```text
   Antes de tocar lib/features/calculator/domain/, carga flutter-standards.
   El parser y el evaluador son Dart puro: sin Flutter, sin widgets, sin BuildContext.
   Verifica con: flutter test test/unit/calculator/
   ```

   Y el prompt de `testing` debe incluir la misma restricción en sus tests unitarios.

## Commands

```bash
# Localizar referencias a un skill en prompts y configuración
grep -R "flutter-standards" .opencode/agents .opencode/opencode.json AGENTS.md

# Comprobar los archivos de agentes presentes
ls .opencode/agents

# Revisar el alcance del cambio antes de commitear
git diff --stat
git status --short
```

## Anti-Patterns

- Actualizar el skill y dejar el prompt del agente con la regla anterior.
- Copiar reglas de otros dominios o stacks en los prompts de RetroCalculator.
- Cambiar el modo de un agente a `primary` por accidente (solo `orchestrator` lo es).
- Sincronizar sin ejecutar después `skill-sync`, dejando `AGENTS.md` desactualizado.
- Meter secretos, tokens de AdMob o credenciales de keystore en los prompts.

## Related Skills

- [skill-sync](../../../.opencode/skills/skill-sync/SKILL.md) — regenera la tabla de triggers en `AGENTS.md`.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — define quién delega y qué reglas manda.
- [auto-learn](../../../.opencode/skills/auto-learn/SKILL.md) — dispara la sincronización tras aprendizaje confirmado.
- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — regla que más se propaga a los agentes.
