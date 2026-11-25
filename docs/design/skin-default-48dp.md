# Cambio 44 → 48 dp de la skin default

V1 del RetroDesign Studio fija `keyMinHeight: 48` en la skin `default` de `design/app.design.json` y reutiliza `minTouchTarget` de `lib/core/design_system/token_validation.dart` como mínimo táctil innegociable.

`SkinTokens.classicAmber` permanece en 44 dp y no se modifica en este slice: es el alias temporal heredado del MVP. La migración de la app a la skin generada y la actualización de los 9 goldens quedan diferidas a V9 (T56 y T57). En V1 no hay goldens en el repositorio y ningún test heredado cambia de expectativa por este motivo.

El validador `tool/design/validate.dart` rechaza cualquier skin con `keyMinHeight < 48` y cualquier `dimensions.minTouchTarget != 48`, sin duplicar la regla: ambos valores proceden de `token_validation.dart`.
