---
name: skill-sync
description: >
  Regenera la tabla Trigger → skill → ruta de AGENTS.md a partir del frontmatter de los
  16 SKILL.md de .opencode/skills/, manteniendo actualizadas descripciones, auto_invoke,
  categorías y dependencias. Trigger: crear, editar o eliminar un skill; invocado por
  orchestrator-agent y sync-agents.
auto_invoke: skill-sync, sincronizar skills, actualizar AGENTS.md, tabla de triggers, regenerar índice de skills
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: []
  status: active
  category: meta
---

## TL;DR

Cada skill tiene un `SKILL.md`. `AGENTS.md` es el índice: si el índice no coincide con los archivos, el auto-invocador falla. Tras crear o editar cualquier skill, regenera la tabla y verifícala.

## Purpose

Mantener una única fuente de verdad para los triggers. El frontmatter (`name`, `description`, `auto_invoke`, `category`, `dependencies`) se escribe en cada skill y se refleja en `AGENTS.md`; así el orquestador sabe qué skill cargar antes de tocar el motor, las skins, los entitlements o la plataforma.

## When to Use

- Se crea uno de los 16 skills iniciales o se añade uno nuevo en su fase (por ejemplo `rewarded-ads`).
- Cambia el `auto_invoke` de un skill (nuevas palabras clave en español).
- Cambia la descripción o la categoría (`meta|workflow|testing|domain|flutter`).
- Antes de un commit que incluya cambios en `.opencode/skills/`.

## Critical Patterns

1. **Leer el frontmatter, no adivinar**

   Para cada `.opencode/skills/*/SKILL.md`, extraer:

   ```yaml
   name: flutter-standards
   description: >  # qué hace + Trigger
   auto_invoke: flutter, dart, clean architecture, mvvm, analyze, test
   category: flutter
   dependencies: []
   ```

2. **Formato de la tabla en `AGENTS.md`**

   ```markdown
   | Trigger (auto_invoke) | Skill | Ruta |
   |---|---|---|
   | flutter, dart, clean architecture, mvvm | flutter-standards | .opencode/skills/flutter-standards/SKILL.md |
   | red, green, refactor, test unitario | test-driven-development | .opencode/skills/test-driven-development/SKILL.md |
   ```

   Mantener también las reglas globales en español: documentación en español, commits/PR en inglés, sin publicidad intrusiva, motor gratuito.

3. **Verificación de integridad**
   - Un `SKILL.md` por directorio; el `name` del frontmatter coincide con el nombre del directorio.
   - `version: "1.0.0"`, `license: Apache-2.0`, `author: RetroCalculator`, `status: active`.
   - `usage: { count: 0, last_used: null, success_rate: 1.0 }` presente.
   - `dependencies` apunta a skills existentes (por ejemplo `orchestrator-agent` depende de `flutter-standards`).
   - Los 16 skills de la sección 3.1 aparecen en la tabla, sin skills de NestJS/Angular/Leaflet/FieldOps.

4. **Ejemplo de salida esperada tras añadir `rewarded-ads`**

   ```markdown
   | anuncio recompensado, recompensa, rewarded, AdMob | rewarded-ads | .opencode/skills/rewarded-ads/SKILL.md |
   ```

   El nuevo skill debe quedar registrado antes de que el subagente `monetization` lo invoque.

## Commands

```bash
# Enumerar skills existentes
ls .opencode/skills

# Extraer nombre, auto_invoke y categoría del frontmatter
grep -H -E '^(name|auto_invoke|category|dependencies):' .opencode/skills/*/SKILL.md

# Comprobar que la tabla de AGENTS.md referencia archivos reales
grep -o '.opencode/skills/[a-z-]*/SKILL.md' AGENTS.md
```

## Anti-Patterns

- Editar `AGENTS.md` a mano sin leer los frontmatters (se pierden triggers nuevos).
- Dejar un skill huérfano que no aparece en la tabla.
- Usar rutas absolutas de Windows en los enlaces; usar siempre `.opencode/skills/<nombre>/SKILL.md`.
- Modificar el cuerpo de los skills durante la sincronización: ese cambio es trabajo de `sync-agents` o del autor del skill.
- Olvidar ejecutar esta sincronización antes de committear cambios en skills.

## Related Skills

- [sync-agents](../../../.opencode/skills/sync-agents/SKILL.md) — propaga el cambio también a los prompts.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — consume la tabla para elegir skills.
- [auto-learn](../../../.opencode/skills/auto-learn/SKILL.md) — actualiza skills y luego sincroniza.
