import '../../../../core/errors/calculator_exception.dart';
import 'token.dart';

class Lexer {
  const Lexer();

  List<Token> tokenize(String input) {
    final List<Token> tokens = <Token>[];
    int i = 0;
    while (i < input.length) {
      final String char = input[i];
      if (char == ' ' || char == '\t') {
        i++;
        continue;
      }
      if (_isDigit(char) || char == '.' || char == ',') {
        final int start = i;
        int separators = 0;
        int digits = 0;
        while (i < input.length &&
            (_isDigit(input[i]) || input[i] == '.' || input[i] == ',')) {
          if (input[i] == '.' || input[i] == ',') {
            separators++;
            if (separators > 1) {
              throw const CalculatorException('invalidNumber');
            }
          } else {
            digits++;
          }
          i++;
        }
        if (digits == 0) {
          throw const CalculatorException('invalidNumber');
        }
        String lexeme = input.substring(start, i).replaceAll(',', '.');
        if (lexeme.startsWith('.')) {
          lexeme = '0$lexeme';
        }
        if (lexeme.endsWith('.')) {
          lexeme = '${lexeme}0';
        }
        tokens.add(Token(TokenType.number, lexeme, start));
        continue;
      }
      if (_isLetter(char)) {
        final int start = i;
        while (i < input.length && _isLetter(input[i])) {
          i++;
        }
        tokens.add(
          Token(TokenType.identifier, input.substring(start, i), start),
        );
        continue;
      }
      if ('+-*/^!%'.contains(char)) {
        tokens.add(Token(TokenType.operator, char, i));
        i++;
        continue;
      }
      if (char == '(' || char == ')') {
        tokens.add(
          Token(
            char == '(' ? TokenType.leftParen : TokenType.rightParen,
            char,
            i,
          ),
        );
        i++;
        continue;
      }
      throw const CalculatorException('invalidCharacter');
    }
    return tokens;
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isLetter(String char) {
    final int code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}
