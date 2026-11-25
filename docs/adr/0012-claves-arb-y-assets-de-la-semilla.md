# ADR-0012: Claves ARB y assets de la semilla del Studio

## Estado
Aceptado | 2026-11-25

## Contexto

La semilla v2 de `design/app.design.json` usa claves de texto con punto (`ads.reward.copy`, `price.skin`, `price.calculator`, `price.monthly`, `price.yearly`). `flutter gen-l10n` las rechaza: los nombres de recurso ARB deben ser identificadores Dart válidos (camelCase, sin caracteres no alfanuméricos). Además, esas siete claves y `skinDefaultName`/`modeIgv` no existen en los cinco ARB actuales, que tienen exactamente 44 claves. La semilla también referencia `fondo_panel.png` y cuatro WAV que los slices V6 y V10 generarán, pero hoy no existen. El validador de V1 debe fallar si falta una clave ARB o un asset, y la semilla debe ser válida.

## Decisión

1. Las siete claves nuevas se escriben en camelCase válido: `skinDefaultName`, `modeIgv`, `adsRewardCopy`, `priceSkin`, `priceCalculator`, `priceMonthly` y `priceYearly`. Se añaden a los cinco ARB (44 → 51 claves) y se actualiza `test/unit/i18n/arb_keys_test.dart`. El esquema v2 y el plan quedan corregidos en consecuencia.
2. V1 crea placeholders mínimos y versionados en `design/assets/`: un PNG 1×1 (`fondo_panel.png`) y cuatro WAV PCM silenciosos (`key_tap.wav`, `equals.wav`, `error.wav`, `skin_change.wav`). El validador comprueba su existencia y metadatos; V6 y V10 regenerarán los archivos definitivos con el mismo nombre estable. No se modifica `pubspec.yaml` ni `assets/catalog/`.

## Consecuencias

- Positivas: `gen-l10n` sigue funcionando, el validador aplica reglas reales sin listas de excepción y la semilla pasa `dart run tool/design/validate.dart`.
- Negativas: V1 toca `lib/l10n/` y un test heredado de forma intencional (44 → 51); los placeholders son temporales y deben sustituirse en V6/V10 sin cambiar sus ids.

## Alternativas descartadas

- Mantener las claves con punto: `flutter gen-l10n` falla con «Resources names must be valid Dart method names».
- Lista de claves pendientes de i18n con avisos no bloqueantes: debilita la validación de forma permanente y ningún slice posterior retira la excepción.
- Diferir la comprobación de assets a V6/V10: deja el caso «imagen inexistente» de T9 sin test y permite que una semilla inválida pase el validador.

## Referencias

- `docs/plans/2026-11-24-design-studio-v2.md` (semilla v2, T5–T10).
- `lib/core/design_system/token_validation.dart`.
