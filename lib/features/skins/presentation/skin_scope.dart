import 'package:flutter/material.dart';

import '../../../core/design_system/skin_tokens.dart';
import '../domain/skin.dart';
import 'skin_controller.dart';

class SkinScope extends StatelessWidget {
  const SkinScope({super.key, required this.controller, required this.child});

  final SkinController controller;
  final Widget child;

  static SkinTokens tokensOf(BuildContext context) {
    final _SkinScopeInherited? scope = context
        .dependOnInheritedWidgetOfExactType<_SkinScopeInherited>();
    return scope?.skin.tokens ?? SkinTokens.classicAmber;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) =>
          _SkinScopeInherited(skin: controller.selected, child: child!),
      child: child,
    );
  }
}

class _SkinScopeInherited extends InheritedWidget {
  const _SkinScopeInherited({required this.skin, required super.child});

  final Skin skin;

  @override
  bool updateShouldNotify(_SkinScopeInherited oldWidget) =>
      oldWidget.skin != skin;
}
