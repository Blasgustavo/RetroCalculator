import 'dart:math' as math;

import '../../../../core/errors/calculator_exception.dart';
import '../engine/angle_mode.dart';
import 'capability.dart';

class ScientificCapability implements CalculatorCapability {
  const ScientificCapability();

  @override
  Set<String> get operators => const <String>{
    '+',
    '-',
    '*',
    '/',
    '^',
    '%',
    '!',
  };

  @override
  Set<String> get functions => const <String>{
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'ln',
    'log',
    'sqrt',
    'inv',
    'sqr',
  };

  @override
  Set<String> get constants => const <String>{'pi', 'e'};

  @override
  bool supportsOperator(String symbol) => operators.contains(symbol);

  @override
  bool supportsFunction(String name) => functions.contains(name.toLowerCase());

  @override
  bool supportsConstant(String name) => constants.contains(name.toLowerCase());

  @override
  double constant(String name) {
    return switch (name.toLowerCase()) {
      'pi' => math.pi,
      'e' => math.e,
      _ => throw const CalculatorException('unsupportedConstant'),
    };
  }

  @override
  double callFunction(String name, double value, AngleMode mode) {
    final double radians = _toRadians(value, mode);
    return switch (name.toLowerCase()) {
      'sin' => math.sin(radians),
      'cos' => math.cos(radians),
      'tan' => math.tan(radians),
      'asin' =>
        value < -1 || value > 1
            ? throw const CalculatorException('invalidDomain')
            : _fromRadians(math.asin(value), mode),
      'acos' =>
        value < -1 || value > 1
            ? throw const CalculatorException('invalidDomain')
            : _fromRadians(math.acos(value), mode),
      'atan' => _fromRadians(math.atan(value), mode),
      'ln' =>
        value <= 0
            ? throw const CalculatorException('invalidDomain')
            : math.log(value),
      'log' =>
        value <= 0
            ? throw const CalculatorException('invalidDomain')
            : math.log(value) / math.ln10,
      'sqrt' =>
        value < 0
            ? throw const CalculatorException('invalidDomain')
            : math.sqrt(value),
      'inv' =>
        value == 0
            ? throw const CalculatorException('divisionByZero')
            : 1 / value,
      'sqr' => value * value,
      _ => throw const CalculatorException('unsupportedFunction'),
    };
  }

  double _toRadians(double value, AngleMode mode) =>
      mode == AngleMode.radians ? value : value * math.pi / 180;

  double _fromRadians(double value, AngleMode mode) =>
      mode == AngleMode.radians ? value : value * 180 / math.pi;

  @override
  double factorial(double value) {
    if (value < 0 || value != value.roundToDouble() || value > 170) {
      throw const CalculatorException('invalidFactorial');
    }
    double result = 1;
    for (int i = 2; i <= value.toInt(); i++) {
      result *= i;
    }
    return result;
  }
}
