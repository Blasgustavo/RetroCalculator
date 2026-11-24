import 'dart:math' as math;

import '../../../../core/errors/calculator_exception.dart';
import '../capabilities/capability.dart';
import 'angle_mode.dart';
import 'ast.dart';

class Evaluator {
  const Evaluator(this._capability, this._angleMode);

  final CalculatorCapability _capability;
  final AngleMode _angleMode;

  double evaluate(ExprNode node) {
    return switch (node) {
      NumberNode(:final double value) => value,
      PercentNode(:final ExprNode operand) => evaluate(operand) / 100,
      ConstantNode(:final String name) =>
        _capability.supportsConstant(name)
            ? _capability.constant(name)
            : throw const CalculatorException('unsupportedConstant'),
      UnaryNode(:final String operator, :final ExprNode operand) =>
        operator == '-' ? -evaluate(operand) : evaluate(operand),
      BinaryNode(
        :final String operator,
        :final ExprNode left,
        :final ExprNode right,
      ) =>
        _binary(operator, left, right),
      FunctionNode(:final String name, :final ExprNode argument) =>
        _capability.supportsFunction(name)
            ? _capability.callFunction(name, evaluate(argument), _angleMode)
            : throw const CalculatorException('unsupportedFunction'),
      FactorialNode(:final ExprNode operand) =>
        _capability.supportsOperator('!')
            ? _capability.factorial(evaluate(operand))
            : throw const CalculatorException('unsupportedFunction'),
    };
  }

  double _binary(String operator, ExprNode left, ExprNode right) {
    if (!_capability.supportsOperator(operator)) {
      throw const CalculatorException('unsupportedOperator');
    }
    if (right is PercentNode) {
      final double base = evaluate(left);
      final double rate = evaluate(right.operand) / 100;
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
    final double a = evaluate(left);
    final double b = evaluate(right);
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
