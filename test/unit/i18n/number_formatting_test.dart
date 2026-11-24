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
      formatNumber(
        1 / 3,
        separator: DecimalSeparator.comma,
        maxFractionDigits: 3,
      ),
      '0,333',
    );
    expect(
      formatNumber(100, separator: DecimalSeparator.dot, maxFractionDigits: 0),
      '100',
    );
    expect(
      formatNumber(0, separator: DecimalSeparator.comma, maxFractionDigits: 0),
      '0',
    );
  });
}
