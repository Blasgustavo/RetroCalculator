// Estado en memoria del RetroDesign Studio (T21, plan V4).
//
// `StudioController` es el único dueño del documento abierto: la paleta, el
// canvas, el panel de capas y el inspector leen de aquí y escuchan sus
// cambios. No conoce widgets ni red: los slices siguientes (drag & drop,
// capas reordenables, inspector, undo/redo y persistencia) se añaden como
// métodos nuevos sobre este mismo estado, sin romper este contrato.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../artifacts.dart' show designNodeToJson;
import '../schema.dart';

/// Ruta relativa al directorio de trabajo (la raíz del proyecto cuando se
/// lanza con `flutter run -t tool/design/studio/main.dart`).
const String studioDefaultDesignPath = 'design/app.design.json';

/// Carga el documento inicial desde [path].
DesignSeed loadStudioDocument([String path = studioDefaultDesignPath]) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError('No existe el documento de diseño: $path');
  }
  return DesignSeed.fromJson(jsonDecode(file.readAsStringSync()));
}

/// Resuelve un nodo por su ruta en el árbol: índices en `children`
/// (`'0.2'` = hijo 2 del nodo 0) y el token `c` para el `child` único
/// (`'0.c'` = child del nodo 0). Devuelve `null` si la ruta no existe.
DesignNode? studioNodeAtPath(List<DesignNode> roots, String path) {
  if (path.isEmpty) return null;
  final List<String> tokens = path.split('.');
  DesignNode? current;
  List<DesignNode>? level = roots;
  for (final String token in tokens) {
    DesignNode? next;
    if (token == 'c') {
      next = current?.child;
    } else {
      final int index = int.tryParse(token) ?? -1;
      if (level == null || index < 0 || index >= level.length) return null;
      next = level[index];
    }
    if (next == null) return null;
    current = next;
    level = next.children;
  }
  return current;
}

class StudioController extends ChangeNotifier {
  StudioController({
    required DesignSeed document,
    String? screen,
    String? breakpoint,
  }) : _document = document,
       _screen = screen != null && document.screens.containsKey(screen)
           ? screen
           : _firstScreen(document),
       _breakpoint =
           breakpoint != null && designBreakpoints.contains(breakpoint)
           ? breakpoint
           : designBreakpoints.first;

  DesignSeed _document;
  String _screen;
  String _breakpoint;
  String _selectedNodePath = '';

  static String _firstScreen(DesignSeed document) =>
      document.screens.isEmpty ? '' : document.screens.keys.first;

  DesignSeed get document => _document;

  /// Pantallas del documento, en orden del JSON.
  List<String> get screens => _document.screens.keys.toList();

  String get screen => _screen;

  /// Breakpoints soportados por el esquema (`mobile`, `tablet`, `desktop`).
  List<String> get breakpoints => designBreakpoints.toList();

  String get breakpoint => _breakpoint;

  /// Tipos de la paleta, en el orden de `designNodeTypes`.
  List<String> get paletteTypes => designNodeTypes.toList();

  /// Nodos del documento para la pantalla y el breakpoint seleccionados.
  List<DesignNode> get currentNodes =>
      _document.screens[_screen]?[_breakpoint] ?? const <DesignNode>[];

  /// Los mismos nodos en la forma JSON que consume `SpecRenderer`.
  List<Object?> get currentSpec => <Object?>[
    for (final DesignNode node in currentNodes) designNodeToJson(node),
  ];

  /// Ruta del nodo seleccionado en las capas; vacío = nada seleccionado.
  String get selectedNodePath => _selectedNodePath;

  DesignNode? get selectedNode =>
      studioNodeAtPath(currentNodes, _selectedNodePath);

  void selectScreen(String value) {
    if (value == _screen || !_document.screens.containsKey(value)) return;
    _screen = value;
    _selectedNodePath = '';
    notifyListeners();
  }

  void selectBreakpoint(String value) {
    if (value == _breakpoint || !designBreakpoints.contains(value)) return;
    _breakpoint = value;
    _selectedNodePath = '';
    notifyListeners();
  }

  void selectNode(String path) {
    if (path == _selectedNodePath) return;
    if (studioNodeAtPath(currentNodes, path) == null) return;
    _selectedNodePath = path;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedNodePath.isEmpty) return;
    _selectedNodePath = '';
    notifyListeners();
  }

  /// Sustituye el documento abierto y vuelve a la selección inicial.
  void loadDocument(DesignSeed document) {
    _document = document;
    _screen = _firstScreen(document);
    _breakpoint = designBreakpoints.first;
    _selectedNodePath = '';
    notifyListeners();
  }
}
