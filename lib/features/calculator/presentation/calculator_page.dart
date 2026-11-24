import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/error_label.dart';
import '../../../core/i18n/locale_resolver.dart';
import '../../../core/i18n/number_formatting.dart';
import '../../../core/widgets/calculator_keyboard.dart';
import '../../../core/widgets/seven_segment_display.dart';
import '../domain/engine/angle_mode.dart';
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
    final DecimalSeparator separator = separatorForLocale(
      LocaleResolver.name(Localizations.localeOf(context)),
    );

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
                      child: SevenSegmentDisplay(
                        key: const Key('calc.display'),
                        text: vm.displayText,
                      ),
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
