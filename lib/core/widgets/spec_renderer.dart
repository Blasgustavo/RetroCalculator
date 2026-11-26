import 'package:flutter/material.dart';

import '../design_system/skin_tokens.dart';
import 'calculator_keyboard.dart';
import 'seven_segment_display.dart';

/// Tipos de nodo permitidos por el esquema v2 (`design/app.design.json`).
///
/// Espejo de `tool/design/adapters/fluttercanvas_to_design.dart`. Cualquier
/// tipo fuera de esta whitelist se rechaza: el renderer nunca interpreta
/// código incrustado en el spec.
const Set<String> specNodeTypes = <String>{
  'padding',
  'display',
  'errorText',
  'row',
  'column',
  'sizedBox',
  'keyboard',
  'key',
  'image',
  'history',
  'skinSelector',
  'angleChip',
};

/// Fallo accionable cuando un spec contiene un tipo o condición no soportada.
class SpecRenderException implements Exception {
  const SpecRenderException(this.message);

  final String message;

  @override
  String toString() => 'SpecRenderException: $message';
}

/// Constructor del panel de historial que la feature inyecta en el renderer.
typedef SpecHistoryBuilder =
    Widget Function(BuildContext context, String? titleKey);

/// Constructor del selector de skins que la feature inyecta en el renderer.
typedef SpecSelectorBuilder = Widget Function(BuildContext context);

/// Datos inyectados por la app para resolver nodos de dominio sin acoplamiento
/// inverso: `core` no importa `features` y los nodos no ejecutan código.
@immutable
class SpecRenderContext {
  const SpecRenderContext({
    this.tokens = SkinTokens.classicAmber,
    this.keyboardHeight,
    this.displayText = '0',
    this.errorLabel,
    this.rows = const <List<String>>[],
    this.labels = const <String, String>{},
    this.onKeyTap,
    this.isScientific = false,
    this.angleSelected = false,
    this.onAngleToggle,
    this.title = '',
    this.strings = const <String, String>{},
    this.historyBuilder,
    this.selectorBuilder,
  });

  final SkinTokens tokens;

  /// Altura heredada del teclado (`SkinTokens.keyboardHeight`). Cuando se
  /// inyecta, sustituye al `height` del `sizedBox` que contiene un `keyboard`
  /// para conservar el layout del MVP mientras la skin sigue siendo la fuente
  /// de las medidas táctiles. Sin valor, se usa la altura del spec.
  final double? keyboardHeight;
  final String displayText;
  final String? errorLabel;
  final List<List<String>> rows;
  final Map<String, String> labels;
  final ValueChanged<String>? onKeyTap;
  final bool isScientific;
  final bool angleSelected;
  final ValueChanged<bool>? onAngleToggle;
  final String title;
  final Map<String, String> strings;
  final SpecHistoryBuilder? historyBuilder;
  final SpecSelectorBuilder? selectorBuilder;
}

/// Renderiza una lista de nodos del spec v2 con la whitelist cerrada.
class SpecRenderer extends StatelessWidget {
  const SpecRenderer({
    super.key,
    required this.nodes,
    required this.renderContext,
  });

  final List<Object?> nodes;
  final SpecRenderContext renderContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Object? node in nodes) _buildNode(context, node),
      ],
    );
  }

  Widget _buildNode(BuildContext context, Object? raw) {
    final Map<String, Object?> node = _asNode(raw);
    if (!_matchesCondition(node)) {
      return const SizedBox.shrink();
    }

    final String type = _text(node, 'type');
    if (!specNodeTypes.contains(type)) {
      throw SpecRenderException(
        'Tipo de nodo "$type" no soportado. Tipos permitidos: '
        '${specNodeTypes.join(', ')}.',
      );
    }

    final SpecRenderContext data = renderContext;
    switch (type) {
      case 'padding':
        return Padding(
          padding: EdgeInsets.all(_number(node, 'value') ?? 0),
          child: _buildChild(context, node),
        );
      case 'display':
        return SevenSegmentDisplay(
          key: Key(_text(node, 'key', 'calc.display')),
          text: data.displayText,
          tokens: data.tokens,
        );
      case 'errorText':
        final String? error = data.errorLabel;
        if (error == null || error.isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(error, style: const TextStyle(color: Colors.redAccent));
      case 'row':
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: data.tokens.screenPadding),
          child: Row(
            mainAxisAlignment: _alignment(node),
            children: _buildChildren(context, node),
          ),
        );
      case 'column':
        return Column(
          mainAxisAlignment: _alignment(node),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildChildren(context, node),
        );
      case 'sizedBox':
        final Object? child = node['child'];
        final bool wrapsKeyboard =
            child is Map<String, Object?> && child['type'] == 'keyboard';
        return SizedBox(
          height: wrapsKeyboard
              ? (data.keyboardHeight ?? _number(node, 'height'))
              : _number(node, 'height'),
          child: _buildChild(context, node),
        );
      case 'keyboard':
        return CalculatorKeyboard(
          key: Key(_text(node, 'key', 'calc.keyboard')),
          rows: data.rows,
          labels: data.labels,
          onKeyTap: data.onKeyTap ?? (String _) {},
          tokens: data.tokens,
        );
      case 'key':
        return _buildKey(node, data);
      case 'image':
        return _buildImage(node, data);
      case 'history':
        final String? titleKey = node['titleKey'] as String?;
        final SpecHistoryBuilder? builder = data.historyBuilder;
        return builder == null
            ? ListTile(title: Text(titleKey ?? ''))
            : builder(context, titleKey);
      case 'skinSelector':
        final SpecSelectorBuilder? builder = data.selectorBuilder;
        return builder == null
            ? const ListTile(title: Text('skinSelector'))
            : builder(context);
      case 'angleChip':
        return _buildAngleChip(node, data);
      default:
        throw SpecRenderException('Tipo de nodo "$type" no soportado.');
    }
  }

  Widget _buildKey(Map<String, Object?> node, SpecRenderContext data) {
    final String value = _text(node, 'value', _text(node, 'key'));
    return ElevatedButton(
      key: Key(_text(node, 'key', 'calc.key')),
      onPressed: data.onKeyTap == null ? null : () => data.onKeyTap!(value),
      child: FittedBox(child: Text(data.labels[value] ?? value)),
    );
  }

  Widget _buildImage(Map<String, Object?> node, SpecRenderContext data) {
    return SizedBox(
      key: Key(_text(node, 'key', 'spec.image')),
      height: 48,
      child: Center(
        child: Icon(Icons.image, size: 32, color: data.tokens.displayBorder),
      ),
    );
  }

  Widget _buildAngleChip(Map<String, Object?> node, SpecRenderContext data) {
    final bool selected = data.angleSelected;
    final String textKey = selected ? 'angleRad' : 'angleDeg';
    return ChoiceChip(
      key: Key(_text(node, 'key', 'calc.toggle.angle')),
      label: Text(data.strings[textKey] ?? textKey),
      selected: selected,
      onSelected: data.onAngleToggle == null
          ? null
          : (_) => data.onAngleToggle!(!selected),
    );
  }

  Widget _buildChild(BuildContext context, Map<String, Object?> node) {
    final Object? child = node['child'];
    return child == null ? const SizedBox.shrink() : _buildNode(context, child);
  }

  List<Widget> _buildChildren(BuildContext context, Map<String, Object?> node) {
    final Object? children = node['children'];
    if (children is! Iterable<Object?>) {
      return <Widget>[];
    }
    return <Widget>[
      for (final Object? child in children) _buildNode(context, child),
    ];
  }

  bool _matchesCondition(Map<String, Object?> node) {
    final Object? raw = node['when'];
    if (raw == null) {
      return true;
    }
    final String when = raw is String ? raw : '';
    return switch (when) {
      'always' || '' => true,
      'hasError' =>
        renderContext.errorLabel != null &&
            renderContext.errorLabel!.isNotEmpty,
      'isScientific' => renderContext.isScientific,
      _ => throw SpecRenderException(
        'Condición "when" no soportada: "$when". '
        'Solo se resuelven hasError e isScientific desde el contexto.',
      ),
    };
  }

  Map<String, Object?> _asNode(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    throw SpecRenderException(
      'Cada nodo del spec debe ser un Map<String, Object?>; recibido $raw.',
    );
  }

  String _text(Map<String, Object?> node, String key, [String fallback = '']) {
    final Object? value = node[key];
    return value is String ? value : fallback;
  }

  double? _number(Map<String, Object?> node, String key) {
    final Object? value = node[key];
    return value is num ? value.toDouble() : null;
  }

  MainAxisAlignment _alignment(Map<String, Object?> node) {
    final String value = _text(node, 'alignment', 'start');
    return switch (value) {
      'start' => MainAxisAlignment.start,
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => throw SpecRenderException(
        'Alineación "$value" no soportada en un nodo row/column.',
      ),
    };
  }
}
