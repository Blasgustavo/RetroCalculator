# MVP Android: calculadora base — Plan de implementación

## Contexto

Este plan convierte el shell actual de RetroCalculator en el primer entregable funcional: la **calculadora base para Android**, con modos normal y científico gratuitos y siempre disponibles.

Fuentes de decisiones cerradas (no reabrir):

- [ADR-0004](../adr/0004-arquitectura-modular-y-generador.md), [ADR-0005](../adr/0005-internacionalizacion-y-formato-numerico.md) y [ADR-0006](../adr/0006-monetizacion-del-catalogo.md): ya registrados en `docs/adr/`, son fuente de las decisiones load-bearing de este MVP: (a) Android primero y base normal/científica sin anuncios ni entitlements; (b) motor en Dart puro con parser propio sin `eval`, precedencia, paréntesis, asociatividad, DEG/RAD y formato decimal configurable; (c) i18n desde el MVP con ARB `es_PE`/`en`/`pt_BR`, historial local global de 50 entradas y telemetría de contadores locales sin envío.
- **Documento de idea:** `C:/Users/qty94/.opencode/plan/retrocalculator-idea.md` (v0.5), especialmente §1 (regla de oro: nunca cobrar ni exigir publicidad para calcular), §4 (MVP = calculadora base), §5.5 (expirar nunca afecta al cálculo), §6 (funcionalidad normal/científica), §7 (Clean Architecture + MVVM y motor sin Flutter), §11 (métricas medibles con contadores locales) y §13 (fase 3: calculadora base).
- **ADR-0001** y **ADR-0003** refuerzan la regla de oro: la tienda, las skins y los entitlements existen como concepto, pero quedan fuera de este entregable.
- **ADR-0002** confirma Android como plataforma inicial.

Estado del repo que se evoluciona: existen `lib/main.dart`, `lib/app.dart`, `lib/config/routes.dart`, el design system en `lib/core/design_system/`, `lib/core/constants/app_strings.dart`, `lib/core/errors/calculator_exception.dart`, el shell `lib/features/calculator/presentation/calculator_page.dart` y `test/widget/app_test.dart`. Hay carpetas con `.gitkeep` en `domain/`, `data/` y `widgets/`; `test/unit/` también existe con `.gitkeep`. `lib/core/i18n/` y los ARB aún no existen. Provider ya está declarado en `pubspec.yaml` (`provider: ^6.1.5+1`).

## Alcance

### Incluye

- Motor en **Dart puro** en `lib/features/calculator/domain/engine/`: lexer, parser recursivo descendente, AST, evaluador, precedencia, paréntesis, asociatividad a la derecha de `^`, unario, **porcentaje simple y contextual**, división por cero y errores con código estable. **Cero imports de `package:flutter/*`**.
- Capacidades con contrato común en `lib/features/calculator/domain/capabilities/`: básicas y científicas (potencias, raíces, logaritmos, trigonometría directa e inversa, recíproco, cuadrado, factorial y constantes).
- Perfiles base como datos estáticos en `lib/features/calculator/domain/profiles/`: normal y científico (el generador llega en la fase siguiente).
- UI MVVM con Provider: display LCD ámbar sobre fondo oscuro con siete segmentos, teclado reutilizable en `lib/core/widgets/`, toggle normal/científico y toggle DEG/RAD.
- i18n desde el MVP: `lib/l10n/app_es_PE.arb`, `app_en.arb`, `app_pt_BR.arb` con las **mismas claves**; resolvedor de locale y regla numérica en `lib/core/i18n/`; decimal según locale; el parser acepta coma y punto; textos y nombres salen de ARB, nunca de cadenas sueltas.
- Historial global (compartido por ambos modos) de los últimos **50** cálculos, etiquetado por calculadora y persistido solo en el dispositivo, sin red.
- Telemetría de **contadores locales**, sin envío ni consentimiento de red.

### Excluye

- Tienda, entitlements, anuncios, IAP, suscripción, catálogo descargable, generador de skins y variantes cosméticas.
- Calculadoras funcionales (programador, financiero, estadístico, gráfico) y cualquier módulo de dominio nuevo distinto del motor base.
- Windows e iOS, plugins nativos, backend y CI de otras plataformas.
- Teclado físico, layout de tablet/escritorio y estilo retro definitivo más allá del LCD base acordado.

## Arquitectura

Dependencias: `presentation → domain`, `data → domain`, `core → solo Dart/Flutter permitido por capa`. El dominio **nunca** importa Flutter, `core/widgets`, `data` ni `presentation`. La UI no calcula: delega en `CalculatorViewModel` y consume `CalculatorEngine` solo a través de él.

```text
lib/
├── main.dart                                      # ya existe, sin cambios
├── app.dart                                       # T29: MultiProvider + l10n
├── config/routes.dart                             # ya existe, sin cambios
├── core/
│   ├── constants/app_strings.dart                 # T15: claves, no textos
│   ├── design_system/                             # ya existe
│   ├── errors/calculator_exception.dart           # ya existe: message = código de error
│   ├── i18n/                                      # T13-T15 (nuevo)
│   │   ├── number_formatting.dart
│   │   ├── locale_resolver.dart
│   │   └── error_label.dart
│   └── widgets/                                   # T22-T23 (carpeta ya existe)
│       ├── seven_segment_display.dart
│       └── calculator_keyboard.dart
├── l10n/                                          # T14 (nuevo)
│   ├── app_en.arb
│   ├── app_es_PE.arb
│   └── app_pt_BR.arb
└── features/calculator/
    ├── domain/
    │   ├── engine/                                # T02-T05, T11
    │   │   ├── angle_mode.dart
    │   │   ├── token.dart
    │   │   ├── lexer.dart
    │   │   ├── ast.dart
    │   │   ├── parser.dart
    │   │   ├── evaluator.dart
    │   │   └── calculator_engine.dart
    │   ├── capabilities/                          # T06-T08
    │   │   ├── capability.dart
    │   │   ├── basic_capability.dart
    │   │   └── scientific_capability.dart
    │   └── profiles/                              # T09-T10
    │       ├── calculator_profile.dart
    │       └── profiles.dart
    ├── data/
    │   ├── models/history_entry.dart              # T17
    │   └── local/
    │       ├── history_store.dart                 # T18
    │       ├── in_memory_history_store.dart       # T18
    │       ├── shared_preferences_history_store.dart # T19
    │       └── local_counters.dart                # T21
    └── presentation/
        ├── calculator_page.dart                   # T28: evoluciona el shell
        ├── viewmodels/calculator_view_model.dart  # T25
        └── widgets/history_panel.dart             # T26
test/
├── unit/calculator/                               # T01, T16, T20, T24, T30
├── unit/i18n/number_formatting_test.dart          # T12
├── unit/i18n/arb_keys_test.dart                   # T14
└── widget/
    ├── app_test.dart                              # T29: evoluciona
    └── calculator_page_test.dart                  # T27
l10n.yaml                                          # T14 (nuevo)
```

## Tareas (2-5 min cada una)

Convención para cada tarea: **Archivo principal**, **Criterio de aceptación** y **Verificar**. Se ejecutan en orden, con TDD (test rojo → código mínimo → verde), desde la raíz del repo. La ejecución real se hará en el worktree `.worktrees/feature-calculator-engine` con `subagent-driven-development` y review de spec/calidad por slice.

### Slice 1 — Motor puro (T01–T11)

#### T01 — Test rojo del contrato del motor

- **Archivo principal:** `test/unit/calculator/parser_test.dart` (nuevo).
- **Criterio de aceptación:** el archivo existe y falla en rojo porque `lexer.dart`, `parser.dart`, `evaluator.dart`, capacidades y perfiles aún no existen; contiene 15 casos concretos de precedencia, paréntesis, asociatividad, DEG/RAD, porcentaje contextual, funciones inversas, recíproco, cuadrado, errores y rechazo de capacidades no soportadas en modo normal.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/errors/calculator_exception.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';
import 'package:retro_calculator/features/calculator/domain/engine/angle_mode.dart';
import 'package:retro_calculator/features/calculator/domain/engine/calculator_engine.dart';
import 'package:retro_calculator/features/calculator/domain/engine/lexer.dart';
import 'package:retro_calculator/features/calculator/domain/profiles/calculator_profile.dart';

void main() {
  const CalculatorEngine engine = CalculatorEngine();
  const CalculatorProfile normal = CalculatorProfile(
    id: CalculatorProfileId.normal,
    labelKey: 'modeNormal',
    capability: BasicCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 8,
    keyRows: <List<String>>[],
  );
  const CalculatorProfile scientific = CalculatorProfile(
    id: CalculatorProfileId.scientific,
    labelKey: 'modeScientific',
    capability: ScientificCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 10,
    keyRows: <List<String>>[],
  );

  group('Lexer', () {
    test('acepta coma y punto como separador decimal', () {
      expect(const Lexer().tokenize('1,5').single.lexeme, '1.5');
      expect(const Lexer().tokenize('1.5').single.lexeme, '1.5');
    });
  });

  group('Parser y evaluador', () {
    test('respeta precedencia: 2 + 3 * 4 == 14', () {
      expect(engine.evaluate('2 + 3 * 4', normal), 14);
    });

    test('respeta paréntesis: (2 + 3) * 4 == 20', () {
      expect(engine.evaluate('(2 + 3) * 4', normal), 20);
    });

    test('potencia asociativa a la derecha: 2 ^ 3 ^ 2 == 512', () {
      expect(engine.evaluate('2 ^ 3 ^ 2', scientific), 512);
    });

    test('unario antes que potencia: -2 ^ 2 == -4', () {
      expect(engine.evaluate('-2 ^ 2', scientific), -4);
    });

    test('porcentaje postfijo: 50% == 0.5', () {
      expect(engine.evaluate('50%', normal), 0.5);
    });

    test('porcentaje contextual a la derecha de +, -, * y /', () {
      expect(engine.evaluate('50 + 10%', normal), 55);
      expect(engine.evaluate('50 - 10%', normal), 45);
      expect(engine.evaluate('100 * 10%', normal), 10);
      expect(engine.evaluate('100 / 10%', normal), 1000);
    });

    test('división por cero usa código estable', () {
      expect(
        () => engine.evaluate('1 / 0', normal),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException e) => e.message,
            'código',
            'divisionByZero',
          ),
        ),
      );
    });

    test('DEG: sin(30) == 0.5', () {
      expect(engine.evaluate('sin(30)', scientific), closeTo(0.5, 1e-12));
    });

    test('RAD: sin(pi / 2) == 1', () {
      expect(
        engine.evaluate('sin(pi / 2)', scientific,
            angleMode: AngleMode.radians),
        closeTo(1, 1e-12),
      );
    });

    test('logaritmo decimal: log(100) == 2', () {
      expect(engine.evaluate('log(100)', scientific), closeTo(2, 1e-12));
    });

    test('inversas, recíproco y cuadrado', () {
      expect(engine.evaluate('asin(1)', scientific), closeTo(90, 1e-12));
      expect(
        engine.evaluate('asin(1)', scientific,
            angleMode: AngleMode.radians),
        closeTo(1.5707963267948966, 1e-12),
      );
      expect(engine.evaluate('inv(4)', scientific), 0.25);
      expect(engine.evaluate('sqr(3)', scientific), 9);
      expect(
        () => engine.evaluate('asin(2)', scientific),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('factorial: 5! == 120', () {
      expect(engine.evaluate('5!', scientific), 120);
    });

    test('el modo normal rechaza funciones y operadores científicos', () {
      expect(
        () => engine.evaluate('sin(30)', normal),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException e) => e.message,
            'código',
            'unsupportedFunction',
          ),
        ),
      );
      expect(
        () => engine.evaluate('2 ^ 3', normal),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException e) => e.message,
            'código',
            'unsupportedOperator',
          ),
        ),
      );
      expect(
        () => engine.evaluate('5!', normal),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException e) => e.message,
            'código',
            'unsupportedFunction',
          ),
        ),
      );
    });

    test('detecta paréntesis sin cerrar', () {
      expect(
        () => engine.evaluate('(2 + 3', normal),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException e) => e.message,
            'código',
            'unbalancedParentheses',
          ),
        ),
      );
    });
  });
}
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (rojo esperado; no mover código de producción hasta T02).

#### T02 — Token, modo angular y lexer

- **Archivos principales:** `lib/features/calculator/domain/engine/lexer.dart` (con `token.dart` y `angle_mode.dart` como soporte).
- **Criterio de aceptación:** `1,5` y `1.5` producen el mismo lexema `1.5`; un separador duplicado lanza `invalidNumber`; un carácter desconocido lanza `invalidCharacter`; ningún archivo importa Flutter.
- **Código literal (soporte `token.dart`):**

```dart
enum TokenType { number, identifier, operator, leftParen, rightParen }

class Token {
  const Token(this.type, this.lexeme, this.position);

  final TokenType type;
  final String lexeme;
  final int position;

  @override
  String toString() => '$type($lexeme)';
}
```

- **Código literal (soporte `angle_mode.dart`):**

```dart
enum AngleMode { degrees, radians }
```

- **Código literal (`lexer.dart`):**

```dart
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
        while (i < input.length &&
            (_isDigit(input[i]) || input[i] == '.' || input[i] == ',')) {
          if (input[i] == '.' || input[i] == ',') {
            separators++;
            if (separators > 1) {
              throw const CalculatorException('invalidNumber');
            }
          }
          i++;
        }
        final String lexeme =
            input.substring(start, i).replaceAll(',', '.');
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

  bool _isDigit(String char) => char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isLetter(String char) {
    final int code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (sigue rojo por módulos pendientes; el caso del Lexer ya puede pasar cuando el import resuelva).

#### T03 — AST mínimo

- **Archivo principal:** `lib/features/calculator/domain/engine/ast.dart` (nuevo).
- **Criterio de aceptación:** existen nodos sealed para número, constante, unario, binario, función, factorial y porcentaje; `flutter analyze` no reporta errores en el archivo.
- **Código literal:**

```dart
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
```

- **Verificar:** `flutter analyze lib/features/calculator/domain/engine/ast.dart`.

#### T04 — Parser recursivo descendente

- **Archivo principal:** `lib/features/calculator/domain/engine/parser.dart` (nuevo).
- **Criterio de aceptación:** precedencia `+/-` < `*/` < unario < `^` (derecha) < postfijo `!`/`%` < primario; paréntesis balanceados; sobrante de tokens lanza `invalidExpression`.
- **Código literal:**

```dart
import '../../../../core/errors/calculator_exception.dart';
import 'ast.dart';
import 'token.dart';

class Parser {
  const Parser(this._tokens);

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

  Token? get _current =>
      _index < _tokens.length ? _tokens[_index] : null;

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
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (sigue rojo hasta T11).

#### T05 — Evaluador y división por cero

- **Archivo principal:** `lib/features/calculator/domain/engine/evaluator.dart` (nuevo).
- **Criterio de aceptación:** evalúa los 7 nodos del AST; un `PercentNode` a la derecha de `+ - * /` es relativo al operando izquierdo (`50 + 10% == 55`); `1/0` lanza `divisionByZero`; `math.pow` con dominio inválido lanza `invalidDomain`; DEG/RAD se resuelve en la capacidad, nunca aquí; operadores, funciones y constantes se validan contra `CalculatorCapability` antes de ejecutarse.
- **Código literal:**

```dart
import 'dart:math' as math;

import '../../../../core/errors/calculator_exception.dart';
import '../capabilities/capability.dart';
import 'angle_mode.dart';
import 'ast.dart';

class Evaluator {
  const Evaluator(this._capability, this._angleMode);

  final CalculatorCapability _capability;
  final AngleMode _angleMode;

  double evaluate(ExprNode node) {
    return switch (node) {
      NumberNode(:final double value) => value,
      PercentNode(:final ExprNode operand) => evaluate(operand) / 100,
      ConstantNode(:final String name) => _capability.supportsConstant(name)
          ? _capability.constant(name)
          : throw const CalculatorException('unsupportedConstant'),
      UnaryNode(:final String operator, :final ExprNode operand) =>
          operator == '-' ? -evaluate(operand) : evaluate(operand),
      BinaryNode(
        :final String operator,
        :final ExprNode left,
        :final ExprNode right,
      ) =>
        _binary(operator, left, right),
      FunctionNode(:final String name, :final ExprNode argument) =>
          _capability.supportsFunction(name)
              ? _capability.callFunction(name, evaluate(argument), _angleMode)
              : throw const CalculatorException('unsupportedFunction'),
      FactorialNode(:final ExprNode operand) =>
          _capability.supportsOperator('!')
              ? _capability.factorial(evaluate(operand))
              : throw const CalculatorException('unsupportedFunction'),
    };
  }

  double _binary(String operator, ExprNode left, ExprNode right) {
    if (!_capability.supportsOperator(operator)) {
      throw const CalculatorException('unsupportedOperator');
    }
    if (right is PercentNode) {
      final double base = evaluate(left);
      final double rate = evaluate(right.operand) / 100;
      return switch (operator) {
        '+' => base + base * rate,
        '-' => base - base * rate,
        '*' => base * rate,
        '/' => rate == 0
            ? throw const CalculatorException('divisionByZero')
            : base / rate,
        _ => throw const CalculatorException('unsupportedOperator'),
      };
    }
    final double a = evaluate(left);
    final double b = evaluate(right);
    return switch (operator) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0
          ? throw const CalculatorException('divisionByZero')
          : a / b,
      '^' => _power(a, b),
      _ => throw const CalculatorException('unsupportedOperator'),
    };
  }

  double _power(double base, double exponent) {
    final double result = math.pow(base, exponent).toDouble();
    if (result.isNaN) {
      throw const CalculatorException('invalidDomain');
    }
    return result;
  }
}
```

- **Verificar:** `flutter analyze lib/features/calculator/domain/engine/evaluator.dart`.

#### T06 — Contrato común de capacidades

- **Archivo principal:** `lib/features/calculator/domain/capabilities/capability.dart` (nuevo).
- **Criterio de aceptación:** una sola interfaz para básica y científica, con conjuntos de operadores/funciones/constantes y resolución de constantes, llamadas y factorial; sin Flutter.
- **Código literal:**

```dart
import '../engine/angle_mode.dart';

abstract interface class CalculatorCapability {
  const CalculatorCapability();

  Set<String> get operators;
  Set<String> get functions;
  Set<String> get constants;

  double constant(String name);
  double callFunction(String name, double value, AngleMode mode);
  double factorial(double value);

  bool supportsOperator(String symbol) => operators.contains(symbol);
  bool supportsFunction(String name) => functions.contains(name.toLowerCase());
  bool supportsConstant(String name) => constants.contains(name.toLowerCase());
}
```

- **Verificar:** `flutter analyze lib/features/calculator/domain/capabilities/capability.dart`.

#### T07 — Capacidad básica

- **Archivo principal:** `lib/features/calculator/domain/capabilities/basic_capability.dart` (nuevo).
- **Criterio de aceptación:** solo `+ - * /` y `%` postfijo; cualquier función, constante o factorial lanza código `unsupported*`; sin Flutter.
- **Código literal:**

```dart
import '../../../../core/errors/calculator_exception.dart';
import '../engine/angle_mode.dart';
import 'capability.dart';

class BasicCapability implements CalculatorCapability {
  const BasicCapability();

  @override
  Set<String> get operators => const <String>{'+', '-', '*', '/', '%'};

  @override
  Set<String> get functions => const <String>{};

  @override
  Set<String> get constants => const <String>{};

  @override
  double constant(String name) =>
      throw const CalculatorException('unsupportedConstant');

  @override
  double callFunction(String name, double value, AngleMode mode) =>
      throw const CalculatorException('unsupportedFunction');

  @override
  double factorial(double value) =>
      throw const CalculatorException('unsupportedFunction');
}
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (el caso «modo normal rechaza sin» debe pasar cuando T08 y T11 estén listos).

#### T08 — Capacidad científica

- **Archivo principal:** `lib/features/calculator/domain/capabilities/scientific_capability.dart` (nuevo).
- **Criterio de aceptación:** `sin/cos/tan` convierten DEG→RAD y `asin/acos/atan` convierten RAD→DEG; `ln/log/sqrt` validan dominio; `inv` rechaza cero y `sqr` eleva al cuadrado; `fact` solo acepta enteros 0..170; constantes `pi` y `e`; sin Flutter.
- **Código literal:**

```dart
import 'dart:math' as math;

import '../../../../core/errors/calculator_exception.dart';
import '../engine/angle_mode.dart';
import 'capability.dart';

class ScientificCapability implements CalculatorCapability {
  const ScientificCapability();

  @override
  Set<String> get operators =>
      const <String>{'+', '-', '*', '/', '^', '%', '!'};

  @override
  Set<String> get functions => const <String>{
        'sin',
        'cos',
        'tan',
        'asin',
        'acos',
        'atan',
        'ln',
        'log',
        'sqrt',
        'inv',
        'sqr',
      };

  @override
  Set<String> get constants => const <String>{'pi', 'e'};

  @override
  double constant(String name) {
    return switch (name.toLowerCase()) {
      'pi' => math.pi,
      'e' => math.e,
      _ => throw const CalculatorException('unknownConstant'),
    };
  }

  @override
  double callFunction(String name, double value, AngleMode mode) {
    final double radians = _toRadians(value, mode);
    return switch (name.toLowerCase()) {
      'sin' => math.sin(radians),
      'cos' => math.cos(radians),
      'tan' => math.tan(radians),
      'asin' => value < -1 || value > 1
          ? throw const CalculatorException('invalidDomain')
          : _fromRadians(math.asin(value), mode),
      'acos' => value < -1 || value > 1
          ? throw const CalculatorException('invalidDomain')
          : _fromRadians(math.acos(value), mode),
      'atan' => _fromRadians(math.atan(value), mode),
      'ln' => value <= 0
          ? throw const CalculatorException('invalidDomain')
          : math.log(value),
      'log' => value <= 0
          ? throw const CalculatorException('invalidDomain')
          : math.log(value) / math.ln10,
      'sqrt' => value < 0
          ? throw const CalculatorException('invalidDomain')
          : math.sqrt(value),
      'inv' => value == 0
          ? throw const CalculatorException('divisionByZero')
          : 1 / value,
      'sqr' => value * value,
      _ => throw const CalculatorException('unsupportedFunction'),
    };
  }

  double _toRadians(double value, AngleMode mode) =>
      mode == AngleMode.radians ? value : value * math.pi / 180;

  double _fromRadians(double value, AngleMode mode) =>
      mode == AngleMode.radians ? value : value * 180 / math.pi;

  @override
  double factorial(double value) {
    if (value < 0 ||
        value != value.roundToDouble() ||
        value > 170) {
      throw const CalculatorException('invalidFactorial');
    }
    double result = 1;
    for (int i = 2; i <= value.toInt(); i++) {
      result *= i;
    }
    return result;
  }
}
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (casos DEG, RAD, `log`, factorial).

#### T09 — Perfil base como datos

- **Archivo principal:** `lib/features/calculator/domain/profiles/calculator_profile.dart` (nuevo).
- **Criterio de aceptación:** perfil es dato inmutable con id, clave ARB de etiqueta, capacidad, modo angular por defecto, decimales y filas de teclas; `labelKey` nunca contiene texto visible.
- **Código literal:**

```dart
import '../capabilities/capability.dart';
import '../engine/angle_mode.dart';

enum CalculatorProfileId { normal, scientific }

class CalculatorProfile {
  const CalculatorProfile({
    required this.id,
    required this.labelKey,
    required this.capability,
    required this.defaultAngleMode,
    required this.decimalDigits,
    required this.keyRows,
  });

  final CalculatorProfileId id;
  final String labelKey;
  final CalculatorCapability capability;
  final AngleMode defaultAngleMode;
  final int decimalDigits;
  final List<List<String>> keyRows;

  bool get isScientific => id == CalculatorProfileId.scientific;
}
```

- **Verificar:** `flutter analyze lib/features/calculator/domain/profiles/calculator_profile.dart`.

#### T10 — Catálogo estático de perfiles

- **Archivo principal:** `lib/features/calculator/domain/profiles/profiles.dart` (nuevo).
- **Criterio de aceptación:** `CalculatorProfiles.normal` y `CalculatorProfiles.scientific` son `const`; el científico expone teclas `sin(`, `cos(`, `tan(`, `asin(`, `acos(`, `atan(`, `1/x`, `x²`, `log(`, `ln(`, `sqrt(`, `^`, `pi`, `e`, `!`, `(`, `)`.
- **Código literal:**

```dart
import '../capabilities/basic_capability.dart';
import '../capabilities/scientific_capability.dart';
import '../engine/angle_mode.dart';
import 'calculator_profile.dart';

class CalculatorProfiles {
  const CalculatorProfiles._();

  static const CalculatorProfile normal = CalculatorProfile(
    id: CalculatorProfileId.normal,
    labelKey: 'modeNormal',
    capability: BasicCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 8,
    keyRows: <List<String>>[
      <String>['C', '⌫', '%', '/'],
      <String>['7', '8', '9', '*'],
      <String>['4', '5', '6', '-'],
      <String>['1', '2', '3', '+'],
      <String>['±', '0', '.', '='],
    ],
  );

  static const CalculatorProfile scientific = CalculatorProfile(
    id: CalculatorProfileId.scientific,
    labelKey: 'modeScientific',
    capability: ScientificCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 10,
    keyRows: <List<String>>[
      <String>['sin(', 'cos(', 'tan(', '(', ')'],
      <String>['asin(', 'acos(', 'atan(', '1/x', 'x²'],
      <String>['ln(', 'log(', 'sqrt(', '^', '!'],
      <String>['pi', 'e', '%', 'C', '⌫'],
      <String>['7', '8', '9', '/', '*'],
      <String>['4', '5', '6', '-', '+'],
      <String>['1', '2', '3', '±', '='],
      <String>['0', '.', 'MC', 'MR', 'M+'],
    ],
  );
}
```

- **Verificar:** `flutter analyze lib/features/calculator/domain/profiles/profiles.dart`.

#### T11 — Fachada del motor y verde del slice

- **Archivo principal:** `lib/features/calculator/domain/engine/calculator_engine.dart` (nuevo).
- **Criterio de aceptación:** `CalculatorEngine.evaluate` compone lexer → parser → evaluador, usa el modo del perfil si no se pasa explicitamente y rechaza resultados no finitos; los 12 tests del slice 1 pasan.
- **Código literal:**

```dart
import '../../../../core/errors/calculator_exception.dart';
import '../profiles/calculator_profile.dart';
import 'angle_mode.dart';
import 'evaluator.dart';
import 'lexer.dart';
import 'parser.dart';

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
```

- **Verificar:** `flutter test test/unit/calculator/parser_test.dart` (verde) y `flutter analyze lib/features/calculator/domain`.

### Slice 2 — i18n y formato numérico (T12–T15)

#### T12 — Test rojo del formato numérico

- **Archivo principal:** `test/unit/i18n/number_formatting_test.dart` (nuevo).
- **Criterio de aceptación:** falla en rojo por `lib/core/i18n/number_formatting.dart` inexistente; fija decimal `.` para `en`, `,` para `es_PE` y `pt_BR`, agrupación inversa y recorte de ceros.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/i18n/number_formatting.dart';

void main() {
  test('en usa punto decimal y coma de millar', () {
    expect(
      formatNumber(1234567.5, separator: DecimalSeparator.dot),
      '1,234,567.5',
    );
  });

  test('es_PE y pt_BR usan coma decimal y punto de millar', () {
    expect(separatorForLocale('es_PE'), DecimalSeparator.comma);
    expect(separatorForLocale('pt-BR'), DecimalSeparator.comma);
    expect(
      formatNumber(1234567.5, separator: DecimalSeparator.comma),
      '1.234.567,5',
    );
  });

  test('recorta ceros y respeta decimalDigits', () {
    expect(
      formatNumber(2, separator: DecimalSeparator.dot, maxFractionDigits: 8),
      '2',
    );
    expect(
      formatNumber(1 / 3,
          separator: DecimalSeparator.comma, maxFractionDigits: 3),
      '0,333',
    );
  });
}
```

- **Verificar:** `flutter test test/unit/i18n/number_formatting_test.dart` (rojo esperado).

#### T13 — Regla numérica por locale

- **Archivo principal:** `lib/core/i18n/number_formatting.dart` (nuevo).
- **Criterio de aceptación:** Dart puro (solo `dart:core`), sin imports de Flutter; los 3 tests del slice pasan; el parser ya acepta coma y punto, así que la salida con coma es reentrante.
- **Código literal:**

```dart
enum DecimalSeparator { dot, comma }

DecimalSeparator separatorForLocale(String localeName) {
  final String locale = localeName.toLowerCase().replaceAll('-', '_');
  if (locale.startsWith('en')) {
    return DecimalSeparator.dot;
  }
  if (locale.startsWith('es') || locale.startsWith('pt')) {
    return DecimalSeparator.comma;
  }
  return DecimalSeparator.dot;
}

String formatNumber(
  num value, {
  required DecimalSeparator separator,
  int maxFractionDigits = 10,
}) {
  if (value.isNaN) {
    return 'NaN';
  }
  if (value.isInfinite) {
    return value.isNegative ? '-∞' : '∞';
  }
  final int digits = maxFractionDigits.clamp(0, 12);
  final String fixed = value.toStringAsFixed(digits);
  final String trimmed = fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  final bool negative = trimmed.startsWith('-');
  final String unsigned = negative ? trimmed.substring(1) : trimmed;
  final List<String> parts = unsigned.split('.');
  final String grouping = separator == DecimalSeparator.dot ? ',' : '.';
  final String integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match _) => grouping,
  );
  final String fraction = parts.length > 1
      ? '${separator == DecimalSeparator.dot ? '.' : ','}${parts[1]}'
      : '';
  final String sign = negative ? '-' : '';
  return '$sign$integer$fraction';
}
```

- **Verificar:** `flutter test test/unit/i18n/number_formatting_test.dart` (verde).

#### T14 — ARB con claves idénticas y generación

- **Archivos principales:** `lib/l10n/app_en.arb`, `lib/l10n/app_es_PE.arb`, `lib/l10n/app_pt_BR.arb`, `lib/l10n/app_es.arb` y `lib/l10n/app_pt.arb` (nuevos; los dos últimos son fallback técnico), `l10n.yaml` (nuevo) y el Dart generado en `lib/l10n/app_localizations*.dart` (nuevo, commiteado); `pubspec.yaml` se evoluciona con `flutter: generate: true`.
- **Criterio de aceptación:** los cinco ARB tienen exactamente las mismas 40 claves; `app_es.arb` replica las claves de `app_es_PE.arb` y `app_pt.arb` las de `app_pt_BR.arb`, pero `LocaleResolver` sigue ofreciendo solo `es_PE`, `en` y `pt_BR` en el lote 1. `flutter gen-l10n` y `flutter pub get` terminan sin errores con Flutter 3.44 y generan `AppLocalizations` en `lib/l10n/`; se importa como `package:retro_calculator/l10n/app_localizations.dart`.
- **Código literal (`l10n.yaml`):**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
preferred-supported-locales: [es_PE, en, pt_BR]
```

- **Código literal (`pubspec.yaml`, sección `flutter`):**

```yaml
flutter:
  generate: true
  uses-material-design: true
```

- **Código literal (`lib/l10n/app_en.arb`):**

```json
{
  "appName": "RetroCalculator",
  "calculatorTitle": "Calculator",
  "readyMessage": "Ready to calculate",
  "modeNormal": "Normal",
  "modeScientific": "Scientific",
  "angleDeg": "DEG",
  "angleRad": "RAD",
  "historyTitle": "History",
  "historyEmpty": "No calculations yet",
  "clearLabel": "Clear",
  "backspaceLabel": "Backspace",
  "equalsLabel": "Equals",
  "signLabel": "Change sign",
  "modeToggleLabel": "Switch mode",
  "resultLabel": "Result",
  "keySin": "sin",
  "keyCos": "cos",
  "keyTan": "tan",
  "keyLog": "log",
  "keyLn": "ln",
  "keySqrt": "√",
  "keyPower": "x^y",
  "keyFactorial": "n!",
  "keyPi": "π",
  "keyE": "e",
  "keyLeftParen": "(",
  "keyRightParen": ")",
  "keyAsin": "asin",
  "keyAcos": "acos",
  "keyAtan": "atan",
  "keyReciprocal": "1/x",
  "keySquare": "x²",
  "errorDivisionByZero": "Division by zero",
  "errorInvalidExpression": "Invalid expression",
  "errorInvalidDomain": "Invalid domain",
  "errorUnsupportedFunction": "Function not available",
  "errorInvalidNumber": "Invalid number",
  "errorUnbalancedParentheses": "Unbalanced parentheses",
  "errorEmptyExpression": "Empty expression",
  "errorNonFiniteResult": "Non-finite result"
}
```

- **Código literal (`lib/l10n/app_es_PE.arb`):**

```json
{
  "appName": "RetroCalculator",
  "calculatorTitle": "Calculadora",
  "readyMessage": "Listo para calcular",
  "modeNormal": "Normal",
  "modeScientific": "Científica",
  "angleDeg": "GRAD",
  "angleRad": "RAD",
  "historyTitle": "Historial",
  "historyEmpty": "Sin cálculos aún",
  "clearLabel": "Borrar",
  "backspaceLabel": "Retroceso",
  "equalsLabel": "Igual",
  "signLabel": "Cambiar signo",
  "modeToggleLabel": "Cambiar modo",
  "resultLabel": "Resultado",
  "keySin": "sen",
  "keyCos": "cos",
  "keyTan": "tan",
  "keyLog": "log",
  "keyLn": "ln",
  "keySqrt": "√",
  "keyPower": "x^y",
  "keyFactorial": "n!",
  "keyPi": "π",
  "keyE": "e",
  "keyLeftParen": "(",
  "keyRightParen": ")",
  "keyAsin": "sen⁻¹",
  "keyAcos": "cos⁻¹",
  "keyAtan": "tan⁻¹",
  "keyReciprocal": "1/x",
  "keySquare": "x²",
  "errorDivisionByZero": "División por cero",
  "errorInvalidExpression": "Expresión no válida",
  "errorInvalidDomain": "Dominio no válido",
  "errorUnsupportedFunction": "Función no disponible",
  "errorInvalidNumber": "Número no válido",
  "errorUnbalancedParentheses": "Paréntesis sin cerrar",
  "errorEmptyExpression": "Expresión vacía",
  "errorNonFiniteResult": "Resultado no finito"
}
```

- **Código literal (`lib/l10n/app_pt_BR.arb`):**

```json
{
  "appName": "RetroCalculator",
  "calculatorTitle": "Calculadora",
  "readyMessage": "Pronto para calcular",
  "modeNormal": "Normal",
  "modeScientific": "Científica",
  "angleDeg": "GRAUS",
  "angleRad": "RAD",
  "historyTitle": "Histórico",
  "historyEmpty": "Nenhum cálculo ainda",
  "clearLabel": "Limpar",
  "backspaceLabel": "Apagar",
  "equalsLabel": "Igual",
  "signLabel": "Alternar sinal",
  "modeToggleLabel": "Alternar modo",
  "resultLabel": "Resultado",
  "keySin": "sen",
  "keyCos": "cos",
  "keyTan": "tan",
  "keyLog": "log",
  "keyLn": "ln",
  "keySqrt": "√",
  "keyPower": "x^y",
  "keyFactorial": "n!",
  "keyPi": "π",
  "keyE": "e",
  "keyLeftParen": "(",
  "keyRightParen": ")",
  "keyAsin": "sen⁻¹",
  "keyAcos": "cos⁻¹",
  "keyAtan": "tan⁻¹",
  "keyReciprocal": "1/x",
  "keySquare": "x²",
  "errorDivisionByZero": "Divisão por zero",
  "errorInvalidExpression": "Expressão inválida",
  "errorInvalidDomain": "Domínio inválido",
  "errorUnsupportedFunction": "Função indisponível",
  "errorInvalidNumber": "Número inválido",
  "errorUnbalancedParentheses": "Parênteses desbalanceados",
  "errorEmptyExpression": "Expressão vazia",
  "errorNonFiniteResult": "Resultado não finito"
}
```

- **Fallback técnico:** `lib/l10n/app_es.arb` contiene las mismas 40 claves que `app_es_PE.arb` y `lib/l10n/app_pt.arb` las mismas que `app_pt_BR.arb`. Flutter 3.44 exige estos ARB base cuando existen locales con región; no amplían el selector de idioma del lote 1.

- **Código literal (`test/unit/i18n/arb_keys_test.dart`, soporte):**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los cinco ARB tienen exactamente las mismas 40 claves', () {
    const List<String> files = <String>[
      'app_en.arb',
      'app_es.arb',
      'app_es_PE.arb',
      'app_pt.arb',
      'app_pt_BR.arb',
    ];
    final List<Set<String>> keySets = files.map((String file) {
      final Object? decoded = jsonDecode(
        File('lib/l10n/$file').readAsStringSync(),
      );
      return (decoded! as Map<String, Object?>).keys.toSet();
    }).toList();
    for (final Set<String> keys in keySets) {
      expect(keys, keySets.first);
    }
    expect(keySets.first, hasLength(40));
  });
}
```

- **Verificar:** `flutter gen-l10n && flutter test test/unit/i18n/arb_keys_test.dart` (verde).

#### T15 — Resolutor de locale, claves y errores localizados

- **Archivos principales:** `lib/core/i18n/locale_resolver.dart` (con `app_strings.dart` y `error_label.dart` como soporte).
- **Criterio de aceptación:** `LocaleResolver.initial()` devuelve `es_PE` por defecto; `resolve` cae a `en` para locales no soportados; `AppStrings` deja de contener texto visible; `errorLabel` traduce todos los códigos usados por el motor.
- **Código literal (`locale_resolver.dart`):**

```dart
import 'package:flutter/material.dart';

class LocaleResolver {
  const LocaleResolver._();

  static const List<Locale> supported = <Locale>[
    Locale('es', 'PE'),
    Locale('en'),
    Locale('pt', 'BR'),
  ];

  static Locale initial() => const Locale('es', 'PE');

  static Locale resolve(Locale? candidate) {
    if (candidate == null) {
      return initial();
    }
    for (final Locale locale in supported) {
      if (locale.languageCode == candidate.languageCode &&
          (locale.countryCode == null ||
              locale.countryCode == candidate.countryCode)) {
        return locale;
      }
    }
    return const Locale('en');
  }

  static String name(Locale locale) => locale.toString();
}
```

- **Código literal (soporte `lib/core/constants/app_strings.dart`, evoluciona el archivo existente):**

```dart
class AppStrings {
  const AppStrings._();

  static const String appName = 'appName';
  static const String calculatorTitle = 'calculatorTitle';
  static const String readyMessage = 'readyMessage';
}
```

- **Código literal (soporte `lib/core/i18n/error_label.dart`):**

```dart
import 'package:retro_calculator/l10n/app_localizations.dart';

String errorLabel(String code, AppLocalizations l10n) {
  return switch (code) {
    'divisionByZero' => l10n.errorDivisionByZero,
    'invalidDomain' => l10n.errorInvalidDomain,
    'unsupportedFunction' => l10n.errorUnsupportedFunction,
    'unsupportedConstant' => l10n.errorUnsupportedFunction,
    'invalidNumber' => l10n.errorInvalidNumber,
    'invalidCharacter' => l10n.errorInvalidNumber,
    'unbalancedParentheses' => l10n.errorUnbalancedParentheses,
    'emptyExpression' => l10n.errorEmptyExpression,
    'unexpectedEnd' => l10n.errorEmptyExpression,
    'nonFiniteResult' => l10n.errorNonFiniteResult,
    _ => l10n.errorInvalidExpression,
  };
}
```

- **Verificar:** `flutter gen-l10n && flutter analyze lib/core/i18n lib/core/constants/app_strings.dart`.

### Slice 3 — Historial global y telemetría local (T16–T21)

#### T16 — Test rojo del historial con tope 50

- **Archivo principal:** `test/unit/calculator/history_store_test.dart` (nuevo).
- **Criterio de aceptación:** falla en rojo por modelos/repositorio inexistentes; exige orden más reciente primero, etiqueta por perfil y descarte del elemento 51.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/models/history_entry.dart';
import 'package:retro_calculator/features/calculator/domain/profiles/calculator_profile.dart';

void main() {
  test('conserva como máximo 50 entradas y la última va primero', () async {
    final HistoryStore store = InMemoryHistoryStore();
    for (int i = 0; i < 51; i++) {
      await store.append(
        HistoryEntry(
          expression: '$i',
          result: i.toDouble(),
          profileId: CalculatorProfileId.normal,
          timestamp: DateTime(2026, 11, 24, 0, i),
        ),
      );
    }
    final List<HistoryEntry> entries = await store.load();
    expect(entries, hasLength(50));
    expect(entries.first.expression, '50');
    expect(entries.last.expression, '1');
  });
}
```

- **Verificar:** `flutter test test/unit/calculator/history_store_test.dart` (rojo esperado).

#### T17 — Modelo de entrada de historial

- **Archivo principal:** `lib/features/calculator/data/models/history_entry.dart` (nuevo).
- **Criterio de aceptación:** serialización JSON ida/vuelta sin pérdida; `profileId` se guarda por nombre (`normal`/`scientific`) para etiquetar la fila en UI.
- **Código literal:**

```dart
import '../../domain/profiles/calculator_profile.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.profileId,
    required this.timestamp,
  });

  final String expression;
  final double result;
  final CalculatorProfileId profileId;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
        'expression': expression,
        'result': result,
        'profileId': profileId.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, Object?> json) {
    return HistoryEntry(
      expression: json['expression']! as String,
      result: (json['result']! as num).toDouble(),
      profileId: CalculatorProfileId.values
          .firstWhere((CalculatorProfileId id) => id.name == json['profileId']),
      timestamp: DateTime.parse(json['timestamp']! as String),
    );
  }
}
```

- **Verificar:** `flutter analyze lib/features/calculator/data/models/history_entry.dart`.

#### T18 — Contrato de historial e implementación en memoria

- **Archivos principales:** `lib/features/calculator/data/local/history_store.dart` e `in_memory_history_store.dart`.
- **Criterio de aceptación:** interfaz asíncrona única; implementación en memoria con tope 50 compartida por todos los tests y por el fallback de la app; el test del slice pasa.
- **Código literal (`history_store.dart`):**

```dart
import '../models/history_entry.dart';

abstract interface class HistoryStore {
  Future<List<HistoryEntry>> load();
  Future<void> append(HistoryEntry entry);
}
```

- **Código literal (`in_memory_history_store.dart`):**

```dart
import '../models/history_entry.dart';
import 'history_store.dart';

class InMemoryHistoryStore implements HistoryStore {
  static const int maxEntries = 50;

  final List<HistoryEntry> _entries = <HistoryEntry>[];

  @override
  Future<List<HistoryEntry>> load() async => List<HistoryEntry>.unmodifiable(_entries);

  @override
  Future<void> append(HistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }
}
```

- **Verificar:** `flutter test test/unit/calculator/history_store_test.dart` (verde).

#### T19 — Persistencia local sin red

- **Archivo principal:** `lib/features/calculator/data/local/shared_preferences_history_store.dart` (y `pubspec.yaml` solo para añadir la dependencia).
- **Criterio de aceptación:** `flutter pub add shared_preferences` ejecutado; la store lee/escribe la clave `calculator.history.v1`, aplica el mismo tope 50 y no contiene ninguna llamada HTTP.
- **Comando previo:** `flutter pub add shared_preferences`.
- **Código literal:**

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import 'history_store.dart';
import 'in_memory_history_store.dart';

class SharedPreferencesHistoryStore implements HistoryStore {
  SharedPreferencesHistoryStore(this._preferences);

  factory SharedPreferencesHistoryStore.create() {
    return SharedPreferencesHistoryStore(SharedPreferences.getInstance());
  }

  static const String storageKey = 'calculator.history.v1';

  final Future<SharedPreferences> _preferences;

  @override
  Future<List<HistoryEntry>> load() async {
    final String? raw = (await _preferences).getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <HistoryEntry>[];
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      return <HistoryEntry>[];
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(HistoryEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> append(HistoryEntry entry) async {
    final List<HistoryEntry> entries = <HistoryEntry>[entry, ...await load()];
    final List<Map<String, Object?>> serializable = entries
        .take(InMemoryHistoryStore.maxEntries)
        .map((HistoryEntry item) => item.toJson())
        .toList(growable: false);
    await (await _preferences)
        .setString(storageKey, jsonEncode(serializable));
  }
}
```

- **Verificar:** `flutter pub get && flutter analyze lib/features/calculator/data/local`.

#### T20 — Test rojo de contadores locales

- **Archivo principal:** `test/unit/calculator/local_counters_test.dart` (nuevo).
- **Criterio de aceptación:** falla en rojo por `LocalCounters` inexistente; exige incremento, lectura y snapshot inmutable.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';

void main() {
  test('cuenta operaciones sin enviar nada', () {
    final LocalCounters counters = LocalCounters();
    counters.increment(LocalCounters.calculationPerformed);
    counters.increment(LocalCounters.calculationPerformed);
    expect(counters.value(LocalCounters.calculationPerformed), 2);
    expect(counters.value(LocalCounters.scientificModeActivated), 0);
    expect(counters.snapshot(), isA<Map<String, int>>());
  });
}
```

- **Verificar:** `flutter test test/unit/calculator/local_counters_test.dart` (rojo esperado).

#### T21 — Contadores locales

- **Archivo principal:** `lib/features/calculator/data/local/local_counters.dart` (nuevo).
- **Criterio de aceptación:** solo estado en memoria, sin imports de red ni plugins; el test del slice pasa.
- **Código literal:**

```dart
class LocalCounters {
  static const String calculationPerformed = 'calculation_performed';
  static const String scientificModeActivated = 'scientific_mode_activated';
  static const String calculationFailed = 'calculation_failed';
  static const String angleModeChanged = 'angle_mode_changed';

  final Map<String, int> _values = <String, int>{};

  void increment(String key) {
    _values[key] = (_values[key] ?? 0) + 1;
  }

  int value(String key) => _values[key] ?? 0;

  Map<String, int> snapshot() => Map<String, int>.unmodifiable(_values);
}
```

- **Verificar:** `flutter test test/unit/calculator/local_counters_test.dart` (verde).

### Slice 4 — Widgets reutilizables y MVVM (T22–T29)

#### T22 — Display LCD de siete segmentos

- **Archivo principal:** `lib/core/widgets/seven_segment_display.dart` (nuevo).
- **Criterio de aceptación:** widget sin estado que pinta dígitos con segmentos activos ámbar (`0xFFFFB000`) e inactivos tenues sobre fondo oscuro (`0xFF1E1B12`); `flutter analyze` limpio; no conoce el motor.
- **Código literal:**

```dart
import 'package:flutter/material.dart';

class SevenSegmentDisplay extends StatelessWidget {
  const SevenSegmentDisplay({
    super.key,
    required this.text,
    this.digitWidth = 26,
    this.digitHeight = 48,
    this.color = const Color(0xFFFFB000),
  });

  final String text;
  final double digitWidth;
  final double digitHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3320)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: CustomPaint(
          painter: _SevenSegmentPainter(
            text: text,
            digitWidth: digitWidth,
            digitHeight: digitHeight,
            color: color,
          ),
          size: Size(
            digitWidth * (text.isEmpty ? 1 : text.length),
            digitHeight,
          ),
        ),
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  const _SevenSegmentPainter({
    required this.text,
    required this.digitWidth,
    required this.digitHeight,
    required this.color,
  });

  static const Map<String, int> _patterns = <String, int>{
    '0': 0b0111111,
    '1': 0b0000110,
    '2': 0b1011011,
    '3': 0b1001111,
    '4': 0b1100110,
    '5': 0b1101101,
    '6': 0b1111101,
    '7': 0b0000111,
    '8': 0b1111111,
    '9': 0b1101111,
    '-': 0b1000000,
  };

  final String text;
  final double digitWidth;
  final double digitHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint active = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint inactive = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double pad = 4;
    final double innerWidth = digitWidth - pad * 2;
    final double innerHeight = digitHeight - pad * 2;
    final String value = text.isEmpty ? '0' : text;

    for (int index = 0; index < value.length; index++) {
      final String char = value[index];
      final double left = index * digitWidth + pad;
      final double top = pad;
      final double middle = top + innerHeight / 2;
      final double bottom = top + innerHeight;
      final double right = left + innerWidth;

      if (char == '.') {
        canvas.drawCircle(Offset(left + 1, bottom), 2.5, active);
        continue;
      }

      final List<Offset> startPoints = <Offset>[
        Offset(left, top),
        Offset(right, top),
        Offset(right, middle),
        Offset(left, bottom),
        Offset(left, middle),
        Offset(left, top),
        Offset(left, middle),
      ];
      final List<Offset> endPoints = <Offset>[
        Offset(right, top),
        Offset(right, middle),
        Offset(right, bottom),
        Offset(right, bottom),
        Offset(left, middle),
        Offset(left, middle),
        Offset(right, middle),
      ];
      final int pattern = _patterns[char] ?? 0;
      for (int segment = 0; segment < 7; segment++) {
        final bool isOn = (pattern & (1 << segment)) != 0;
        canvas.drawLine(
          startPoints[segment],
          endPoints[segment],
          isOn ? active : inactive,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.color != color;
  }
}
```

- **Verificar:** `flutter analyze lib/core/widgets/seven_segment_display.dart`.

#### T23 — Teclado reutilizable

- **Archivo principal:** `lib/core/widgets/calculator_keyboard.dart` (nuevo).
- **Criterio de aceptación:** recibe filas y un mapa de etiquetas localizadas; cada botón expone `Key('calc.key.<token>')` para tests; no importa dominio ni ViewModel.
- **Código literal:**

```dart
import 'package:flutter/material.dart';

class CalculatorKeyboard extends StatelessWidget {
  const CalculatorKeyboard({
    super.key,
    required this.rows,
    required this.labels,
    required this.onKeyTap,
  });

  final List<List<String>> rows;
  final Map<String, String> labels;
  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final List<String> row in rows)
          Expanded(
            child: Row(
              children: <Widget>[
                for (final String key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ElevatedButton(
                        key: Key('calc.key.$key'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => onKeyTap(key),
                        child: FittedBox(
                          child: Text(labels[key] ?? key),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
```

- **Verificar:** `flutter analyze lib/core/widgets/calculator_keyboard.dart`.

#### T24 — Test rojo del ViewModel

- **Archivo principal:** `test/unit/calculator/calculator_view_model_test.dart` (nuevo).
- **Criterio de aceptación:** falla en rojo por ViewModel inexistente; cubre suma, historial global, error de división por cero y contador de activación científica.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';

void main() {
  test('suma y guarda una entrada global', () async {
    final InMemoryHistoryStore store = InMemoryHistoryStore();
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(store, counters);

    vm.input('2');
    vm.input('+');
    vm.input('3');
    await vm.submit();

    expect(vm.displayText, '5');
    expect((await store.load()).single.result, 5);
    expect(counters.value(LocalCounters.calculationPerformed), 1);
  });

  test('expone divisionByZero como clave de error', () async {
    final CalculatorViewModel vm = CalculatorViewModel(
      InMemoryHistoryStore(),
      LocalCounters(),
    );
    vm.input('8');
    vm.input('/');
    vm.input('0');
    await vm.submit();
    expect(vm.errorKey, 'divisionByZero');
  });

  test('el toggle científico incrementa el contador', () {
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(
      InMemoryHistoryStore(),
      counters,
    );
    vm.toggleProfile();
    expect(vm.profile.isScientific, isTrue);
    expect(counters.value(LocalCounters.scientificModeActivated), 1);
  });
}
```

- **Verificar:** `flutter test test/unit/calculator/calculator_view_model_test.dart` (rojo esperado).

#### T25 — ViewModel MVVM

- **Archivo principal:** `lib/features/calculator/presentation/viewmodels/calculator_view_model.dart` (nuevo).
- **Criterio de aceptación:** `ChangeNotifier` sin lógica de cálculo propia (delega en `CalculatorEngine`); actualiza display, error localizado por clave, historial y contadores; los 3 tests del slice pasan.
- **Código literal:**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/calculator_exception.dart';
import '../../../core/i18n/number_formatting.dart';
import '../../data/local/history_store.dart';
import '../../data/local/local_counters.dart';
import '../../data/models/history_entry.dart';
import '../../domain/engine/angle_mode.dart';
import '../../domain/engine/calculator_engine.dart';
import '../../domain/profiles/calculator_profile.dart';
import '../../domain/profiles/profiles.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel(this._history, this._counters) {
    unawaited(loadHistory());
  }

  final HistoryStore _history;
  final LocalCounters _counters;
  final CalculatorEngine _engine = const CalculatorEngine();

  CalculatorProfile _profile = CalculatorProfiles.normal;
  AngleMode _angleMode = AngleMode.degrees;
  DecimalSeparator _separator = DecimalSeparator.comma;
  String _expression = '';
  String? _errorKey;
  double? _lastResult;
  double _memory = 0;
  List<HistoryEntry> _historyEntries = <HistoryEntry>[];

  CalculatorProfile get profile => _profile;
  AngleMode get angleMode => _angleMode;
  String? get errorKey => _errorKey;
  List<HistoryEntry> get history => List<HistoryEntry>.unmodifiable(_historyEntries);
  String get expressionText => _expression.isEmpty ? '0' : _expression;
  String get displayText => _errorKey != null
      ? ''
      : _lastResult == null
          ? expressionText
          : _format(_lastResult!);

  void setLocaleName(String localeName) {
    final DecimalSeparator next = separatorForLocale(localeName);
    if (next == _separator) {
      return;
    }
    _separator = next;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _historyEntries = await _history.load();
    notifyListeners();
  }

  void input(String key) {
    switch (key) {
      case '=':
        unawaited(submit());
      case 'C':
        _clear();
      case '⌫':
        _backspace();
      case '±':
        _toggleSign();
      case 'MODE':
        toggleProfile();
      case 'DEG':
        setAngleMode(AngleMode.degrees);
      case 'RAD':
        setAngleMode(AngleMode.radians);
      case 'MC':
        _memory = 0;
      case 'MR':
        _append(_format(_memory));
      case 'M+':
        _memory += _lastResult ?? 0;
      case 'M-':
        _memory -= _lastResult ?? 0;
      default:
        _append(_canonical(key));
    }
  }

  void toggleProfile() {
    _profile = _profile.isScientific
        ? CalculatorProfiles.normal
        : CalculatorProfiles.scientific;
    if (_profile.isScientific) {
      _counters.increment(LocalCounters.scientificModeActivated);
    }
    _clear();
  }

  void setAngleMode(AngleMode mode) {
    if (_angleMode == mode) {
      return;
    }
    _angleMode = mode;
    _counters.increment(LocalCounters.angleModeChanged);
    notifyListeners();
  }

  Future<void> submit() async {
    if (_expression.trim().isEmpty) {
      _errorKey = 'emptyExpression';
      notifyListeners();
      return;
    }
    try {
      final double result = _engine.evaluate(
        _expression,
        _profile,
        angleMode: _angleMode,
      );
      await _history.append(
        HistoryEntry(
          expression: _expression,
          result: result,
          profileId: _profile.id,
          timestamp: DateTime.now(),
        ),
      );
      _historyEntries = await _history.load();
      _lastResult = result;
      _errorKey = null;
      _counters.increment(LocalCounters.calculationPerformed);
    } on CalculatorException catch (error) {
      _errorKey = error.message;
      _counters.increment(LocalCounters.calculationFailed);
    }
    notifyListeners();
  }

  String _canonical(String key) {
    return switch (key) {
      'π' => 'pi',
      'x^y' => '^',
      '√' => 'sqrt(',
      'n!' => '!',
      '1/x' => 'inv(',
      'x²' => 'sqr(',
      _ => key,
    };
  }

  void _append(String token) {
    _expression += token;
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _clear() {
    _expression = '';
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _toggleSign() {
    _expression = _expression.isEmpty ? '-' : '-$_expression';
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  String _format(double value) {
    return formatNumber(
      value,
      separator: _separator,
      maxFractionDigits: _profile.decimalDigits,
    );
  }
}
```

- **Verificar:** `flutter test test/unit/calculator/calculator_view_model_test.dart` (verde).

#### T26 — Panel de historial

- **Archivo principal:** `lib/features/calculator/presentation/widgets/history_panel.dart` (nuevo).
- **Criterio de aceptación:** muestra máximo 50 filas `expresión = resultado`, etiqueta derivada de `profileId` con textos de ARB y mensaje vacío localizado; nunca consume la store directamente.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

import '../../../core/i18n/number_formatting.dart';
import '../../data/models/history_entry.dart';
import '../../domain/profiles/calculator_profile.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.entries,
    required this.separator,
    required this.decimalDigits,
  });

  final List<HistoryEntry> entries;
  final DecimalSeparator separator;
  final int decimalDigits;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      return ListTile(title: Text(l10n.historyEmpty));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final HistoryEntry entry = entries[index];
        final String label = entry.profileId == CalculatorProfileId.scientific
            ? l10n.modeScientific
            : l10n.modeNormal;
        return ListTile(
          key: Key('calc.history.$index'),
          title: Text('${entry.expression} = ${formatNumber(entry.result, separator: separator, maxFractionDigits: decimalDigits)}'),
          subtitle: Text(label),
        );
      },
    );
  }
}
```

- **Verificar:** `flutter analyze lib/features/calculator/presentation/widgets/history_panel.dart`.

#### T27 — Test rojo de la página de la calculadora

- **Archivo principal:** `test/widget/calculator_page_test.dart` (nuevo).
- **Criterio de aceptación:** falla en rojo hasta T28; comprueba resultado, toggle científico, toggle DEG/RAD, historial global y error localizado.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) {
    return tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );
  }

  testWidgets('calcula y muestra el resultado en el display', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    for (final String key in <String>['2', '+', '3', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(find.text('5'), findsWidgets);
  });

  testWidgets('el toggle revela las teclas científicas y DEG/RAD', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('calc.key.sin(')), findsNothing);

    await tester.tap(find.byKey(const Key('calc.toggle.mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calc.key.sin(')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calc.toggle.angle')));
    await tester.pumpAndSettle();
    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;
    expect(find.text(l10n.angleRad), findsOneWidget);
  });

  testWidgets('el historial es global y el error está localizado', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;

    for (final String key in <String>['1', '/', '0', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(find.text(l10n.errorDivisionByZero), findsOneWidget);

    final CalculatorViewModel vm = Provider.of<CalculatorViewModel>(
      tester.element(find.byType(CalculatorPage)),
      listen: false,
    );
    vm.toggleProfile();
    await tester.pumpAndSettle();
    expect(vm.history, isEmpty);
  });
}
```

- **Verificar:** `flutter test test/widget/calculator_page_test.dart` (rojo esperado).

#### T28 — Integración de `CalculatorPage`

- **Archivo principal:** `lib/features/calculator/presentation/calculator_page.dart` (evoluciona el shell existente).
- **Criterio de aceptación:** la página consume Provider, construye etiquetas desde ARB, pasa el separador y decimales al display/panel y expone las keys `calc.toggle.mode` y `calc.toggle.angle`; el test del slice pasa.
- **Código literal:**

```dart
import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/error_label.dart';
import '../../../core/i18n/locale_resolver.dart';
import '../../../core/i18n/number_formatting.dart';
import '../../../core/widgets/calculator_keyboard.dart';
import '../../../core/widgets/seven_segment_display.dart';
import '../../domain/engine/angle_mode.dart';
import 'viewmodels/calculator_view_model.dart';
import 'widgets/history_panel.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String localeName = LocaleResolver.name(
      LocaleResolver.resolve(Localizations.localeOf(context)),
    );
    context.read<CalculatorViewModel>().setLocaleName(localeName);
  }

  Map<String, String> _labels(AppLocalizations l10n) {
    return <String, String>{
      'C': l10n.clearLabel,
      '⌫': l10n.backspaceLabel,
      '=': l10n.equalsLabel,
      '±': l10n.signLabel,
      'sin(': l10n.keySin,
      'cos(': l10n.keyCos,
      'tan(': l10n.keyTan,
      'log(': l10n.keyLog,
      'ln(': l10n.keyLn,
      'sqrt(': l10n.keySqrt,
      '^': l10n.keyPower,
      '!': l10n.keyFactorial,
      'pi': l10n.keyPi,
      'e': l10n.keyE,
      '(': l10n.keyLeftParen,
      ')': l10n.keyRightParen,
      'asin(': l10n.keyAsin,
      'acos(': l10n.keyAcos,
      'atan(': l10n.keyAtan,
      '1/x': l10n.keyReciprocal,
      'x²': l10n.keySquare,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final CalculatorViewModel vm = context.watch<CalculatorViewModel>();
    final DecimalSeparator separator =
        separatorForLocale(LocaleResolver.name(Localizations.localeOf(context)));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calculatorTitle),
        actions: <Widget>[
          IconButton(
            key: const Key('calc.toggle.mode'),
            tooltip: l10n.modeToggleLabel,
            icon: Icon(
              vm.profile.isScientific ? Icons.calculate : Icons.science,
            ),
            onPressed: vm.toggleProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SevenSegmentDisplay(text: vm.displayText),
                    ),
                    if (vm.errorKey != null)
                      Text(
                        errorLabel(vm.errorKey!, l10n),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    if (vm.profile.isScientific)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ChoiceChip(
                              key: const Key('calc.toggle.angle'),
                              label: Text(
                                vm.angleMode == AngleMode.degrees
                                    ? l10n.angleDeg
                                    : l10n.angleRad,
                              ),
                              selected: vm.angleMode == AngleMode.radians,
                              onSelected: (_) => vm.setAngleMode(
                                vm.angleMode == AngleMode.degrees
                                    ? AngleMode.radians
                                    : AngleMode.degrees,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 380,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CalculatorKeyboard(
                          rows: vm.profile.keyRows,
                          labels: _labels(l10n),
                          onKeyTap: vm.input,
                        ),
                      ),
                    ),
                    ExpansionTile(
                      title: Text(l10n.historyTitle),
                      children: <Widget>[
                        HistoryPanel(
                          entries: vm.history,
                          separator: separator,
                          decimalDigits: vm.profile.decimalDigits,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- **Verificar:** `flutter test test/widget/calculator_page_test.dart` (verde).

#### T29 — Cableado de providers y evolución de `app_test.dart`

- **Archivos principales:** `lib/app.dart` (evoluciona) con `test/widget/app_test.dart` (evoluciona) como soporte.
- **Criterio de aceptación:** `MultiProvider` inyecta `HistoryStore`, `LocalCounters` y `CalculatorViewModel`; se usan delegados/locale de `AppLocalizations`; `routes.dart` sigue intacto; el test de arranque pasa con stores en memoria.
- **Código literal (`lib/app.dart`):**

```dart
import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'core/design_system/design_system.dart';
import 'core/i18n/locale_resolver.dart';
import 'features/calculator/data/local/history_store.dart';
import 'features/calculator/data/local/local_counters.dart';
import 'features/calculator/data/local/shared_preferences_history_store.dart';
import 'features/calculator/presentation/viewmodels/calculator_view_model.dart';

class RetroCalculatorApp extends StatelessWidget {
  const RetroCalculatorApp({
    super.key,
    HistoryStore? historyStore,
    LocalCounters? counters,
  })  : _historyStore = historyStore,
        _counters = counters;

  final HistoryStore? _historyStore;
  final LocalCounters? _counters;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HistoryStore>(
          create: (_) =>
              _historyStore ?? SharedPreferencesHistoryStore.create(),
        ),
        Provider<LocalCounters>(
          create: (_) => _counters ?? LocalCounters(),
        ),
        ChangeNotifierProvider<CalculatorViewModel>(
          create: (BuildContext context) => CalculatorViewModel(
            context.read<HistoryStore>(),
            context.read<LocalCounters>(),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)!.appName,
        debugShowCheckedModeBanner: false,
        locale: LocaleResolver.initial(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: DSTheme.toMaterialTheme(Brightness.light),
        darkTheme: DSTheme.toMaterialTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
```

- **Código literal (`test/widget/app_test.dart`, evoluciona):**

```dart
import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';

void main() {
  testWidgets('la app arranca y muestra la calculadora', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;
    expect(find.text(l10n.calculatorTitle), findsOneWidget);
    expect(find.byKey(const Key('calc.key.7')), findsOneWidget);
  });
}
```

- **Verificar:** `flutter test test/widget/app_test.dart` (verde).

#### T30 — Regresión: el cálculo no depende de estado externo

- **Archivo principal:** `test/unit/calculator/engine_regression_test.dart` (nuevo).
- **Criterio de aceptación:** con historial y contadores manipulados, el resultado del motor es idéntico al de una llamada directa; no hay imports de monetización, skins, plataforma ni red.
- **Código literal:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/i18n/number_formatting.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/domain/engine/calculator_engine.dart';
import 'package:retro_calculator/features/calculator/domain/profiles/profiles.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';

void main() {
  test('historial y contadores no alteran el resultado base', () async {
    final InMemoryHistoryStore store = InMemoryHistoryStore();
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(store, counters);

    vm.input('2');
    vm.input('+');
    vm.input('3');
    await vm.submit();

    final double direct = const CalculatorEngine().evaluate(
      '2+3',
      CalculatorProfiles.normal,
    );
    expect(
      vm.displayText,
      formatNumber(
        direct,
        separator: DecimalSeparator.comma,
        maxFractionDigits: CalculatorProfiles.normal.decimalDigits,
      ),
    );
    expect(counters.value(LocalCounters.calculationPerformed), 1);
  });
}
```

- **Verificar:** `flutter test test/unit/calculator/engine_regression_test.dart`.

## Verificación final

Ejecutar desde la raíz del worktree `.worktrees/feature-calculator-engine` (creado con `using-git-worktrees`; ejecución con `subagent-driven-development` y review de spec y calidad antes de merge):

```bash
flutter gen-l10n
flutter pub get
flutter analyze
flutter test
```

Criterio de salida: `flutter analyze` sin issues y `flutter test` completamente en verde, incluidos `test/unit/calculator/parser_test.dart`, `test/unit/calculator/history_store_test.dart`, `test/unit/calculator/local_counters_test.dart`, `test/unit/calculator/calculator_view_model_test.dart`, `test/unit/calculator/engine_regression_test.dart`, `test/unit/i18n/number_formatting_test.dart`, `test/widget/calculator_page_test.dart` y `test/widget/app_test.dart`. Además, `flutter gen-l10n` debe regenerar sin errores y `flutter test test/unit/i18n/arb_keys_test.dart` debe confirmar las 40 claves compartidas.

## Riesgos

- **Precedencia DEG/RAD:** la conversión vive solo en `ScientificCapability.callFunction`; si se repite en el evaluador o en la UI, `sin(30)` y `sin(pi/2)` divergen. Mitigación: tests T01 con ambos modos y revisión de que la UI nunca pase factores de conversión; las inversas usan la conversión contraria en `_fromRadians`.
- **Porcentaje contextual:** `50 + 10%` debe ser `55`, no `50.1`. Mitigación: `Evaluator._binary` detecta `PercentNode` a la derecha y aplica el tanto por ciento sobre el operando izquierdo; el caso aislado `50%` sigue siendo `0.5`.
- **Coma flotante:** resultados como `0.1 + 0.2` y raíces/potencias pueden acumular error. Mitigación: `closeTo(1e-12)` en tests, recorte controlado de decimales en `formatNumber` y `nonFiniteResult` para desbordamientos; no introducir `Decimal` en este MVP.
- **División por cero:** debe ser `CalculatorException('divisionByZero')`, nunca `Infinity` ni un crash. Mitigación: test T01, mapeo en `error_label.dart` y verificación de que el display muestra el texto localizado.
- **Claves ARB desincronizadas:** una clave ausente en `es_PE` o `pt_BR` rompe la generación o deja texto sin traducir. Mitigación: comando de comparación de T14, uso exclusivo de `AppLocalizations` en UI y `AppStrings` reducido a claves.
- **La UI nunca debe alterar el motor:** el ViewModel solo compone tokens y llama a `CalculatorEngine`; no se añaden reglas de cálculo en widgets, ni formatos con separadores dentro de la expresión, ni dependencias de monetización/skins. Mitigación: test T30, imports revisados y regla de dependencias de `docs/architecture.md`.
- **Persistencia local:** `shared_preferences` puede no estar inicializado en tests; por eso `RetroCalculatorApp` acepta stores inyectados y los tests usan `InMemoryHistoryStore`.
- **Dependencia `shared_preferences`:** ya se añadió y retiró durante el bootstrap por avisos de plugins Linux/Windows con Flutter 3.44. Mitigación: reintroducirla solo en T19, ejecutar `flutter analyze` completo y, si reaparecen avisos, aislar la persistencia tras `lib/platform/` sin bloquear el historial en memoria.









