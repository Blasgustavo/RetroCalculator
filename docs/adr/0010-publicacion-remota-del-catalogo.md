# ADR-0010: Publicación remota del catálogo y actualización de la app instalada

## Estado
Aceptado | 2026-11-24

## Contexto

El puente `localhost` de la v1 solo servía durante desarrollo. El usuario pidió que la herramienta publique el catálogo y que una app **ya instalada** reciba los cambios. ADR-0003 dejó el backend diferido; esta decisión lo supera únicamente para el catálogo de diseño, no para entitlements, precios ni compras.

## Decisión

1. La herramienta publica paquetes versionados por canal (`prod`, `beta`) en hosting estático: `manifest.json`, tokens, fórmulas y assets (imágenes/sonidos) con checksum SHA-256.
2. El manifiesto se firma con **Ed25519** y la clave pública se fija en la app (paquete `cryptography`, aislado en `lib/platform/catalog/`). El checksum detecta corrupción; la firma detecta falsificación.
3. La app consulta el manifiesto al iniciar y con sondeo periódico configurable; descarga solo si `version` es mayor; verifica firma y checksum; valida tokens, fórmulas, nodos y assets antes de aplicar; guarda la versión aceptada en caché.
4. Si falla cualquiera de esos pasos, se mantiene la última versión válida. Nunca se deja la app sin skin, sin teclado o sin calculadora. La calculadora sigue siendo gratuita.
5. El catálogo remoto contiene **solo datos**: ni código Dart, ni precios, ni entitlements, ni reglas de anuncios distintas de las permitidas (ADR-0001, ADR-0003, ADR-0006). La UI de monetización que publica el Studio es únicamente presentación.
6. No es una actualización instantánea ni universal: depende de que la app arranque o sondee, y de la conectividad. El rollback es la versión local ya verificada.
7. La publicación es una acción explícita del Studio (`Publicar`), con historial de versiones y posibilidad de revertir a una versión anterior firmada.

## Consecuencias

- Positivas: una skin o una calculadora nueva llega a usuarios instalados sin recompilar; el contenido es verificable y reversible; los entitlements siguen siendo autoridad de la tienda.
- Negativas: se añade hosting, firma y lógica de caché/validación en la app; hay que gestionar claves y canales; el efecto no es inmediato; `flutter pub get` añade artefactos nativos que se restauran en `windows/flutter/` durante la fase Android.

## Alternativas descartadas

- **Mantener solo el puente localhost**: útil para desarrollo, pero no actualiza una app instalada.
- **Enviar el catálogo por notificaciones push**: requiere backend stateful y depende de permisos; ADR-0003 sigue diferido para entitlements.
- **Fiar precios/entitlements al catálogo**: permitiría alterar la monetización desde un archivo descargado y rompe ADR-0006.
- **Checksum sin firma**: detecta corrupción, pero no impide que un tercero sustituya el catálogo.

## Referencias

- `docs/plans/2026-11-24-design-studio-v2.md`
- `docs/adr/0001-skins-temporales-y-anuncios.md`
- `docs/adr/0003-tienda-skins-y-calculadoras.md`
- `docs/adr/0004-arquitectura-modular-y-generador.md`
