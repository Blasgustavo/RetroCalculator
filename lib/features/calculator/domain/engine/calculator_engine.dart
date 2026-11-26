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
        : <String, num>{
            for (final MapEntry<String, num> entry in variables.entries)
              entry.key.toLowerCase(): entry.value,
          };
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
}
