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
  }) {
    final List<Token> tokens = const Lexer().tokenize(expression);
    final ExprNode tree = Parser(tokens).parse();
    final double result = Evaluator(
      profile.capability,
      angleMode ?? profile.defaultAngleMode,
    ).evaluate(tree);
    if (!result.isFinite) {
      throw const CalculatorException('nonFiniteResult');
    }
    return result;
  }
}
