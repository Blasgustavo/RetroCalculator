---
name: orchestrator-agent
description: >
  Coordina el trabajo de RetroCalculator: elige el skill correcto, reparte tareas entre los
  subagentes (calculator, skins, monetization, platform, testing, docs, infra) y controla el
  flujo plan → worktree → TDD → review → PR a main. Trigger: tareas que cruzan dominios,
  decisión de qué skill invocar, delegación de trabajo o revisión global del flujo.
auto_invoke: orquestador, coordinar, delegar, cross-domain, qué skill usar, repartir tareas, revisar flujo
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 1, last_used: "2026-11-25", success_rate: 1.0 }
  dependencies: [skill-sync, sync-agents, verification-before-completion, flutter-standards]
  status: active
  category: meta
---

## TL;DR

Antes de escribir código, carga `flutter-standards`. Toda tarea > 15 min pasa por `writing-plans`; ante cualquier error, `systematic-debugging`; antes de decir "listo", `verification-before-completion`. Nunca se auto-invoca `auto-learn` sin confirmación explícita del usuario.

## Purpose

Ser la capa de decisión del proyecto. El orquestador no resuelve directamente cada detalle: identifica el dominio, elige el skill, delega en el subagente adecuado y verifica que el trabajo pase por revisiones antes de llegar a `main`. Mantiene la regla de oro del producto: la calculadora siempre es gratuita y funcional; los anuncios son solo recompensados y las skins son cosméticas y temporales.

## When to Use

- Una petición toca más de un dominio (por ejemplo: "añadir skin que se desbloquea con anuncio y expira").
- Hay que decidir entre varios skills o entre subagencias.
- Hay que revisar que una tarea cumpla el flujo acordado antes de mergear.
- Se detecta un error y hay que ordenar la investigación antes de parchear.

## Critical Patterns

1. **Secuencia obligatoria por dominio**

   | Petición | Skill primero | Subagente |
   |---|---|---|
   | Parser, modos normal/científico | `flutter-standards` → `test-driven-development` | `calculator` |
   | Catálogo, tienda, countdown de skins | `flutter-standards` → `adr-recorder` si cambia el modelo | `skins` |
   | Anuncio recompensado / IAP / expiración | `adr-recorder` → `tdd` | `monetization` |
   | Android → Windows → iOS | `adr-recorder` → `using-git-worktrees` | `platform` |
   | Tests y cobertura del motor | `test-driven-development` | `testing` |
   | Documentación, ADR, planes | `writing-plans` / `adr-recorder` | `docs` |
   | CI, workflows, releases | `git-github-workflow` | `infra` |

2. **Reglas del orquestador (checklist mental)**
   - Cargar `flutter-standards` antes de generar código Dart.
   - Error → `systematic-debugging`, nunca un fix a ciegas.
   - Código generado → preguntar al usuario; solo con confirmación explícita, `auto-learn`.
   - Toda operación Git → `git-github-workflow` (`type(scope): summary` en inglés, cuerpo en español).
   - Tarea > 15 min → `writing-plans` en `docs/plans/YYYY-MM-DD-<feature>.md`.
   - Afirmar completitud → `verification-before-completion` con `flutter analyze` + `flutter test`.
   - Decisión load-bearing → `adr-recorder` en `docs/adr/`.
   - Tarea grande independiente → `subagent-driven-development` + `using-git-worktrees`.
   - Crear/editar skill → `skill-sync` (y `sync-agents` si cambian triggers o prompts).

3. **Ejemplo de descomposición correcta**

   Pedido: "quiero que la skin neón se pueda probar 10 minutos viendo un anuncio".

   ```
   1. adr-recorder        → ADR sobre duración y fuente del entitlement
   2. writing-plans       → docs/plans/2026-11-24-skin-neon-recompensada.md
   3. using-git-worktrees → git worktree add .worktrees/feature-neon-ad -b feature/neon-ad
   4. subagent-driven-development
        ├─ monetization: Entitlement temporal (test unitario primero)
        ├─ skins: consume el estado, sin tocar el motor
        └─ testing: tests de expiración y renovación
   5. verification-before-completion → flutter analyze && flutter test
   6. git-github-workflow → PR a main con Summary/Testing/Checklist
   ```

4. **Límites de delegación**: no despachar dos implementers sobre los mismos archivos; no saltarse `spec reviewer` ni `quality reviewer`; no avanzar con issues abiertos; entregar al subagente el texto completo de la tarea (que no lea el plan desde disco).

5. **Modelo de la UI frente a modelos delegados (verificado el 2026-11-25)**: el modelo elegido en la UI manda en `orchestrator` y `build`, así que esos agentes no declaran `model` ni `variant`; el `model` raíz es solo fallback. Cada subagente declara un modelo `opencode/*` gratuito explícito: si hereda el modelo de la sesión y el usuario eligió uno de pago, la delegación también sería de pago. Las revisiones de spec y calidad van juntas y en background a `general` con `opencode/beam-free#max` (1M de contexto, `open_weights`, sin entrenamiento, sin `write`/`patch`), y la exploración a `opencode/hy4-flash-free#high`. Ver ADR-0013; no añadir proveedores, claves ni harnesses porque los modelos gratuitos devuelven `403` fuera de OpenCode.

## Commands

```bash
# Verificación mínima antes de delegar trabajo de código
flutter pub get
flutter analyze
flutter test

# Aislar la tarea antes de despachar
git worktree add .worktrees/feature-calculator-engine -b feature/calculator-engine
git check-ignore -v .worktrees/

# Estado del flujo
git status --short
git branch --list 'feature/*' 'fix/*'
```

## Anti-Patterns

- Generar código sin haber cargado `flutter-standards` y sin saber si el motor debe seguir puro (sin Flutter).
- Meter lógica de anuncios o de expiración en widgets; la UI solo consume el estado del entitlement.
- Delegar "mejora la calculadora" sin slices verificables ni criterios de aceptación.
- Decir "compila" sin haber ejecutado `flutter analyze` y `flutter test`.
- Llamar a `auto-learn` porque sí, sin que el usuario confirme que el cambio fue correcto.
- Implementar directamente en `main` sin PR ni consentimiento explícito.
- Fijar `model` en `orchestrator` o `build`, o dejar que un subagente herede el modelo de pago elegido en la UI.

## Related Skills

- [writing-plans](../../../.opencode/skills/writing-plans/SKILL.md) — planes con tareas de 2-5 min antes de implementar.
- [skill-sync](../../../.opencode/skills/skill-sync/SKILL.md) — refleja los skills en `AGENTS.md`.
- [sync-agents](../../../.opencode/skills/sync-agents/SKILL.md) — propaga cambios a prompts de agentes.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — ejecución con reviews.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — evidencia antes de cerrar.
- [auto-learn](../../../.opencode/skills/auto-learn/SKILL.md) — aprendizaje solo tras confirmación.
