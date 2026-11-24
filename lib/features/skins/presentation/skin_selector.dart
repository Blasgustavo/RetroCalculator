import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

import '../data/skin_repository.dart';
import '../domain/skin.dart';
import 'skin_controller.dart';

class SkinSelector extends StatefulWidget {
  const SkinSelector({super.key});

  @override
  State<SkinSelector> createState() => _SkinSelectorState();
}

class _SkinSelectorState extends State<SkinSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SkinController>().loadCatalog(
        context.read<SkinRepository>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SkinController controller = context.watch<SkinController>();
    return ExpansionTile(
      key: const Key('skin.selector'),
      title: Text(l10n.skinSelectorTitle),
      children: <Widget>[
        for (final Skin skin in controller.catalog)
          ListTile(
            key: Key('skin.option.${skin.id}'),
            title: Text(_name(l10n, skin.nameKey)),
            trailing: controller.selected.id == skin.id
                ? const Icon(Icons.check)
                : null,
            onTap: () => context.read<SkinController>().select(skin.id),
          ),
        ListTile(
          key: const Key('skin.reset'),
          title: Text(l10n.skinResetLabel),
          onTap: () => context.read<SkinController>().reset(),
        ),
      ],
    );
  }

  String _name(AppLocalizations l10n, String key) {
    return switch (key) {
      'skinClassicName' => l10n.skinClassicName,
      'skinLcdClassicaName' => l10n.skinLcdClassicaName,
      _ => key,
    };
  }
}
