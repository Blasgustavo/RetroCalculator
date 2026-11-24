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
