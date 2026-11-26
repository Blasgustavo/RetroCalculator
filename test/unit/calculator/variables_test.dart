import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/errors/calculator_exception.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';
import 'package:retro_calculator/features/calculator/domain/engine/angle_mode.dart';
import 'package:retro_calculator/features/calculator/domain/engine/calculator_engine.dart';
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

  Matcher throwsCode(String code) => throwsA(
    isA<CalculatorException>().having(
      (CalculatorException e) => e.message,
      'código',
      code,
    ),
  );

  test('2+3 sigue evaluando 5 con el perfil básico', () {
    expect(engine.evaluate('2+3', normal), 5);
  });

  test('resuelve variables declaradas en una fórmula', () {
    expect(
      engine.evaluate(
        'base*(1+tasa/100)',
        normal,
        variables: <String, num>{'base': 100, 'tasa': 18},
      ),
      118,
    );
  });

  test('una variable no declarada falla con unknownVariable', () {
    expect(
      () => engine.evaluate(
        'base+foo',
        normal,
        variables: <String, num>{'base': 100},
      ),
      throwsCode('unknownVariable'),
    );
  });

  test('sin mapa de variables, pi sigue siendo constante y un id desconocido '
      'mantiene unsupportedConstant', () {
    expect(engine.evaluate('pi', scientific), closeTo(math.pi, 1e-12));
    expect(
      () => engine.evaluate('foo', normal),
      throwsCode('unsupportedConstant'),
    );
    expect(
      () => engine.evaluate('foo', scientific),
      throwsCode('unsupportedConstant'),
    );
  });

  test('una variable declarada prevalece sobre una constante soportada', () {
    expect(
      engine.evaluate('pi', scientific, variables: <String, num>{'PI': 3}),
      3,
    );
  });

  test('normaliza a minúsculas las claves y los identificadores', () {
    expect(
      engine.evaluate(
        'BASE + Tasa',
        normal,
        variables: <String, num>{'Base': 100, 'TASA': 18},
      ),
      118,
    );
  });

  test('rechaza claves que colisionan al normalizar a minúsculas', () {
    // El orden de entrada no debe decidir el ganador: ambas son inválidas.
    expect(
      () => engine.evaluate(
        'base',
        normal,
        variables: <String, num>{'Base': 1, 'BASE': 2},
      ),
      throwsCode('duplicateVariable'),
    );
    expect(
      () => engine.evaluate(
        'base',
        normal,
        variables: <String, num>{'BASE': 2, 'Base': 1},
      ),
      throwsCode('duplicateVariable'),
    );
  });

  test('rechaza identificadores con caracteres no ASCII según el lexer', () {
    expect(
      () =>
          engine.evaluate('báse', normal, variables: <String, num>{'báse': 1}),
      throwsCode('invalidCharacter'),
    );
  });

  test('exceder el presupuesto de pasos falla con stepBudgetExceeded', () {
    // 51 grupos (1+1) = 203 nodos (200 permitidos) y profundidad 53 (< 64),
    // así que el límite que salta es el de pasos, no el de profundidad.
    final String expression = List<String>.generate(
      51,
      (_) => '(1+1)',
    ).join('*');
    expect(
      () => engine.evaluate(expression, normal),
      throwsCode('stepBudgetExceeded'),
    );
  });

  test('exceder la profundidad máxima falla con maxDepthExceeded', () {
    // 70 términos = 139 nodos (< 200) pero 70 niveles de recursión (> 64).
    final String expression = List<String>.generate(70, (_) => '1').join('+');
    expect(
      () => engine.evaluate(expression, normal),
      throwsCode('maxDepthExceeded'),
    );
  });

  test('el parser limita también la profundidad de paréntesis anidados', () {
    final String expression = '${'(' * 65}1${')' * 65}';
    expect(
      () => engine.evaluate(expression, normal),
      throwsCode('maxDepthExceeded'),
    );
  });
}
