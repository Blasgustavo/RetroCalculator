// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'RetroCalculator';

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get readyMessage => 'Ready to calculate';

  @override
  String get modeNormal => 'Normal';

  @override
  String get modeScientific => 'Scientific';

  @override
  String get angleDeg => 'DEG';

  @override
  String get angleRad => 'RAD';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No calculations yet';

  @override
  String get clearLabel => 'Clear';

  @override
  String get backspaceLabel => 'Backspace';

  @override
  String get equalsLabel => 'Equals';

  @override
  String get signLabel => 'Change sign';

  @override
  String get modeToggleLabel => 'Switch mode';

  @override
  String get resultLabel => 'Result';

  @override
  String get keySin => 'sin';

  @override
  String get keyCos => 'cos';

  @override
  String get keyTan => 'tan';

  @override
  String get keyLog => 'log';

  @override
  String get keyLn => 'ln';

  @override
  String get keySqrt => '√';

  @override
  String get keyPower => 'x^y';

  @override
  String get keyFactorial => 'n!';

  @override
  String get keyPi => 'π';

  @override
  String get keyE => 'e';

  @override
  String get keyLeftParen => '(';

  @override
  String get keyRightParen => ')';

  @override
  String get keyAsin => 'asin';

  @override
  String get keyAcos => 'acos';

  @override
  String get keyAtan => 'atan';

  @override
  String get keyReciprocal => '1/x';

  @override
  String get keySquare => 'x²';

  @override
  String get errorDivisionByZero => 'Division by zero';

  @override
  String get errorInvalidExpression => 'Invalid expression';

  @override
  String get errorInvalidDomain => 'Invalid domain';

  @override
  String get errorUnsupportedFunction => 'Function not available';

  @override
  String get errorInvalidNumber => 'Invalid number';

  @override
  String get errorUnbalancedParentheses => 'Unbalanced parentheses';

  @override
  String get errorEmptyExpression => 'Empty expression';

  @override
  String get errorNonFiniteResult => 'Non-finite result';

  @override
  String get skinSelectorTitle => 'Skin selector';

  @override
  String get skinClassicName => 'Classic amber';

  @override
  String get skinLcdClassicaName => 'Classic LCD';

  @override
  String get skinResetLabel => 'Reset theme';
}
