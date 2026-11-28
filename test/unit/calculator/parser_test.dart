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
    id: 'normal',
    labelKey: 'modeNormal',
    capability: BasicCapability(),
    isScientific: false,
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 8,
    keyRows: <List<String>>[],
  );
  const CalculatorProfile scientific = CalculatorProfile(
    id: 'scientific',
    labelKey: 'modeScientific',
    capability: ScientificCapability(),
    isScientific: true,
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 10,
    keyRows: <List<String>>[],
  );

  group('Lexer', () {
    test(
      'acepta coma y punto como separador decimal y rechaza separadores sin dígitos',
      () {
        expect(const Lexer().tokenize('1,5').single.lexeme, '1.5');
        expect(const Lexer().tokenize('1.5').single.lexeme, '1.5');
        expect(
          () => engine.evaluate('.', normal),
          throwsA(
            isA<CalculatorException>().having(
              (CalculatorException e) => e.message,
              'código',
              'invalidNumber',
            ),
          ),
        );
        expect(
          () => engine.evaluate(',', normal),
          throwsA(
            isA<CalculatorException>().having(
              (CalculatorException e) => e.message,
              'código',
              'invalidNumber',
            ),
          ),
        );
        expect(const Lexer().tokenize('.5').single.lexeme, '0.5');
        expect(const Lexer().tokenize('1.').single.lexeme, '1.0');
        expect(engine.evaluate('.5', normal), 0.5);
        expect(engine.evaluate('1.', normal), 1);
      },
    );
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
        engine.evaluate(
          'sin(pi / 2)',
          scientific,
          angleMode: AngleMode.radians,
        ),
        closeTo(1, 1e-12),
      );
    });

    test('logaritmo decimal: log(100) == 2', () {
      expect(engine.evaluate('log(100)', scientific), closeTo(2, 1e-12));
    });

    test('inversas, recíproco y cuadrado', () {
      expect(engine.evaluate('asin(1)', scientific), closeTo(90, 1e-12));
      expect(
        engine.evaluate('asin(1)', scientific, angleMode: AngleMode.radians),
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
