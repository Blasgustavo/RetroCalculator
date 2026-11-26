import '../../../../core/errors/calculator_exception.dart';
import '../profiles/calculator_profile.dart';
import 'angle_mode.dart';
import 'ast.dart';
import 'evaluator.dart';
import 'lexer.dart';
import 'parser.dart';
import 'token.dart';

class CalculatorEngine {
  const CalculatorEngine();

  double evaluate(
    String expression,
    CalculatorProfile profile, {
    AngleMode? angleMode,
    Map<String, num>? variables,
  }) {
    // Las claves del catálogo llegan en cualquier caso: se normalizan aquí,
    // antes de que el parser decida qué identificadores son variables.
    final Map<String, num>? declaredVariables = variables == null
        ? null
        : _normalizedVariables(variables);
    final List<Token> tokens = const Lexer().tokenize(expression);
    final ExprNode tree = Parser(tokens, variables: declaredVariables).parse();
    final double result = Evaluator(
      profile.capability,
      angleMode ?? profile.defaultAngleMode,
      variables: declaredVariables,
    ).evaluate(tree);
    if (!result.isFinite) {
      throw const CalculatorException('nonFiniteResult');
    }
    return result;
  }

  /// Normaliza a minúsculas sin dejar que el orden de entrada decida el valor:
  /// dos claves que solo difieran en caso son una declaración ambigua.
  static Map<String, num> _normalizedVariables(Map<String, num> variables) {
    final Map<String, num> normalized = <String, num>{};
    for (final MapEntry<String, num> entry in variables.entries) {
      final String key = entry.key.toLowerCase();
      if (normalized.containsKey(key)) {
        throw const CalculatorException('duplicateVariable');
      }
      normalized[key] = entry.value;
    }
    return normalized;
  }
}
