# ADR-0013: Orquestación paralela con modelos gratuitos delegados

## Estado
Aceptado | 2026-11-25

## Contexto

El orquestador debe operar con el modelo que se seleccione desde la UI de OpenCode, sin que la configuración del repo lo sobreescriba. Al mismo tiempo, las actividades delegadas deben ejecutarse en paralelo con modelos gratuitos del proveedor `opencode`, para ganar tiempo sin perder calidad. El único modelo de pago del proveedor es `opencode-go`; no se van a añadir proveedores, claves API ni servicios nuevos.

La elección también debe tener en cuenta el contexto disponible, la salida máxima, los esfuerzos de razonamiento y la política de datos de cada modelo. Según `https://opencode.ai/inference/v1/models`, los modelos gratis van de 64k a 1,048,576 tokens de contexto; OpenCode no publica cuota mensual ni límite de peticiones para el tier gratuito, así que no se asume ninguna cifra. Los modelos gratuitos solo funcionan dentro del harness de OpenCode: otros arneses reciben HTTP `403` aunque usen una clave de Console.

## Decisión

1. El orquestador y `build` **no declaran `model` ni `variant`**: heredan el modelo de la sesión elegido en la UI. El `model` raíz, `opencode/beam-free`, es solo el fallback cuando no hay selección en la UI.
2. **Todos los subagentes declaran su modelo de forma explícita**, para que nunca hereden un modelo de pago si la UI está en uno. Se usan únicamente modelos `opencode/*` con coste 0:

   | Agente | Modelo | Variante | Contexto | `open_weights` |
   |---|---|---|---:|---|
   | `calculator`, `monetization` | `opencode/deepseek-v4.1-flash-free` | `high` | 200,000 | sí |
   | `platform`, `infra` | `opencode/flint-40b-free` | `high` | 262,144 | sí |
   | `testing` | `opencode/flint-40b-free` | `medium` | 262,144 | sí |
   | `skins`, `docs` | `opencode/mimo-v2.6-flash-free` | — | 200,000 | sí |
   | `general` (revisiones) | `opencode/beam-free` | `max` | 1,048,576 | sí |
   | `explore` | `opencode/hy4-flash-free` | `high` | 1,048,576 | sí |

3. Las revisiones de **spec** y de **calidad** se delegan en `general` con `opencode/beam-free#max`: 1M de contexto para plan, diff y logs de CI, 131k de salida, esfuerzo máximo, `open_weights` y sin entrenamiento con el código. `general` y `explore` tienen denegadas `write` y `patch`.
4. El paralelismo sigue **`dispatching-parallel-agents` + `subagent-driven-development`**: un worktree por slice, lista disjunta de archivos, subagentes en background con el texto completo de la tarea, estados `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`, y ningún avance con issues abiertos. Si dos slices tocan el mismo archivo, se serializan.
5. Antes de mergear: revisión de spec, revisión de calidad, `flutter analyze`, `flutter test` y CI en verde. Ante un fallo se aplica `systematic-debugging`; no se parchean síntomas.
6. La configuración se mantiene en formato V1 (`agent`, `prompt`, `permission`, `model` y `variant` separados) porque OpenCode V2 lo normaliza sin reescribir el archivo. No se mezcla con `agents`/`#variant` dentro del mismo agente.

## Consecuencias

- Positivas: el modelo de la UI manda en la coordinación; la ejecución se reparte entre modelos gratuitos con distinta capacidad de razonamiento; las revisiones tienen contexto suficiente; los subagentes no pueden convertirse en gasto aunque la UI use un modelo de pago.
- Negativas: no hay cuota ni SLA publicado para el tier gratuito; algunos modelos (`flint-40b-free`, `nemotron-*`) conservan datos para mejorar, por lo que no se les envía código confidencial; el root y la UI pueden diferir hasta que se inicie una sesión nueva o se use `/models`.
- Neutras: `general` y `explore` no editan archivos; el formato V1 seguirá vigente hasta una migración explícita a V2.

## Alternativas descartadas

- Fijar `model` en `orchestrator` o `build`: elimina el control del modelo desde la UI.
- Dejar que los subagentes hereden el modelo de la sesión: si la UI selecciona un modelo de pago, la delegación también lo sería.
- Usar `opencode-go`, modelos de otros proveedores o una clave de Console: el usuario pidió expresamente no añadir más cosas.
- Un único modelo para todas las actividades: renuncia al paralelismo especializado y al contexto amplio en revisiones.
- Cambiar de harness (Claude Code, Codex, Hermes, Pi, Raycast): los modelos gratuitos devuelven `403` fuera de OpenCode.

## Referencias

- `.opencode/opencode.json` y `.opencode/agents/orchestrator.md`.
- Skills `subagent-driven-development`, `dispatching-parallel-agents`, `using-git-worktrees` y `verification-before-completion`.
- `https://opencode.ai/docs/agents/`, `https://opencode.ai/docs/migrate-v1/` y `https://opencode.ai/docs/console/harnesses/`.
- `https://opencode.ai/inference/v1/models` (contexto, salida, `open_weights` y coste).
- `docs/plans/2026-11-24-design-studio-v2.md` (V4, T21–T28).
