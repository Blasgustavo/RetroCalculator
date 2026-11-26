/// Límites explícitos para fórmulas declarativas (ADR-0009, regla 7).
///
/// El catálogo es dato, nunca código: estas cotas impiden que una expresión
/// arbitrariamente larga o anidada agote CPU o pila durante el análisis.
class EngineLimits {
  const EngineLimits._();

  /// Máximo de nodos que el evaluador puede visitar por expresión.
  static const int maxAstNodes = 200;

  /// Máximo de niveles de anidamiento, aplicado en parser y evaluador.
  static const int maxAstDepth = 64;
}
