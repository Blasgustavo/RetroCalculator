import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

import '../../../core/widgets/spec_breakpoint.dart';
import '../../../core/widgets/spec_renderer.dart';
import '../data/generated/screens.g.dart';
import '../data/skin_repository.dart';
import '../domain/skin.dart';
import 'skin_controller.dart';
import 'skin_scope.dart';

/// Compatibilidad: delega en [SkinSelectorScreen], que es el único punto que
/// carga el catálogo y renderiza el cuerpo del spec.
class SkinSelector extends StatelessWidget {
  const SkinSelector({super.key});

  @override
  Widget build(BuildContext context) => const SkinSelectorScreen();
}

/// Pantalla compartida de skins: el cuerpo sale de `screenSpecs['selector']`.
/// Conserva la carga remota del catálogo que antes vivía en `SkinSelector`.
class SkinSelectorScreen extends StatefulWidget {
  const SkinSelectorScreen({super.key});

  @override
  State<SkinSelectorScreen> createState() => _SkinSelectorScreenState();
}

class _SkinSelectorScreenState extends State<SkinSelectorScreen> {
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
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final String breakpoint = SpecBreakpoint.of(constraints.maxWidth);
        final List<Object?> nodes =
            screenSpecs['selector']?[breakpoint] ?? const <Object?>[];
        return SpecRenderer(
          nodes: nodes,
          renderContext: SpecRenderContext(
            tokens: SkinScope.tokensOf(context),
            title: l10n?.skinSelectorTitle ?? '',
            strings: <String, String>{
              'skinSelectorTitle': l10n?.skinSelectorTitle ?? '',
            },
            selectorBuilder: (BuildContext context) =>
                const _SkinSelectorOptions(),
          ),
        );
      },
    );
  }
}

/// Hoja de dominio: mantiene las keys heredadas del selector del MVP.
class _SkinSelectorOptions extends StatelessWidget {
  const _SkinSelectorOptions();

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
