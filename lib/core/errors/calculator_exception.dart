class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  @override
  String toString() => 'CalculatorException: $message';
}
