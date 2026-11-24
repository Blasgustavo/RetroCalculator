---
name: test-driven-development
description: >
  Aplica red → green → refactor en RetroCalculator: escribe primero un test unitario que
  falle, añade el código mínimo para pasarlo y refactoriza sin cambiar el comportamiento,
  con foco en el motor de cálculo y los entitlements temporales. Trigger: nueva lógica, bug,
  parser, expiración de skins o antes de implementar un slice.
auto_invoke: TDD, test primero, red green refactor, escribir test, falla el test, unit test, cobertura del motor
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: [flutter-standards, verification-before-completion, systematic-debugging]
  status: active
  category: testing
---

## TL;DR

Test que falla → código mínimo → test verde → refactor → commit. El motor de cálculo se prueba con Dart puro en `test/unit/calculator/`; la expiración de skins en `test/unit/monetization/`.

## Purpose

Asegurar que cada regla del negocio tiene una prueba ejecutable: precedencia de operadores, DEG/RAD, división por cero, expiración y renovación de entitlements. Evita que el código se escriba para "parecer" correcto sin verificarlo.

## When to Use

- Implementar o cambiar el parser/evaluador.
- Añadir operaciones científicas (seno, coseno, log, factorial).
- Implementar `Entitlement` y su expiración.
- Corregir un bug (el test de regresión se escribe primero).
- Ejecutar cualquier slice de `subagent-driven-development`.

## Critical Patterns

1. **Ciclo estricto por comportamiento**

   ```bash
   # RED: crear el test y verlo fallar
   flutter test test/unit/calculator/parser_test.dart

   # GREEN: código mínimo en lib/features/calculator/domain/
   flutter test test/unit/calculator/parser_test.dart

   # REFACTOR: mantener el test en verde
   flutter analyze && flutter test
   ```

   No se escribe implementación antes de ver el test fallar por la razón esperada.

2. **Ejemplo real: precedencia (RED)**

   ```dart
   // test/unit/calculator/parser_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:retrocalculator/features/calculator/domain/evaluator.dart';

   void main() {
     test('respeta precedencia de operadores', () {
       expect(Evaluator().evaluate('2 + 3 * 4'), 14);
     });
   }
   ```

   Fallo esperado: `type 'Evaluator' is not defined` o resultado 20. Después se implementa solo lo suficiente en `lib/features/calculator/domain/evaluator.dart`.

3. **Ejemplo real: expiración (RED)**

   ```dart
   // test/unit/monetization/entitlement_test.dart
   test('la skin vence y vuelve el tema gratuito', () {
     final entitlement = Entitlement(
       skinId: 'neon',
       expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
     );
     expect(entitlement.isActive(DateTime.now()), isFalse);
   });
   ```

   La lógica vive en `lib/features/monetization/entitlements/`, nunca en el widget que muestra la cuenta atrás.

4. **Reglas de contexto**
   - Tests unitarios del motor: sin `TestWidgetsFlutterBinding`, sin widgets, sin plugins.
   - Tests de widget: `test/widget/` para teclado, display y tienda; comprobar que la skin cambia colores sin tocar el resultado.
   - Un test, una razón para fallar. Nombres en español descriptivos.
   - Sin `eval` en Dart: el parser es propio, con precedencia y asociatividad explícitas.
   - El test de regresión de un bug se queda para siempre.

## Commands

```bash
flutter test test/unit/calculator/parser_test.dart
flutter test test/unit/monetization/entitlement_test.dart
flutter test test/widget/
flutter test --coverage
flutter analyze
```

## Anti-Patterns

- Escribir el código y después el test "para confirmar".
- Tests que comprueban implementación (variables privadas) en lugar de comportamiento.
- Probar el motor con `flutter test` de widget innecesariamente.
- Usar `eval`, `dart:mirrors` o soluciones que dependan de la UI para calcular.
- Test de expiración con `DateTime.now()` sin controlar el reloj de forma determinista.
- Refactorizar en medio de la fase RED sin volver a ver el fallo esperado.

## Related Skills

- [flutter-standards](../../../.opencode/skills/flutter-standards/SKILL.md) — estructura de `test/unit`, `test/widget` y motor puro.
- [systematic-debugging](../../../.opencode/skills/systematic-debugging/SKILL.md) — test de regresión antes del fix.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — evidencia final de green.
- [subagent-driven-development](../../../.opencode/skills/subagent-driven-development/SKILL.md) — TDD dentro de cada slice.
