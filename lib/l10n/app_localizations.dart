import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es', 'PE'),
    Locale('en'),
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'RetroCalculator'**
  String get appName;

  /// No description provided for @calculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTitle;

  /// No description provided for @readyMessage.
  ///
  /// In en, this message translates to:
  /// **'Ready to calculate'**
  String get readyMessage;

  /// No description provided for @modeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get modeNormal;

  /// No description provided for @modeScientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get modeScientific;

  /// No description provided for @angleDeg.
  ///
  /// In en, this message translates to:
  /// **'DEG'**
  String get angleDeg;

  /// No description provided for @angleRad.
  ///
  /// In en, this message translates to:
  /// **'RAD'**
  String get angleRad;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No calculations yet'**
  String get historyEmpty;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @backspaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get backspaceLabel;

  /// No description provided for @equalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get equalsLabel;

  /// No description provided for @signLabel.
  ///
  /// In en, this message translates to:
  /// **'Change sign'**
  String get signLabel;

  /// No description provided for @modeToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch mode'**
  String get modeToggleLabel;

  /// No description provided for @resultLabel.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultLabel;

  /// No description provided for @keySin.
  ///
  /// In en, this message translates to:
  /// **'sin'**
  String get keySin;

  /// No description provided for @keyCos.
  ///
  /// In en, this message translates to:
  /// **'cos'**
  String get keyCos;

  /// No description provided for @keyTan.
  ///
  /// In en, this message translates to:
  /// **'tan'**
  String get keyTan;

  /// No description provided for @keyLog.
  ///
  /// In en, this message translates to:
  /// **'log'**
  String get keyLog;

  /// No description provided for @keyLn.
  ///
  /// In en, this message translates to:
  /// **'ln'**
  String get keyLn;

  /// No description provided for @keySqrt.
  ///
  /// In en, this message translates to:
  /// **'√'**
  String get keySqrt;

  /// No description provided for @keyPower.
  ///
  /// In en, this message translates to:
  /// **'x^y'**
  String get keyPower;

  /// No description provided for @keyFactorial.
  ///
  /// In en, this message translates to:
  /// **'n!'**
  String get keyFactorial;

  /// No description provided for @keyPi.
  ///
  /// In en, this message translates to:
  /// **'π'**
  String get keyPi;

  /// No description provided for @keyE.
  ///
  /// In en, this message translates to:
  /// **'e'**
  String get keyE;

  /// No description provided for @keyLeftParen.
  ///
  /// In en, this message translates to:
  /// **'('**
  String get keyLeftParen;

  /// No description provided for @keyRightParen.
  ///
  /// In en, this message translates to:
  /// **')'**
  String get keyRightParen;

  /// No description provided for @keyAsin.
  ///
  /// In en, this message translates to:
  /// **'asin'**
  String get keyAsin;

  /// No description provided for @keyAcos.
  ///
  /// In en, this message translates to:
  /// **'acos'**
  String get keyAcos;

  /// No description provided for @keyAtan.
  ///
  /// In en, this message translates to:
  /// **'atan'**
  String get keyAtan;

  /// No description provided for @keyReciprocal.
  ///
  /// In en, this message translates to:
  /// **'1/x'**
  String get keyReciprocal;

  /// No description provided for @keySquare.
  ///
  /// In en, this message translates to:
  /// **'x²'**
  String get keySquare;

  /// No description provided for @errorDivisionByZero.
  ///
  /// In en, this message translates to:
  /// **'Division by zero'**
  String get errorDivisionByZero;

  /// No description provided for @errorInvalidExpression.
  ///
  /// In en, this message translates to:
  /// **'Invalid expression'**
  String get errorInvalidExpression;

  /// No description provided for @errorInvalidDomain.
  ///
  /// In en, this message translates to:
  /// **'Invalid domain'**
  String get errorInvalidDomain;

  /// No description provided for @errorUnsupportedFunction.
  ///
  /// In en, this message translates to:
  /// **'Function not available'**
  String get errorUnsupportedFunction;

  /// No description provided for @errorInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get errorInvalidNumber;

  /// No description provided for @errorUnbalancedParentheses.
  ///
  /// In en, this message translates to:
  /// **'Unbalanced parentheses'**
  String get errorUnbalancedParentheses;

  /// No description provided for @errorEmptyExpression.
  ///
  /// In en, this message translates to:
  /// **'Empty expression'**
  String get errorEmptyExpression;

  /// No description provided for @errorNonFiniteResult.
  ///
  /// In en, this message translates to:
  /// **'Non-finite result'**
  String get errorNonFiniteResult;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'PE':
            return AppLocalizationsEsPe();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
