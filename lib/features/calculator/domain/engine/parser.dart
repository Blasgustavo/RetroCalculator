import '../../../../core/errors/calculator_exception.dart';
import 'ast.dart';
import 'token.dart';

class Parser {
  Parser(this._tokens);

  final List<Token> _tokens;
  int _index = 0;

  ExprNode parse() {
    if (_tokens.isEmpty) {
      throw const CalculatorException('emptyExpression');
    }
    final ExprNode node = _parseAdditive();
    if (_current != null) {
      throw const CalculatorException('invalidExpression');
    }
    return node;
  }

  Token? get _current => _index < _tokens.length ? _tokens[_index] : null;

  bool _matchOperator(String lexeme) {
    final Token? token = _current;
    if (token != null &&
        token.type == TokenType.operator &&
        token.lexeme == lexeme) {
      _index++;
      return true;
    }
    return false;
  }

  ExprNode _parseAdditive() {
    ExprNode node = _parseMultiplicative();
    while (true) {
      if (_matchOperator('+')) {
        node = BinaryNode('+', node, _parseMultiplicative());
      } else if (_matchOperator('-')) {
        node = BinaryNode('-', node, _parseMultiplicative());
      } else {
        return node;
      }
    }
  }

  ExprNode _parseMultiplicative() {
    ExprNode node = _parseUnary();
    while (true) {
      if (_matchOperator('*')) {
        node = BinaryNode('*', node, _parseUnary());
      } else if (_matchOperator('/')) {
        node = BinaryNode('/', node, _parseUnary());
      } else {
        return node;
      }
    }
  }

  ExprNode _parseUnary() {
    if (_matchOperator('+')) {
      return _parseUnary();
    }
    if (_matchOperator('-')) {
      return UnaryNode('-', _parseUnary());
    }
    return _parsePower();
  }

  ExprNode _parsePower() {
    final ExprNode base = _parsePostfix();
    if (_matchOperator('^')) {
      return BinaryNode('^', base, _parseUnary());
    }
    return base;
  }

  ExprNode _parsePostfix() {
    ExprNode node = _parsePrimary();
    while (true) {
      if (_matchOperator('!')) {
        node = FactorialNode(node);
      } else if (_matchOperator('%')) {
        node = PercentNode(node);
      } else {
        return node;
      }
    }
  }

  ExprNode _parsePrimary() {
    final Token? token = _current;
    if (token == null) {
      throw const CalculatorException('unexpectedEnd');
    }
    if (token.type == TokenType.number) {
      _index++;
      return NumberNode(double.parse(token.lexeme));
    }
    if (token.type == TokenType.leftParen) {
      _index++;
      final ExprNode node = _parseAdditive();
      final Token? closing = _current;
      if (closing == null || closing.type != TokenType.rightParen) {
        throw const CalculatorException('unbalancedParentheses');
      }
      _index++;
      return node;
    }
    if (token.type == TokenType.identifier) {
      _index++;
      final Token? next = _current;
      if (next != null && next.type == TokenType.leftParen) {
        _index++;
        final ExprNode argument = _parseAdditive();
        final Token? closing = _current;
        if (closing == null || closing.type != TokenType.rightParen) {
          throw const CalculatorException('unbalancedParentheses');
        }
        _index++;
        return FunctionNode(token.lexeme.toLowerCase(), argument);
      }
      return ConstantNode(token.lexeme.toLowerCase());
    }
    throw const CalculatorException('invalidExpression');
  }
}
