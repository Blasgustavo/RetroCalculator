# V5 T32 — Editor de fórmulas: autocompletado y botón «Probar»

## Contexto

T29–T31 añadieron `VariableNode`, el evaluador con `variables` y los tests del motor. T33 añadió la validación build-time. El Studio ya valida fórmulas en vivo (`studio_formula_validation.dart`) pero el editor es un `TextField` plano: no ayuda a escribir identificadores ni permite comprobar el resultado sin compilar. T32 cierra esa brecha: autocompletado de `inputs` y funciones permitidas por la capability, más un botón «Probar» que evalúa la fórmula con valores de ejemplo sin ejecutar código del catálogo.

## Alcance

- Incluye: autocompletado en el inspector, botón «Probar» con valores de ejemplo, evaluación con `CalculatorEngine` usando las variables declaradas, tests unit/widget y actualización del checkbox T32 del plan original.
- Excluye: T34 (validación runtime al aplicar catálogo), cambios en el motor, `pubspec.yaml`, goldens y nuevos ARB.

## Arquitectura

- `tool/design/studio/studio_controller.dart`: nuevo método `testProfileFormula(...)` que evalúa con `CalculatorEngine` y devuelve `String?` (null = éxito, texto de error si falla). No muta el documento.
- `tool/design/studio/studio_inspector.dart`: `_FormulaSection` sustituye el `TextField` por un `RawAutocomplete` (o equivalente) y añade el botón «Probar» + línea de resultado.
- El helper de validación existente sigue siendo la única fuente de mensajes de error; la evaluación solo se usa para «Probar».

## Tareas (2-5 min cada una)

- [ ] T32.0 — Añadir `testProfileFormula` al controller.
  Archivo: `tool/design/studio/studio_controller.dart`.
  Firma:
  ```dart
  /// Evalúa [expression] del perfil [profileId] con [values] (valores de
  /// ejemplo para los inputs) y devuelve null si el resultado es finito, o el
  /// código/mensaje del error. No muta el documento ni valida build-time.
  String? testProfileFormula(
    String profileId,
    String name,
    String expression,
    Map<String, num> values,
  );
  ```
  Implementación: obtener perfil; normalizar variables; usar `CalculatorEngine().evaluate(expression, profileCapability, variables: values)`; capturar `CalculatorException` y devolver `error.message`; si el resultado no es finito, devolver `'nonFiniteResult'`.
  Verificar: `flutter test --no-pub test/unit/design/studio_inspector_test.dart`.

- [ ] T32.1 — Autocompletado en el inspector.
  Archivo: `tool/design/studio/studio_inspector.dart`.
  Cambios: envolver el campo de expresión en un `RawAutocomplete<String>` cuyas opciones sean `profile.inputs` + `capability.functions` + `capability.constants`; filtrar por el token actual (último identificador parcial tras un separador no alfanumérico); al seleccionar, reemplazar el token parcial por la opción y actualizar el controller.
  Verificar: `flutter test --no-pub test/unit/design/studio_inspector_test.dart`.

- [ ] T32.2 — Botón «Probar» y línea de resultado.
  Archivo: `tool/design/studio/studio_inspector.dart`.
  Cambios: añadir `ElevatedButton` con key `studio.inspector.formulaTest` y texto «Probar»; al pulsarlo construir un mapa de valores de ejemplo (1 para cada input) y llamar a `controller.testProfileFormula(...)`; mostrar el resultado numérico o el error en un `Text` con key `studio.inspector.formulaResult`.
  Verificar: `flutter test --no-pub test/unit/design/studio_inspector_test.dart`.

- [ ] T32.3 — Tests de regresión.
  Archivo: `test/unit/design/studio_inspector_test.dart` (ampliar).
  Casos: autocompletado ofrece `base` y `tasa` para un perfil con esos inputs; «Probar» con `base*(1+tasa/100)` y valores `base=100, tasa=18` muestra `118`; una fórmula inválida muestra el código de error.
  Verificar: `flutter test --no-pub test/unit/design/studio_inspector_test.dart`.

- [ ] T32.4 — Verificación final.
  Comandos: `flutter analyze --no-pub`, `flutter test --no-pub test/unit test/widget`, `dart format --output=none --set-exit-if-changed`, `git diff --check`. Restaurar `windows/flutter/` tras `pub get`.

- [ ] T32.5 — Actualizar checkbox.
  Archivo: `docs/plans/2026-11-24-design-studio-v2.md`: marcar T32 como `[x]`.

## Riesgos

- `RawAutocomplete` requiere que el campo mantenga el foco y el controlador; cuidar de no perder el agrupamiento de undo (T26).
- La evaluación usa `CalculatorEngine` que normaliza variables; si hay colisión se lanza `duplicateVariable` y se muestra como error.
- Los valores de ejemplo deben ser finitos y no provocar divisiones por cero; usar 1 por defecto y permitir override futuro (T34).
- El Studio importa `lib/`: verificar que no se arrastren dependencias de Flutter en domain (ADR-0014).