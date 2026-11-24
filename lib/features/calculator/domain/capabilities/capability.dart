import '../engine/angle_mode.dart';

abstract interface class CalculatorCapability {
  const CalculatorCapability();

  Set<String> get operators;
  Set<String> get functions;
  Set<String> get constants;

  double constant(String name);
  double callFunction(String name, double value, AngleMode mode);
  double factorial(double value);

  bool supportsOperator(String symbol) => operators.contains(symbol);
  bool supportsFunction(String name) => functions.contains(name.toLowerCase());
  bool supportsConstant(String name) => constants.contains(name.toLowerCase());
}
