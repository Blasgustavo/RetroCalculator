// Validación en vivo de fórmulas del RetroDesign Studio (T25, plan V4).
//
// Espejo de la comprobación build-time de `validate.dart`, pero sin tocar ese
// archivo y sin ejecutar la fórmula: solo se tokeniza, se parsea y se recorre
// el AST con el presupuesto de `schema.dart`. T27 sigue siendo la barrera de
// compilación; aquí solo se muestra el error mientras se escribe.

import 'package:retro_calculator/core/errors/calculator_exception.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';
import 'package:retro_calculator/features/calculator/domain/engine/ast.dart';
import 'package:retro_calculator/features/calculator/domain/engine/lexer.dart';
import 'package:retro_calculator/features/calculator/domain/engine/parser.dart';

import '../schema.dart' show maxFormulaDepth, maxFormulaSteps;

/// Longitud máxima de una fórmula, igual que en el validador build-time.
const int maxFormulaLength = 256;

/// Errores legibles para una fórmula, sin evaluarla numéricamente.
List<String> validateStudioFormula({
  required String name,
  required String expression,
  required List<String> inputs,
  required String capabilityId,
  required Set<String> formulaNames,
}) {
  if (expression.trim().isEmpty) {
    return <String>['fórmula vacía'];
  }
  if (expression.length > maxFormulaLength) {
    return <String>['fórmula demasiado larga'];
  }

  final ExprNode parsed;
  try {
    parsed = Parser(const Lexer().tokenize(expression)).parse();
  } on CalculatorException catch (error) {
    return <String>['fórmula con sintaxis inválida (${error.message})'];
  }

  final CalculatorCapability capability = capabilityId == 'scientific'
      ? const ScientificCapability()
      : const BasicCapability();
  final _FormulaCheck check = _FormulaCheck(
    name: name,
    declared: inputs.toSet(),
    formulaNames: formulaNames,
    functions: capability.functions,
    constants: capability.constants,
  );
  check.walk(parsed, 0);
  return List<String>.unmodifiable(check.errors);
}

class _FormulaCheck {
  _FormulaCheck({
    required this.name,
    required this.declared,
    required this.formulaNames,
    required this.functions,
    required this.constants,
  });

  final String name;
  final Set<String> declared;
  final Set<String> formulaNames;
  final Set<String> functions;
  final Set<String> constants;
  final List<String> errors = <String>[];
  int steps = 0;
  bool _budgetReported = false;
  bool _depthReported = false;

  void walk(ExprNode node, int depth) {
    if (++steps > maxFormulaSteps) {
      if (!_budgetReported) {
        errors.add('fórmula excede el presupuesto de $maxFormulaSteps pasos');
        _budgetReported = true;
      }
      return;
    }
    if (depth > maxFormulaDepth) {
      if (!_depthReported) {
        errors.add('fórmula demasiado profunda');
        _depthReported = true;
      }
      return;
    }

    switch (node) {
      case NumberNode():
        return;
      case ConstantNode():
        _checkConstant(node.name);
      case FunctionNode():
        if (!functions.contains(node.name.toLowerCase())) {
          errors.add('función no permitida: ${node.name}');
        }
        walk(node.argument, depth + 1);
      case UnaryNode():
        walk(node.operand, depth + 1);
      case BinaryNode():
        walk(node.left, depth + 1);
        walk(node.right, depth + 1);
      case FactorialNode():
        walk(node.operand, depth + 1);
      case PercentNode():
        walk(node.operand, depth + 1);
    }
  }

  void _checkConstant(String identifier) {
    final String lower = identifier.toLowerCase();
    if (lower == name.toLowerCase()) {
      errors.add('fórmula recursiva: $lower');
      return;
    }
    // Otra fórmula del documento es una dependencia válida: T27 comprobará
    // el grafo completo y detectará ciclos entre fórmulas.
    if (formulaNames.contains(lower)) return;
    if (declared.contains(lower) || constants.contains(lower)) return;
    errors.add('variable no declarada: $identifier');
  }
}
