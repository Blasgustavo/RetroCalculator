// Adaptador temporal del modelo de autoría de fluttercanvas al esquema v2 de
// design/app.design.json. No usa el exportador Dart ni el renderer del paquete.

import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Nodos permitidos en el esquema v2 (docs/plans/2026-11-24-design-studio-v2.md).
const List<String> designNodeWhitelist = <String>[
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
];

/// Fallo accionable cuando un nodo del canvas no puede representarse en el diseño.
class DesignAdapterException implements Exception {
  const DesignAdapterException(this.message);

  final String message;

  @override
  String toString() => 'DesignAdapterException: $message';
}

/// Tipos del catálogo de fluttercanvas que pueden mapearse sin propiedad explícita.
///
/// Los nodos de dominio (`display`, `keyboard`, `key`, `history`,
/// `skinSelector`, `angleChip`, `errorText`) requieren `designType` porque no
/// existen en el catálogo del paquete. Así el adaptador nunca inventa nodos.
const Map<String, String> _implicitTypes = <String, String>{
  WidgetTypes.column: 'column',
  WidgetTypes.row: 'row',
  WidgetTypes.box: 'padding',
  WidgetTypes.container: 'padding',
  WidgetTypes.spacer: 'sizedBox',
  WidgetTypes.image: 'image',
};

const Set<String> _breakpoints = <String>{'mobile', 'tablet', 'desktop'};

/// Convierte un nodo de autoría en un nodo JSON de la whitelist v2.
///
/// Las propiedades puente son `designType`, `designKey`, `when`, `titleKey`,
/// `alignment`, `padding` y `height`. Solo se emiten claves válidas para el
/// tipo destino; cualquier otro tipo se rechaza.
Map<String, Object?> canvasNodeToDesignNode(WidgetNode node) {
  final declared = node.string('designType');
  final type = declared.isNotEmpty ? declared : _implicitTypes[node.type];
  if (type == null) {
    throw DesignAdapterException(
      'El tipo "${node.type}" no tiene mapeo al esquema v2; '
      'define designType o cámbialo en la paleta.',
    );
  }
  if (!designNodeWhitelist.contains(type)) {
    throw DesignAdapterException(
      'El tipo "$type" no está en la whitelist de nodos v2.',
    );
  }

  final result = <String, Object?>{'type': type};
  final key = node.string('designKey');
  final when = node.string('when');
  final titleKey = node.string('titleKey');

  switch (type) {
    case 'padding':
      result['value'] = _jsonNumber(node.number('padding', 12));
      result['child'] = _onlyChild(node, type);
    case 'sizedBox':
      result['height'] = _jsonNumber(node.number('height', 48));
      result['child'] = _onlyChild(node, type);
    case 'row':
    case 'column':
      final alignment = node.string('alignment');
      if (alignment.isNotEmpty) result['alignment'] = alignment;
      if (when.isNotEmpty) result['when'] = when;
      result['children'] = <Object?>[
        for (final child in node.children) canvasNodeToDesignNode(child),
      ];
    case 'display':
    case 'errorText':
    case 'key':
    case 'angleChip':
      _noChildren(node, type);
      if (key.isNotEmpty) result['key'] = key;
      if (when.isNotEmpty) result['when'] = when;
    case 'keyboard':
    case 'image':
      _noChildren(node, type);
      if (key.isNotEmpty) result['key'] = key;
    case 'history':
      _noChildren(node, type);
      if (titleKey.isNotEmpty) result['titleKey'] = titleKey;
      if (when.isNotEmpty) result['when'] = when;
    case 'skinSelector':
      _noChildren(node, type);
      if (when.isNotEmpty) result['when'] = when;
  }
  return result;
}

/// Convierte los hijos de la raíz de una pantalla al layout de un breakpoint.
///
/// El resultado es un fragmento de `screens.<screen>.<breakpoint>`; el fichero
/// completo `design/app.design.json` se crea en V1 y sigue siendo la fuente
/// de verdad. La comparación visual con `SpecRenderer` se traslada a V3.
Map<String, Object?> canvasDocumentToScreenSpec(
  CanvasDocument document, {
  String breakpoint = 'mobile',
}) {
  if (!_breakpoints.contains(breakpoint)) {
    throw DesignAdapterException('Breakpoint desconocido: $breakpoint.');
  }
  return <String, Object?>{
    breakpoint: <Object?>[
      for (final child in document.root.children) canvasNodeToDesignNode(child),
    ],
  };
}

Object _jsonNumber(double value) =>
    value == value.roundToDouble() ? value.toInt() : value;

Map<String, Object?> _onlyChild(WidgetNode node, String type) {
  if (node.children.length != 1) {
    throw DesignAdapterException(
      'El nodo "$type" necesita exactamente un hijo; tiene '
      '${node.children.length}.',
    );
  }
  return canvasNodeToDesignNode(node.children.first);
}

void _noChildren(WidgetNode node, String type) {
  if (node.children.isNotEmpty) {
    throw DesignAdapterException('El nodo "$type" no admite hijos.');
  }
}
