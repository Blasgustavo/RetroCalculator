# V5 T33 — Validación build-time de fórmulas declarativas

## Contexto

ADR-0009 define fórmulas declarativas con `inputs` y un mapa `formulas`, sin `eval`, validadas en build-time y de nuevo en runtime. V5 T29–T31 (PR #27) añadió `VariableNode`, `findVariableKey`, `duplicateVariable` y los límites de `EngineLimits` al motor. Quedó una deuda explícita: los validadores de `tool/design/` siguen parseando sin variables y usan `case ConstantNode():`, por lo que una futura inyección de `inputs` trataría variables como constantes. ADR-0016 fija la cota canónica (200 nodos / 64 niveles) y el rechazo de `inputs` duplicados al normalizar a minúsculas.

## Alcance

- Incluye: validación build-time en `validate.dart`, espejo en vivo en `studio_formula_validation.dart`, helper compartido en `tool/design/`, tests unitarios y actualización de los checkboxes T29–T33 del plan original.
- Excluye: T32 (autocompletado y botón «Probar»), T34 (validación runtime y catálogo), cambios en UI de la app, `pubspec.yaml`, goldens y nuevos ARB.

## Arquitectura

- `tool/design/formula_validation.dart` (nuevo): helper puro que parsea con `variables` y recorre el AST. Puede importar `package:retro_calculator/features/calculator/domain/engine/`; al revés está prohibido (ADR-0014).
- `tool/design/validate.dart`: convierte `FormulaIssue` en `ValidationIssue(path, message)` y conserva la detección de ciclos.
- `tool/design/studio/studio_formula_validation.dart`: convierte `FormulaIssue` en `List<String>` con los mismos mensajes de hoy.
- `schema.dart` deja de exportar `maxFormulaSteps`/`maxFormulaDepth`; `EngineLimits` es la única fuente.
- El motor en `lib/` no se modifica: ya expone `VariableNode`, `findVariableKey` y `EngineLimits`.

## Tareas (2-5 min cada una)

- [x] T33.0 — Registrar ADR-0016.
  Archivo: `docs/adr/0016-presupuesto-y-normalizacion-de-formulas.md`.
  Verificar: `git diff --check`.

- [x] T33.1 — Crear el helper compartido.
  Archivo: `tool/design/formula_validation.dart`.
  Código base:

  ```dart
  import 'package:retro_calculator/core/errors/calculator_exception.dart';
  import 'package:retro_calculator/features/calculator/domain/engine/ast.dart';
  import 'package:retro_calculator/features/calculator/domain/engine/engine_limits.dart';
  import 'package:retro_calculator/features/calculator/domain/engine/lexer.dart';
  import 'package:retro_calculator/features/calculator/domain/engine/parser.dart';

  class FormulaIssue {
    const FormulaIssue(this.code, this.message);
    final String code;
    final String message;
    @override String toString() => message;
  }

  class FormulaValidation {
    const FormulaValidation(this.issues, this.dependencies);
    final List<FormulaIssue> issues;
    final Set<String> dependencies;
    bool get isValid => issues.isEmpty;
  }

  const int maxFormulaLength = 256;

  FormulaValidation validateFormula({
    required String name,
    required String expression,
    required List<String> inputs,
    required Set<String> formulaNames,
    required Set<String> functions,
    required Set<String> constants,
  }) {
    final List<FormulaIssue> issues = <FormulaIssue>[];
    if (expression.trim().isEmpty) {
      return FormulaValidation(<FormulaIssue>[
        const FormulaIssue('emptyFormula', 'fórmula vacía'),
      ], const <String>{});
    }
    if (expression.length > maxFormulaLength) {
      return FormulaValidation(<FormulaIssue>[
        const FormulaIssue('formulaTooLong', 'fórmula demasiado larga'),
      ], const <String>{});
    }

    final Set<String> declared = <String>{};
    for (final String input in inputs) {
      final String normalized = input.toLowerCase();
      if (!declared.add(normalized)) {
        issues.add(FormulaIssue(
          'duplicateVariable',
          'variable declarada dos veces: $input (duplicateVariable)',
        ));
      }
    }
    if (issues.isNotEmpty) return FormulaValidation(issues, const <String>{});

    // El parser convierte los ids declarados en VariableNode; el resto sigue
    // siendo ConstantNode y se valida contra constants/formulaNames.
    final Map<String, num> variables = <String, num>{
      for (final String key in declared) key: 0,
    };
    final ExprNode parsed;
    try {
      parsed = Parser(
        const Lexer().tokenize(expression),
        variables: variables,
      ).parse();
    } on CalculatorException catch (error) {
      final String message = error.message == 'maxDepthExceeded'
          ? 'fórmula demasiado profunda'
          : 'fórmula con sintaxis inválida (${error.message})';
      return FormulaValidation(<FormulaIssue>[
        FormulaIssue(error.message, message),
      ], const <String>{});
    }

    final _FormulaWalker walker = _FormulaWalker(
      name: name,
      declared: declared,
      formulaNames: formulaNames,
      functions: functions,
      constants: constants,
    );
    walker.walk(parsed, 0);
    return FormulaValidation(
      List<FormulaIssue>.unmodifiable(walker.issues),
      Set<String>.unmodifiable(walker.dependencies),
    );
  }
  ```

  `_FormulaWalker` cuenta nodos con `EngineLimits.maxAstNodes`, profundidad con `EngineLimits.maxAstDepth`, y su switch debe empezar por `case VariableNode():` y después `case ConstantNode():`. Los mensajes se mantienen: `fórmula recursiva: <id>`, `variable no declarada: <id>`, `función no permitida: <id>`, `fórmula excede el presupuesto de 200 nodos`, `fórmula demasiado profunda`.

  Verificar: `dart analyze tool/design/formula_validation.dart`.

- [x] T33.2 — Conectar el validador build-time.
  Archivos: `tool/design/validate.dart`, `tool/design/schema.dart`.
  Cambios: importar `formula_validation.dart show validateFormula`; `_validateFormula` delega parseo y recorrido, convierte cada `FormulaIssue` en `ValidationIssue(path, issue.message)` y devuelve `result.dependencies`; eliminar `_FormulaBudget`, `_walkFormula` y los imports de `ast.dart`/`lexer.dart`/`parser.dart`/`calculator_exception.dart` que queden sin uso; borrar `maxFormulaSteps`/`maxFormulaDepth` de `schema.dart`.
  Verificar: `dart run tool/design/validate.dart` → `✓ válido`.

- [x] T33.3 — Conectar el espejo del Studio.
  Archivo: `tool/design/studio/studio_formula_validation.dart`.
  Cambios: `validateStudioFormula` delega en `validateFormula` y devuelve `result.issues.map((e) => e.message).toList(growable: false)`; borrar `_FormulaCheck`, el import de `schema.dart` y los imports de AST/lexer/parser sin uso. Conservar `maxFormulaLength` reexportado desde el helper si algún caller lo usa.
  Verificar: `flutter test --no-pub test/unit/design/studio_inspector_test.dart`.

- [x] T33.4 — Tests de regresión.
  Archivo: `test/unit/design/validate_formula_variables_test.dart` (nuevo).
  Casos: `base*(1+tasa/100)` con `inputs: ['base','tasa']` válido; `Base` y `BASE` juntos producen `duplicateVariable` y cero artefactos al compilar; identificador no declarado produce `variable no declarada: otro`; `pi` falla en `basic` y pasa en `scientific`; una concatenación de 51 `(1+1)` produce el aviso de 200 nodos; 70 `1+` produce `fórmula demasiado profunda`; ambos órdenes de duplicados dan el mismo issue.
  Verificar: `flutter test --no-pub test/unit/design/validate_formula_variables_test.dart`.

- [x] T33.5 — Verificación final.
  Comandos: `flutter analyze --no-pub`, `flutter test --no-pub test/unit test/widget`, `dart run tool/design/validate.dart`, `dart run tool/design/compile.dart && git diff --exit-code`, `dart format --output=none --set-exit-if-changed`, `git diff --check`. Tras cualquier `flutter pub get`, `git restore -- windows/flutter/`.

## Riesgos

- Cambiar mensajes rompe tests widget que buscan texto exacto: conservar las cadenas actuales.
- El helper no debe ejecutar la fórmula: solo parsear y recorrer el AST (ADR-0004).
- `VariableNode extends ConstantNode`: el orden del switch es la corrección; cualquier nuevo case debe poner `VariableNode` primero.
- Windows: no regenerar los 9 goldens canónicos de Linux; verificar solo `test/unit test/widget`.
