import 'dart:math' as math;

import '../../../../core/errors/calculator_exception.dart';
import '../capabilities/capability.dart';
import 'angle_mode.dart';
import 'ast.dart';
import 'engine_limits.dart';

/// Estado de una sola evaluación: cuenta visitas totales (no por rama) y
/// niveles de recursión activos. Se crea en [Evaluator.evaluate], por lo que
/// el evaluador sigue siendo inmutable y reutilizable.
class _EvaluationBudget {
  int _steps = 0;
  int _depth = 0;

  void enter() {
    _steps++;
    if (_steps > EngineLimits.maxAstNodes) {
      throw const CalculatorException('stepBudgetExceeded');
    }
    _depth++;
    if (_depth > EngineLimits.maxAstDepth) {
      throw const CalculatorException('maxDepthExceeded');
    }
  }

  void leave() => _depth--;
}

class Evaluator {
  const Evaluator(this._capability, this._angleMode, {this.variables});

  final CalculatorCapability _capability;
  final AngleMode _angleMode;

  /// `null` mantiene el modo calculadora clásico; un mapa (incluso vacío)
  /// activa el modo fórmula, donde todo id desconocido es `unknownVariable`.
  /// El motor entrega las claves ya normalizadas a minúsculas; la consulta
  /// también las normaliza para quien construya el evaluador directamente.
  final Map<String, num>? variables;

  double evaluate(ExprNode node) => _evaluate(node, _EvaluationBudget());

  double _evaluate(ExprNode node, _EvaluationBudget budget) {
    budget.enter();
    try {
      return switch (node) {
        NumberNode(:final double value) => value,
        PercentNode(:final ExprNode operand) =>
          _evaluate(operand, budget) / 100,
        VariableNode(:final String name) => _variable(name),
        ConstantNode(:final String name) => _constant(name),
        UnaryNode(:final String operator, :final ExprNode operand) =>
          operator == '-'
              ? -_evaluate(operand, budget)
              : _evaluate(operand, budget),
        BinaryNode(
          :final String operator,
          :final ExprNode left,
          :final ExprNode right,
        ) =>
          _binary(operator, left, right, budget),
        FunctionNode(:final String name, :final ExprNode argument) =>
          _capability.supportsFunction(name)
              ? _capability.callFunction(
                  name,
                  _evaluate(argument, budget),
                  _angleMode,
                )
              : throw const CalculatorException('unsupportedFunction'),
        FactorialNode(:final ExprNode operand) =>
          _capability.supportsOperator('!')
              ? _capability.factorial(_evaluate(operand, budget))
              : throw const CalculatorException('unsupportedFunction'),
      };
    } finally {
      budget.leave();
    }
  }

  double _constant(String name) {
    if (_capability.supportsConstant(name)) {
      return _capability.constant(name);
    }
    throw CalculatorException(
      variables == null ? 'unsupportedConstant' : 'unknownVariable',
    );
  }

  double _variable(String name) {
    final Map<String, num>? declared = variables;
    final String key = name.toLowerCase();
    if (declared != null && declared.containsKey(key)) {
      return declared[key]!.toDouble();
    }
    throw const CalculatorException('unknownVariable');
  }

  double _binary(
    String operator,
    ExprNode left,
    ExprNode right,
    _EvaluationBudget budget,
  ) {
    if (!_capability.supportsOperator(operator)) {
      throw const CalculatorException('unsupportedOperator');
    }
    if (right is PercentNode) {
      final double base = _evaluate(left, budget);
      final double rate = _evaluate(right.operand, budget) / 100;
      return switch (operator) {
        '+' => base + base * rate,
        '-' => base - base * rate,
        '*' => base * rate,
        '/' =>
          rate == 0
              ? throw const CalculatorException('divisionByZero')
              : base / rate,
        _ => throw const CalculatorException('unsupportedOperator'),
      };
    }
    final double a = _evaluate(left, budget);
    final double b = _evaluate(right, budget);
    return switch (operator) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0 ? throw const CalculatorException('divisionByZero') : a / b,
      '^' => _power(a, b),
      _ => throw const CalculatorException('unsupportedOperator'),
    };
  }

  double _power(double base, double exponent) {
    final double result = math.pow(base, exponent).toDouble();
    if (result.isNaN) {
      throw const CalculatorException('invalidDomain');
    }
    return result;
  }
}
