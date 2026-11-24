import 'package:flutter/material.dart';

class LocaleResolver {
  const LocaleResolver._();

  static const List<Locale> supported = <Locale>[
    Locale('es', 'PE'),
    Locale('en'),
    Locale('pt', 'BR'),
  ];

  static Locale initial() => const Locale('es', 'PE');

  static Locale resolve(Locale? candidate) {
    if (candidate == null) {
      return initial();
    }
    for (final Locale locale in supported) {
      if (locale.languageCode == candidate.languageCode &&
          (locale.countryCode == null ||
              locale.countryCode == candidate.countryCode)) {
        return locale;
      }
    }
    return const Locale('en');
  }

  static String name(Locale locale) => locale.toString();
}
