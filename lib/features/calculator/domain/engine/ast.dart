sealed class ExprNode {
  const ExprNode();
}

class NumberNode extends ExprNode {
  const NumberNode(this.value);
  final double value;
}

class ConstantNode extends ExprNode {
  const ConstantNode(this.name);
  final String name;
}

/// Variable declarada en el mapa inyectado por la capa que invoca al motor.
///
/// Comparte `name` con [ConstantNode] para que los validadores existentes
/// sigan siendo exhaustivos sin tocar `tool/`; el evaluador distingue ambos
/// casos porque comprueba [VariableNode] antes que [ConstantNode].
class VariableNode extends ConstantNode {
  const VariableNode(super.name);
}

class UnaryNode extends ExprNode {
  const UnaryNode(this.operator, this.operand);
  final String operator;
  final ExprNode operand;
}

class BinaryNode extends ExprNode {
  const BinaryNode(this.operator, this.left, this.right);
  final String operator;
  final ExprNode left;
  final ExprNode right;
}

class FunctionNode extends ExprNode {
  const FunctionNode(this.name, this.argument);
  final String name;
  final ExprNode argument;
}

class FactorialNode extends ExprNode {
  const FactorialNode(this.operand);
  final ExprNode operand;
}

class PercentNode extends ExprNode {
  const PercentNode(this.operand);
  final ExprNode operand;
}
