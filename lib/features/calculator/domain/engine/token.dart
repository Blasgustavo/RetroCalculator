enum TokenType { number, identifier, operator, leftParen, rightParen }

class Token {
  const Token(this.type, this.lexeme, this.position);

  final TokenType type;
  final String lexeme;
  final int position;

  @override
  String toString() => '$type($lexeme)';
}
