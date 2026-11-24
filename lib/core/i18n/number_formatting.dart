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
  final String trimmed = digits == 0
      ? fixed
      : fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
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
