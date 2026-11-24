import '../../../../core/errors/calculator_exception.dart';
import '../engine/angle_mode.dart';
import 'capability.dart';

class BasicCapability implements CalculatorCapability {
  const BasicCapability();

  @override
  Set<String> get operators => const <String>{'+', '-', '*', '/', '%'};

  @override
  Set<String> get functions => const <String>{};

  @override
  Set<String> get constants => const <String>{};

  @override
  bool supportsOperator(String symbol) => operators.contains(symbol);

  @override
  bool supportsFunction(String name) => functions.contains(name.toLowerCase());

  @override
  bool supportsConstant(String name) => constants.contains(name.toLowerCase());

  @override
  double constant(String name) =>
      throw const CalculatorException('unsupportedConstant');

  @override
  double callFunction(String name, double value, AngleMode mode) =>
      throw const CalculatorException('unsupportedFunction');

  @override
  double factorial(double value) =>
      throw const CalculatorException('unsupportedFunction');
}
