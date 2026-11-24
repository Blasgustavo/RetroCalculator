# ADR-0005: Internacionalización y formato numérico

## Estado

Aceptado | 2026-11-24

## Contexto

El público inicial es peruano y el producto se entrega en varias plataformas, con una tienda cuyo catálogo ampliado se descarga bajo demanda (ADR-0003 y ADR-0004). Los textos, los nombres de las skins y de las calculadoras, y el formato de los números deben ser coherentes entre la app y ese catálogo. España y Latinoamérica no comparten el mismo separador decimal, y un parser estricto convertiría entradas válidas en errores. El motor debe permanecer en Dart puro (ADR-0004), por lo que no puede depender de utilidades de Flutter para formatear.

## Decisión

- Idioma por defecto: **es-PE**.
- **Lote 1:** `en` y `pt-BR`. **Lote 2:** `fr`, `de`, `it`, `ja`, `ko`, `zh-Hans`, `ru` y `es`. **Lote 3:** `ar` y `he`, con soporte **RTL, diferido**.
- **Un ARB por locale**, con **claves idénticas** en todos; la **CI verifica las claves faltantes** y falla si algún locale no cubre el conjunto completo.
- El **formato decimal depende del locale**. El **parser acepta tanto coma como punto** como separador decimal, sin importar el locale activo.
- Los **nombres de skins y de calculadoras son claves de traducción**, también en el **catálogo descargado**: el manifiesto referencia claves, no textos literales.
- El motor sigue siendo **Dart puro** y **recibe la regla de formato por inyección**, sin importar Flutter.
- Con Flutter 3.44+, los locales con región (`es-PE`, `pt-BR`) exigen un **ARB base** (`es`, `pt`) como fallback técnico. Se incluyen en el lote 1 solo para herencia de recursos y **no se añaden al selector de locale** hasta el lote 2. El Dart generado vive en `lib/l10n/` y se commitea; no se usa el paquete sintético `flutter_gen`, retirado en este SDK.

## Consecuencias

- Positivas: una sola fuente de textos por clave evita divergencias entre la app y el catálogo descargado.
- Positivas: la CI detecta traducciones incompletas antes de publicar; aceptar coma y punto reduce errores de entrada en es-PE y pt-BR.
- Positivas: el motor se mantiene testeable sin Flutter al recibir la regla de formato como dependencia.
- Negativas: cada locale nuevo obliga a completar todas las claves del ARB y a pasar la verificación de CI.
- Negativas: el catálogo descargado debe respetar el esquema de claves y su versión debe coordinarse con los ARB de la app.
- Negativas: el lote 3 (RTL) requerirá revisar layout, alineación y dirección de botones antes de habilitarlo.
- Riesgo mitigado: la regla de formato se inyecta en el motor; no se introduce dependencia de Flutter en `lib/features/calculator/domain/`.
- Positivas: `flutter gen-l10n` y `flutter pub get` funcionan con el SDK instalado y el Dart generado es revisable en PR.
- Negativas: el repo tiene cinco ARB aunque solo tres sean seleccionables en el lote 1; la CI debe verificar las 40 claves también en `es` y `pt`.

## Alternativas descartadas

- **Textos en español hardcodeados:** impide publicar los lotes 1 y 2 y rompe la coherencia con el catálogo descargado.
- **Un único ARB con fallback silencioso:** oculta las claves faltantes y deja textos sin traducir sin que CI lo detecte.
- **Usar paquetes de formato dependientes de Flutter dentro del motor:** rompe la decisión de Dart puro del ADR-0004.
- **Parser que acepte solo punto:** rechaza la coma decimal habitual en es-PE y pt-BR.
- **Nombres de skins y calculadoras como literales en el manifiesto:** no se pueden traducir y divergen de los ARB de la app.
- **Publicar RTL en el lote 1:** añade coste de layout y validación antes de tener estables los primeros locales.
- **Generar bajo `.dart_tool/flutter_gen/` con import relativo:** deja el Dart generado fuera del repo y rompe la reproducción en CI.
- **Exigir un SDK de Flutter anterior:** no está instalado y retrasaría el MVP sin cambiar el resultado.

## Referencias

- [ADR-0003: tienda de skins y calculadoras](0003-tienda-skins-y-calculadoras.md) — catálogo y nombres de artículos.
- [ADR-0004: arquitectura modular y generador](0004-arquitectura-modular-y-generador.md) — motor en Dart puro y manifiesto descargable.
- Documento de idea: `C:/Users/qty94/.opencode/plan/retrocalculator-idea.md` (v0.5).
- [Plan del MVP Android](../plans/2026-11-24-mvp-android-calculator.md) — implementación de i18n en los slices S2 y S4.
