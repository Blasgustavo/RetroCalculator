import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded<void>(() => runApp(const RetroCalculatorApp()), (
    Object error,
    StackTrace stack,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
}
