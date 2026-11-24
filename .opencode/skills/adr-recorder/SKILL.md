---
name: adr-recorder
description: >
  Registra decisiones load-bearing de RetroCalculator en docs/adr/NNNN-<slug>.md con
  contexto, decisión y consecuencias: motor propio, backend diferido, skins temporales,
  solo anuncios recompensados y orden Android → Windows → iOS. Trigger: decisión
  arquitectónica o de negocio que cambiará el código o que no debe redebaturse.
auto_invoke: ADR, decisión arquitectónica, load-bearing, documentar decisión, por qué decidimos, backend, duración de skin
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [writing-plans, orchestrator-agent]
  status: active
  category: meta
---

## TL;DR

Si la decisión afecta a varias capas o al modelo de negocio, se escribe un ADR en `docs/adr/` antes de planificar. Formato corto: Contexto → Decisión → Consecuencias → Alternativas descartadas. El ADR se referencia desde el plan y desde el código cuando aplica.

## Purpose

Evitar que futuros agentes reabran decisiones ya tomadas (por ejemplo, proponer banners, cobrar por calcular o cambiar el orden de plataformas). Deja constancia del porqué, no solo del qué.

## When to Use

- Elegir backend (Firebase, Supabase o solo local) para catálogo y entitlements.
- Fijar duración de las skins y de la renovación, o la rewarded frente a IAP.
- Definir el estilo retro definitivo del `core/design_system/`.
- Decidir el modelo de monetización de Windows.
- Cambiar la estrategia de expiración offline o el periodo de gracia.
- Cualquier decisión que `writing-plans` o `orchestrator-agent` marque como load-bearing.

## Critical Patterns

1. **Ubicación y numeración**

   ```
   docs/adr/0001-modelo-negocio-skins-temporales.md
   docs/adr/0002-orden-plataformas.md
   docs/adr/0003-backend-entitlements.md
   docs/adr/0004-estilo-retro.md
   ```

   Secuencia `NNNN-<slug>.md` en inglés; contenido en español. Nunca se renombra un ADR aceptado: si cambia la decisión, se escribe uno nuevo que lo supera.

2. **Plantilla**

   ```markdown
   # ADR-0003: Backend para entitlements

   ## Estado
   Aceptado | 2026-11-24

   ## Contexto
   El catálogo de skins y la expiración deben funcionar offline; el backend está diferido.

   ## Decisión
   Almacenar entitlements en local primero y validar con <proveedor> al reconectar.

   ## Consecuencias
   - Positivas: sin bloqueos para calcular; expiración predecible.
   - Negativas: requiere reloj fiable y política de gracia.

   ## Alternativas descartadas
   - <opción>: motivo concreto.

   ## Referencias
   docs/plans/2026-11-25-skins-temporales.md
   ```

3. **Decisiones ya registradas en el documento de idea (no reabrir sin ADR nuevo)**
   - Skins cosméticas desbloqueables por anuncio recompensado o pago, **ambas temporales**.
   - Solo anuncios recompensados: **sin banners ni intersticiales**.
   - Backend: **diferido**.
   - Estilo retro: **sin definir**.
   - Orden: **Android → Windows → iOS**.
   - La calculadora es gratuita siempre.

4. **Conectar con el código**
   - Un ADR de diseño retro apunta a `lib/core/design_system/` y no autoriza cambiar el motor.
   - Un ADR de entitlements apunta a `lib/features/monetization/entitlements/`; la UI solo consume estado.
   - Un ADR de plataforma apunta a `lib/platform/` y al workflow `.github/workflows/` correspondiente.
   - Todo plan que dependa del ADR lo cita en su sección `Contexto`.

## Commands

```bash
mkdir -p docs/adr
# crear docs/adr/0003-backend-entitlements.md con la plantilla anterior

# ver ADRs existentes y numeración
ls docs/adr

# comprobar referencias desde planes
grep -R 'ADR-000' docs/plans docs/README.md
```

## Anti-Patterns

- Documentar decisiones triviales (nombre de una variable) como ADR.
- Escribir el ADR después de haber implementado la decisión sin poder explicar el porqué.
- Reabrir "solo banners" o "cobrar por el modo científico" sin un ADR nuevo que lo anule.
- ADRs sin Estado, Consecuencias ni Alternativas descartadas.
- Copiar formatos de otros stacks o dominios (NestJS, Angular, Leaflet, FieldOps).
- Guardar ADRs en `.opencode/plans/` en lugar de `docs/adr/`.

## Related Skills

- [writing-plans](../../../.opencode/skills/writing-plans/SKILL.md) — cita el ADR en el contexto del plan.
- [orchestrator-agent](../../../.opencode/skills/orchestrator-agent/SKILL.md) — exige ADR para decisiones load-bearing.
- [to-issues](../../../.opencode/skills/to-issues/SKILL.md) — decide qué slices son HITL según el ADR.
- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — traduce la decisión a estructura de carpetas.
