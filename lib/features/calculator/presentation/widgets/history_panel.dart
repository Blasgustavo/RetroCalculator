import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

import '../../../../core/i18n/number_formatting.dart';
import '../../data/models/history_entry.dart';

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
        final String label = entry.profileId == 'scientific'
            ? l10n.modeScientific
            : l10n.modeNormal;
        return ListTile(
          key: Key('calc.history.$index'),
          title: Text(
            '${entry.expression} = ${formatNumber(entry.result, separator: separator, maxFractionDigits: decimalDigits)}',
          ),
          subtitle: Text(label),
        );
      },
    );
  }
}
