import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/core/design_system/design_system.dart';
import 'package:retro_calculator/core/i18n/locale_resolver.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';
import 'package:retro_calculator/features/skins/data/local/skin_cache.dart';
import 'package:retro_calculator/features/skins/data/skin_repository.dart';
import 'package:retro_calculator/features/skins/domain/skin.dart';
import 'package:retro_calculator/features/skins/presentation/skin_controller.dart';
import 'package:retro_calculator/features/skins/presentation/skin_scope.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:retro_calculator/platform/preferences/key_value_store.dart';

class _MemoryStore implements KeyValueStore {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> setString(String key, String value) async {}
}

class _StaticSource implements SkinManifestSource {
  const _StaticSource(this.raw);

  final String raw;

  @override
  Future<String> fetch() async => raw;
}

void main() {
  testWidgets(
    'la página carga el catálogo remoto y muestra la skin adicional',
    (WidgetTester tester) async {
      final Map<String, dynamic> manifest =
          jsonDecode(File('assets/catalog/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      manifest['version'] = 2;
      final List<dynamic> entries = manifest['entries'] as List<dynamic>;
      entries.add(
        Map<String, dynamic>.from(entries.single as Map<String, dynamic>)
          ..['id'] = 'remote_extra'
          ..['nameKey'] = 'remoteExtraName',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<InMemoryHistoryStore>(
              create: (_) => InMemoryHistoryStore(),
            ),
            Provider<LocalCounters>(create: (_) => LocalCounters()),
            ChangeNotifierProvider<CalculatorViewModel>(
              create: (BuildContext context) => CalculatorViewModel(
                context.read<InMemoryHistoryStore>(),
                context.read<LocalCounters>(),
              ),
            ),
            Provider<SkinRepository>(
              create: (_) => SkinRepository.remote(
                _StaticSource(jsonEncode(manifest)),
                SkinCache(_MemoryStore()),
              ),
            ),
            ChangeNotifierProvider<SkinController>(
              create: (_) => SkinController(),
            ),
          ],
          child: Builder(
            builder: (BuildContext context) => SkinScope(
              controller: context.read<SkinController>(),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: LocaleResolver.initial(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: DSTheme.toMaterialTheme(Brightness.light),
                home: const CalculatorPage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SkinController controller = tester
          .element(find.byType(CalculatorPage))
          .read<SkinController>();
      expect(
        controller.catalog.map((Skin skin) => skin.id),
        contains('remote_extra'),
      );

      await tester.ensureVisible(find.byKey(const Key('skin.selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skin.selector')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('skin.option.remote_extra')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('skin.option.remote_extra')), findsOneWidget);
    },
  );
}
