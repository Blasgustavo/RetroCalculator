# ADR-0006: Monetización del catálogo

## Estado

Aceptado | 2026-11-24

## Contexto

ADR-0001 y ADR-0003 fijaron el modelo temporal y la tienda, pero dejaron abiertos precios, duraciones, renovación, expiración offline e historial. ADR-0004 definió un catálogo mixto con manifiesto descargable y ADR-0005 hizo traducibles sus nombres. Hay que cerrar esos parámetros sin tocar la regla de oro: la calculadora base (normal y científica) es gratuita y siempre funcional. La suscripción que se decide aquí no reabre la descartada en ADR-0001: aquella era a la calculadora completa; esta es al catálogo cosmético y funcional y nunca bloquea la base. El orden de plataformas sigue siendo Android → Windows → iOS (ADR-0002).

## Decisión

- **Precios de compra:** skins a **S/ 0.90** y calculadoras funcionales a **S/ 1.90**, ambos por **30 días**.
- **Suscripción al catálogo:** **S/ 4.90 mensual** y **S/ 39.90 anual**. Habilita **todo el catálogo** (cosmético y funcional) y **nunca la calculadora base**, que permanece gratuita y disponible sin suscripción.
- La **duración de cada artículo la define el manifiesto/generador** (ADR-0004); para recompensas por anuncio se aplican **24 horas por defecto** cuando el manifiesto no declara otra duración.
- La **renovación acumula el nuevo plazo desde la fecha de expiración**, no desde el momento del pago.
- Existe un **periodo de gracia al expirar sin red**: el acceso se mantiene temporalmente hasta poder validar de nuevo.
- La publicidad sigue siendo **solo anuncios recompensados**: **sin banners ni intersticiales** (ADR-0001).
- El **historial es local, persistente y global**: guarda las **últimas 50 entradas**, etiquetadas por calculadora.
- La **telemetría se limita a contadores locales**, **sin envío** a ningún servidor.

## Consecuencias

- Positivas: precios y duraciones quedan cerrados y verificables en el manifiesto; la renovación acumulada no penaliza al usuario que renueva antes de vencer.
- Positivas: el periodo de gracia evita perder el acceso por quedarse sin red justo al expirar; el historial acotado a 50 entradas limita el almacenamiento.
- Positivas: no hay envío de telemetría ni backend nuevo, y la base gratuita queda intacta.
- Negativas: la suscripción exige integrar IAP y gestión de renovación por plataforma; en Windows no hay IAP móvil (ADR-0002) y habrá que resolverlo en su fase.
- Negativas: el manifiesto pasa a ser fuente de duración, por lo que su checksum y versión (ADR-0004) deben validarse antes de aplicar entitlements.
- Negativas: acumular desde la expiración y conceder gracia requieren reloj fiable y persistencia consistente en `lib/features/monetization/entitlements/`.
- Riesgo mitigado: ADR-0001 descartó la suscripción a la calculadora completa; la suscripción de este ADR es al catálogo cosmético/funcional y **no bloquea la calculadora base**.

## Alternativas descartadas

- **Suscripción a la calculadora completa:** ya descartada en ADR-0001; la de aquí solo cubre el catálogo y no limita la base.
- **Banners e intersticiales:** contradicen la política de anuncios recompensados del ADR-0001.
- **Duración fija en código:** ignora el manifiesto/generador del ADR-0004 y obligaría a recompilar para ajustar cada artículo.
- **Renovación a partir del pago:** descarta el tiempo no consumido del plazo anterior.
- **Expirar sin red sin periodo de gracia:** causa pérdida de acceso por una condición de conectividad, no por decisión del usuario.
- **Historial en un backend o ilimitado:** requiere el backend diferido y crece sin control; el historial es local y se recorta a 50 entradas.
- **Enviar telemetría a un servidor:** añade dependencia de red y recopilación de datos sin beneficio para el modelo acordado.

## Referencias

- [ADR-0001: skins temporales y anuncios](0001-skins-temporales-y-anuncios.md) — regla de oro y descartes vigentes.
- [ADR-0002: orden de plataformas](0002-orden-plataformas.md) — Android → Windows → iOS y consecuencias por plataforma.
- [ADR-0003: tienda de skins y calculadoras](0003-tienda-skins-y-calculadoras.md) — categorías y modelo temporal común.
- [ADR-0004: arquitectura modular y generador](0004-arquitectura-modular-y-generador.md) — manifiesto, checksum y control de versión.
- [ADR-0005: internacionalización y formato numérico](0005-internacionalizacion-y-formato-numerico.md) — nombres traducibles del catálogo.
- Documento de idea: `C:/Users/qty94/.opencode/plan/retrocalculator-idea.md` (v0.5).
