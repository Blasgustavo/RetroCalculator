# Documentación de RetroCalculator

Índice de la documentación técnica del proyecto.

- [Arquitectura](architecture.md) — Clean Architecture + MVVM, estructura de `lib/` y reglas de dependencias.
- [Decisiones arquitectónicas (ADR)](adr/) — decisiones load-bearing del proyecto.
  - [0001 — Skins temporales y anuncios](adr/0001-skins-temporales-y-anuncios.md)
  - [0002 — Orden de plataformas](adr/0002-orden-plataformas.md)
  - [0003 — Tienda de skins y calculadoras](adr/0003-tienda-skins-y-calculadoras.md)
  - [0004 — Arquitectura modular y generador](adr/0004-arquitectura-modular-y-generador.md)
  - [0005 — Internacionalización y formato numérico](adr/0005-internacionalizacion-y-formato-numerico.md)
  - [0006 — Monetización del catálogo](adr/0006-monetizacion-del-catalogo.md)
  - [0007 — Perfiles de calculadora y registro de capacidades](adr/0007-perfiles-calculadora-registro-capacidades.md)
  - [0008 — Sonidos locales con audioplayers](adr/0008-sonidos-locales-audioplayers.md)
  - [0009 — Fórmulas declarativas con variables](adr/0009-formulas-declarativas-con-variables.md)
  - [0010 — Publicación remota del catálogo](adr/0010-publicacion-remota-del-catalogo.md)
  - [0011 — Editor visual sobre base Dart con adaptador](adr/0011-editor-visual-base-dart-adapter.md)
  - [0012 — Claves ARB y assets de la semilla](adr/0012-claves-arb-y-assets-de-la-semilla.md)
- [Planes de implementación](plans/) — planes de ejecución por funcionalidad.
  - [MVP Android de la calculadora](plans/2026-11-24-mvp-android-calculator.md)
  - [CI de Android](plans/2026-11-24-android-ci.md)
  - [LCD clásica](plans/2026-11-25-skins-lcd-clasica.md)
  - [RetroDesign Studio v2](plans/2026-11-24-design-studio-v2.md) — sustituye al [plan v1](plans/2026-11-24-design-studio-compiler.md), que queda como registro histórico; sus identificadores `S7`–`S10` y `D7`–`D10` no se mantienen.
- [Cambio 44 → 48 dp de la skin default](design/skin-default-48dp.md) — alcance de V1 y diferimiento de la migración y los goldens a V9.
- [Prompts de mockups](mockups/prompts.md) — pendientes de regenerar por falta de créditos del proveedor de imágenes.
- [AGENTS.md](../AGENTS.md) — reglas globales del proyecto y tabla de triggers del orquestador.

La documentación y la conversación se escriben en español; los títulos de commits y PRs, en inglés.
