import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'core/design_system/design_system.dart';
import 'core/i18n/locale_resolver.dart';
import 'features/calculator/data/local/history_store.dart';
import 'features/calculator/data/local/local_counters.dart';
import 'features/calculator/data/local/shared_preferences_history_store.dart';
import 'features/calculator/presentation/viewmodels/calculator_view_model.dart';
import 'features/skins/data/skin_repository.dart';
import 'features/skins/presentation/skin_controller.dart';
import 'features/skins/presentation/skin_scope.dart';
import 'platform/preferences/shared_preferences_key_value_store.dart';

class RetroCalculatorApp extends StatelessWidget {
  const RetroCalculatorApp({
    super.key,
    HistoryStore? historyStore,
    LocalCounters? counters,
  }) : _historyStore = historyStore, // ignore: prefer_initializing_formals
       _counters = counters; // ignore: prefer_initializing_formals

  final HistoryStore? _historyStore;
  final LocalCounters? _counters;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HistoryStore>(
          create: (_) =>
              _historyStore ??
              SharedPreferencesHistoryStore(
                SharedPreferencesKeyValueStore.create(),
              ),
        ),
        Provider<LocalCounters>(create: (_) => _counters ?? LocalCounters()),
        ChangeNotifierProvider<CalculatorViewModel>(
          create: (BuildContext context) => CalculatorViewModel(
            context.read<HistoryStore>(),
            context.read<LocalCounters>(),
          ),
        ),
        Provider<SkinRepository>(create: (_) => const SkinRepository()),
        ChangeNotifierProvider<SkinController>(create: (_) => SkinController()),
      ],
      child: Builder(
        builder: (BuildContext context) => SkinScope(
          controller: context.read<SkinController>(),
          child: MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appName,
            debugShowCheckedModeBanner: false,
            locale: LocaleResolver.initial(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: DSTheme.toMaterialTheme(Brightness.light),
            darkTheme: DSTheme.toMaterialTheme(Brightness.dark),
            themeMode: ThemeMode.system,
            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
