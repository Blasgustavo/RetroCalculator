// Validación compartida de fórmulas declarativas, en build-time y en el Studio.
//
// Solo tokeniza, parsea y recorre el AST: nunca ejecuta la fórmula (ADR-0004,
// ADR-0009). Las cotas son las del motor (ADR-0016), no las del esquema.

import 'package:retro_calculator/core/errors/calculator_exception.dart';
import 'package:retro_calculator/features/calculator/domain/engine/ast.dart';
import 'package:retro_calculator/features/calculator/domain/engine/engine_limits.dart';
import 'package:retro_calculator/features/calculator/domain/engine/lexer.dart';
import 'package:retro_calculator/features/calculator/domain/engine/parser.dart';

class FormulaIssue {
  const FormulaIssue(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
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
  if (expression.trim().isEmpty) {
    return const FormulaValidation(<FormulaIssue>[
      FormulaIssue('emptyFormula', 'fórmula vacía'),
    ], <String>{});
  }
  if (expression.length > maxFormulaLength) {
    return const FormulaValidation(<FormulaIssue>[
      FormulaIssue('formulaTooLong', 'fórmula demasiado larga'),
    ], <String>{});
  }

  final List<FormulaIssue> issues = <FormulaIssue>[];
  final Set<String> declared = <String>{};
  for (final String input in inputs) {
    final String normalized = input.toLowerCase();
    if (!declared.add(normalized)) {
      issues.add(
        FormulaIssue(
          'duplicateVariable',
          'variable declarada dos veces: $input (duplicateVariable)',
        ),
      );
    }
  }
  if (issues.isNotEmpty) {
    return FormulaValidation(
      List<FormulaIssue>.unmodifiable(issues),
      const <String>{},
    );
  }

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

class _FormulaWalker {
  _FormulaWalker({
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
  final List<FormulaIssue> issues = <FormulaIssue>[];
  final Set<String> dependencies = <String>{};
  int nodes = 0;
  bool _budgetReported = false;
  bool _depthReported = false;

  void walk(ExprNode node, int depth) {
    nodes++;
    if (nodes > EngineLimits.maxAstNodes) {
      if (!_budgetReported) {
        issues.add(
          const FormulaIssue(
            'stepBudgetExceeded',
            'fórmula excede el presupuesto de 200 nodos',
          ),
        );
        _budgetReported = true;
      }
      return;
    }
    if (depth > EngineLimits.maxAstDepth) {
      if (!_depthReported) {
        issues.add(
          const FormulaIssue('maxDepthExceeded', 'fórmula demasiado profunda'),
        );
        _depthReported = true;
      }
      return;
    }

    switch (node) {
      case NumberNode():
        return;
      // VariableNode extiende ConstantNode: este case debe ir primero para
      // que una variable inyectada no se trate como constante global.
      case VariableNode():
        if (!declared.contains(node.name)) {
          issues.add(
            FormulaIssue(
              'unknownVariable',
              'variable no declarada: ${node.name}',
            ),
          );
        }
      case ConstantNode():
        _checkConstant(node.name);
      case FunctionNode():
        if (!functions.contains(node.name.toLowerCase())) {
          issues.add(
            FormulaIssue(
              'unsupportedFunction',
              'función no permitida: ${node.name}',
            ),
          );
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
      issues.add(FormulaIssue('recursiveFormula', 'fórmula recursiva: $lower'));
      return;
    }
    // Otra fórmula del documento es una dependencia válida: validate.dart
    // comprueba el grafo completo con _detectFormulaCycles.
    if (formulaNames.contains(lower)) {
      dependencies.add(lower);
      return;
    }
    if (declared.contains(lower) || constants.contains(lower)) return;
    issues.add(
      FormulaIssue('unknownVariable', 'variable no declarada: $identifier'),
    );
  }
}
