/// Resolución compartida de nombres de variables declaradas.
///
/// `CalculatorEngine` normaliza las claves antes de inyectarlas, pero `Parser`
/// y `Evaluator` también se construyen directamente: usar la misma comparación
/// en ambos evita que el parser acepte un nombre que el evaluador rechace.
String? findVariableKey(Map<String, num> variables, String name) {
  final String normalized = name.toLowerCase();
  for (final String key in variables.keys) {
    if (key.toLowerCase() == normalized) {
      return key;
    }
  }
  return null;
}
