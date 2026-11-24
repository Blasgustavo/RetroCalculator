# 0001 — Skins temporales y anuncios

- **Fecha:** 2026-11-24
- **Estado:** Accepted

## Contexto

RetroCalculator es una calculadora gratuita con modos normal y científico. Su propuesta de valor exige que el núcleo de cálculo sea siempre funcional y que la monetización no cobre por calcular ni interrumpa al usuario con publicidad intrusiva. Al mismo tiempo, el proyecto necesita una vía de ingresos y una forma ligera de personalización que no complique el motor ni requiera un backend en esta fase. La identidad retro concreta está aún por definir y no debe bloquear estas decisiones.

## Decisión

- La calculadora es **100 % gratuita** y siempre funcional; nunca se cobra ni se exige publicidad para calcular.
- Las skins son temas **puramente cosméticos** (paleta de colores, tipografía, textura de botones y, eventualmente, sonidos). No alteran el motor de cálculo ni añaden funciones de pago.
- Las skins se desbloquean **por tiempo limitado** mediante dos vías voluntarias: ver un **anuncio recompensado** o realizar un **pago real** (compra integrada). Ambas conducen al mismo beneficio, con distinta duración por definir.
- Al expirar el plazo, la skin se desactiva, vuelve el tema gratuito y se ofrece **renovar** por la misma vía.
- La publicidad se limita **exclusivamente a anuncios recompensados**: sin banners ni intersticiales. El anuncio es siempre voluntario y está ligado a una recompensa explícita.

## Alternativas descartadas

- **Cobrar por el modo científico o por funciones de cálculo:** rompe la regla de oro y degrada la propuesta de valor.
- **Banners e intersticiales:** interrumpen el uso diario y contradicen la política de anuncios.
- **Skins permanentes de pago:** elimina la prueba sin compromiso y el ciclo de renovación buscado.
- **Suscripción a la calculadora completa:** introduce fricción y una dependencia de backend innecesaria en esta fase.
- **Anuncios recompensados para desbloquear funciones:** convertiría la publicidad en requisito para calcular.

## Consecuencias

- `features/monetization/entitlements/` es la fuente de verdad de duración, expiración y renovación; la UI solo consume su estado.
- `features/monetization/ads/` y `features/monetization/iap/` son dos caminos distintos que producen el mismo entitlement.
- Las skins dependen de `core/design_system/`, nunca del motor en `features/calculator/domain/`.
- Hay que definir las duraciones de cada vía, la validación offline al vencer y un eventual periodo de gracia antes de implementar la monetización.
- AdMob y las IAP móviles solo aplican en Android e iOS; el modelo de escritorio queda para su fase (ver ADR 0002).

## Enmienda

Esta decisión se amplía en [ADR-0003: tienda de skins y calculadoras](0003-tienda-skins-y-calculadoras.md): la tienda incluye también variantes cosméticas y calculadoras funcionales, todas con el mismo modelo temporal. La calculadora base sigue siendo gratuita y las skins siguen sin alterar el motor.
