# ADR-0004: Arquitectura modular y generador de skins

## Estado

Aceptado | 2026-11-24

## Contexto

ADR-0003 amplió la tienda con calculadoras funcionales y fijó un generador interno de skins. Sin una arquitectura común, cada calculadora nueva tendría su propio motor y cada skin podría terminar modificando operaciones, con resultados divergentes y tests duplicados. El catálogo también debe poder crecer sin inflar el binario ni exigir una nueva versión de la app para cada tema. La calculadora normal y la científica siguen siendo la base gratuita (ADR-0001 y ADR-0003) y el orden de entrega sigue siendo Android → Windows → iOS (ADR-0002).

## Decisión

- **Un solo motor de cálculo** en `lib/features/calculator/domain/`, escrito en **Dart puro**, sin dependencias de Flutter ni de la UI. Todas las calculadoras comparten ese motor.
- El motor se organiza en **capacidades reutilizables**: básicas, científicas, programador (**bitwise, bases y ancho de palabra**), financiero y estadístico. La capacidad **gráfica queda diferida** y no forma parte de esta decisión de implementación.
- Cada calculadora funcional se modela como un **perfil declarativo** que activa capacidades ya registradas; **no se escribe una clase por calculadora**. Solo una capacidad verdaderamente nueva añade código al dominio, con contrato estable y tests propios. Esta decisión prevalece sobre la redacción de ADR-0003 que hablaba de dominio propio por calculadora.
- Los **perfiles de calculadora son declarativos y generados**: solo referencian **IDs de capacidades** y definen **layout y formato**. No contienen lógica de cálculo.
- Las **skins se componen por combinación de módulos**: paletas × displays × botones × fondos, con **validación de contraste y de tamaño táctil** antes de publicarse.
- El generador es **manual**: `dart run tool/skins/generate.dart`. Publica código Dart en `lib/core/design_system/generated/` y un **manifiesto descargable**; **nunca emite código del motor**.
- El catálogo es **mixto**: una **base compilada en la app** (normal, científica y tema LCD clásico) y un **catálogo ampliado descargable bajo demanda**, con **checksum en el manifiesto**, **caché de la última versión válida** y **control de versión**.
- Añadir una **capacidad nueva** requiere una **actualización de la app**; el manifiesto solo puede combinar capacidades ya compiladas.
- El orden de plataformas permanece **Android → Windows → iOS** (ADR-0002).

## Consecuencias

- Positivas: un único motor centraliza el comportamiento y los tests; dos calculadoras no pueden divergir en el resultado de la misma operación.
- Positivas: los perfiles declarativos permiten crear variantes sin escribir cálculo, y las skins pasan validación de contraste y tamaño táctil por construcción.
- Positivas: la base compilada funciona sin red; el catálogo ampliado crece sin inflar el binario y el checksum más la caché evitan usar definiciones corruptas.
- Negativas: el generador introduce un paso manual (`tool/skins/generate.dart`) que hay que ejecutar y revisar antes de publicar tokens o manifiesto.
- Negativas: el catálogo descargado exige validar checksum y versión, gestionar la caché y decidir qué hacer cuando falla la descarga.
- Negativas: una capacidad nueva no puede entregarse solo con un manifiesto: necesita una versión nueva de la app, aunque los temas sí puedan descargarse.
- Riesgo mitigado: el generador nunca toca `lib/features/calculator/domain/`; las skins consumen `lib/core/design_system/generated/`, no el motor.

## Alternativas descartadas

- **Un motor por calculadora:** duplica lógica y tests, y permite resultados distintos para la misma operación.
- **Perfiles que incluyan código de capacidades en lugar de IDs:** acopla la configuración al motor y abre la puerta a que una skin altere el cálculo.
- **Generador en runtime dentro de la app:** contradice el ADR-0003 (herramienta de equipo, no editor de usuario) y añade superficie de carga de definiciones externas antes del MVP.
- **Catálogo totalmente remoto:** la base dejaría de funcionar offline y dependería de la red para calcular o mostrar el tema gratuito.
- **Catálogo totalmente compilado:** cada skin exigiría una nueva versión de la app y el binario crecería sin límite.
- **Capacidades descargables que traigan código del motor:** exigiría ejecutar código externo y rompería el motor en Dart puro sin Flutter.

## Referencias

- [ADR-0001: skins temporales y anuncios](0001-skins-temporales-y-anuncios.md) — regla de oro: calcular siempre gratis.
- [ADR-0002: orden de plataformas](0002-orden-plataformas.md) — Android → Windows → iOS.
- [ADR-0003: tienda de skins y calculadoras](0003-tienda-skins-y-calculadoras.md) — origen del generador y de los tipos funcionales.
- [Arquitectura](../architecture.md) — Clean Architecture + MVVM y reglas de dependencia.
- Documento de idea: `C:/Users/qty94/.opencode/plan/retrocalculator-idea.md` (v0.5).
