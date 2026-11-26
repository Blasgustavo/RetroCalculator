// Estado en memoria del RetroDesign Studio (T21, plan V4).
//
// `StudioController` es el único dueño del documento abierto: la paleta, el
// canvas, el panel de capas y el inspector leen de aquí y escuchan sus
// cambios. No conoce widgets ni red: los slices siguientes (capas
// reordenables, inspector, undo/redo y persistencia) se añaden como métodos
// nuevos sobre este mismo estado, sin romper este contrato.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;

import '../artifacts.dart' show designNodeToJson;
import '../schema.dart';
import 'studio_geometry.dart';

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

  // Geometría del editor, separada del documento: pantalla → breakpoint →
  // ruta del nodo → rectángulo. Cambiar de breakpoint conserva la posición.
  final Map<String, Map<String, Map<String, StudioGeometry>>> _geometry =
      <String, Map<String, Map<String, StudioGeometry>>>{};
  bool _snappingEnabled = false;
  double _snapGrid = studioDefaultSnapGrid;

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

  /// Rectángulo del nodo seleccionado, o `null` si no hay selección.
  StudioGeometry? get selectedGeometry =>
      _selectedNodePath.isEmpty ? null : geometryOf(_selectedNodePath);

  /// El snapping es una ayuda opcional del editor: desactivado conserva la
  /// precisión de coma flotante de las coordenadas introducidas.
  bool get snappingEnabled => _snappingEnabled;

  double get snapGrid => _snapGrid;

  void setSnapping(bool enabled) {
    if (enabled == _snappingEnabled) return;
    _snappingEnabled = enabled;
    notifyListeners();
  }

  void setSnapGrid(double value) {
    final double grid = value.isFinite && value >= 1
        ? value
        : studioDefaultSnapGrid;
    if (grid == _snapGrid) return;
    _snapGrid = grid;
    notifyListeners();
  }

  /// Frame del breakpoint activo, según las dimensiones del documento.
  Size get frame => studioFrameSize(_document, _breakpoint);

  /// Rectángulo de un nodo del breakpoint activo. Los nodos que vienen del
  /// documento (no creados con la paleta) reciben una geometría inicial
  /// determinista sin mutar el `DesignNode`.
  StudioGeometry? geometryOf(String path) {
    if (path.isEmpty || studioNodeAtPath(currentNodes, path) == null) {
      return null;
    }
    final StudioGeometry? stored = _geometryMap()[path];
    return stored ?? _clampGeometry(_defaultGeometry(path), frame);
  }

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

  /// Añade un nodo de [type] al final del breakpoint actual, lo selecciona
  /// (para que aparezca en capas e inspector) y devuelve su ruta.
  ///
  /// Deny-by-default: si [type] no pertenece a `designNodeTypes` o la
  /// pantalla/breakpoint actual no existe en el documento, no se muta nada y
  /// se devuelve `null`.
  String? addNode(String type) {
    if (!designNodeTypes.contains(type)) return null;
    final Map<String, List<DesignNode>>? breakpoints =
        _document.screens[_screen];
    if (breakpoints == null) return null;
    final List<DesignNode> nodes = breakpoints[_breakpoint] ??= <DesignNode>[];
    final String path = '${nodes.length}';
    nodes.add(DesignNode(type: type));
    // El nodo nuevo entra ya dentro del frame del breakpoint.
    _geometryMap()[path] = _clampGeometry(_defaultGeometry(path), frame);
    _selectedNodePath = path;
    notifyListeners();
    return path;
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

  // ---------------------------------------------------------------------------
  // T23 — mover, redimensionar y serializar geometría
  // ---------------------------------------------------------------------------

  /// Sustituye el rectángulo de un nodo, siempre dentro del frame y con
  /// `width`/`height` >= 48 dp. Es el único punto de escritura de geometría:
  /// mover y redimensionar pasan por aquí, igual que la serialización.
  void setNodeGeometry(String path, StudioGeometry geometry) {
    if (studioNodeAtPath(currentNodes, path) == null) return;
    _geometryMap()[path] = _clampGeometry(geometry, frame);
    notifyListeners();
  }

  /// Coloca un nodo en una posición absoluta del frame (con snapping opcional).
  void setNodePosition(String path, {required double x, required double y}) {
    final StudioGeometry? geometry = geometryOf(path);
    if (geometry == null) return;
    setNodeGeometry(path, geometry.copyWith(x: _snap(x), y: _snap(y)));
  }

  /// Mueve un nodo por el delta del gesto; actualiza sus coordenadas x/y.
  void moveNode(String path, {required double dx, required double dy}) {
    final StudioGeometry? geometry = geometryOf(path);
    if (geometry == null) return;
    setNodePosition(path, x: geometry.x + dx, y: geometry.y + dy);
  }

  /// Redimensiona un nodo desde una de sus ocho manillas.
  ///
  /// El borde opuesto queda fijo, se aplica el mínimo de 48 dp al borde que se
  /// mueve (invariante de `keyMinHeight`) y el resultado se acota al frame.
  void resizeNode(
    String path,
    StudioResizeHandle handle, {
    double dx = 0,
    double dy = 0,
  }) {
    final StudioGeometry? geometry = geometryOf(path);
    if (geometry == null) return;

    final bool moveLeft =
        handle == StudioResizeHandle.topLeft ||
        handle == StudioResizeHandle.left ||
        handle == StudioResizeHandle.bottomLeft;
    final bool moveRight =
        handle == StudioResizeHandle.topRight ||
        handle == StudioResizeHandle.right ||
        handle == StudioResizeHandle.bottomRight;
    final bool moveTop =
        handle == StudioResizeHandle.topLeft ||
        handle == StudioResizeHandle.top ||
        handle == StudioResizeHandle.topRight;
    final bool moveBottom =
        handle == StudioResizeHandle.bottomLeft ||
        handle == StudioResizeHandle.bottom ||
        handle == StudioResizeHandle.bottomRight;

    double left = geometry.x;
    double top = geometry.y;
    double right = geometry.x + geometry.width;
    double bottom = geometry.y + geometry.height;
    if (moveLeft) left = _snap(left + dx);
    if (moveRight) right = _snap(right + dx);
    if (moveTop) top = _snap(top + dy);
    if (moveBottom) bottom = _snap(bottom + dy);

    if (right - left < studioMinNodeWidth) {
      if (moveLeft && !moveRight) {
        left = right - studioMinNodeWidth;
      } else if (moveRight && !moveLeft) {
        right = left + studioMinNodeWidth;
      } else {
        left = 0;
        right = studioMinNodeWidth;
      }
    }
    if (bottom - top < studioMinNodeHeight) {
      if (moveTop && !moveBottom) {
        top = bottom - studioMinNodeHeight;
      } else if (moveBottom && !moveTop) {
        bottom = top + studioMinNodeHeight;
      } else {
        top = 0;
        bottom = studioMinNodeHeight;
      }
    }

    setNodeGeometry(
      path,
      StudioGeometry(
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      ),
    );
  }

  /// Copia serializable de la geometría del breakpoint activo. Se emite por
  /// separado del spec: la app y el compilador siguen consumiendo solo datos
  /// de `designNodeToJson`, sin posiciones ni tamaños del editor.
  Map<String, Object?> serializeLayout() {
    return <String, Object?>{
      'screen': _screen,
      'breakpoint': _breakpoint,
      'snapping': <String, Object?>{
        'enabled': _snappingEnabled,
        'grid': _snapGrid,
      },
      'frame': <String, Object?>{'width': frame.width, 'height': frame.height},
      'nodes': <String, Object?>{
        for (int i = 0; i < currentNodes.length; i++)
          '$i': geometryOf('$i')!.toJson(),
      },
    };
  }

  Map<String, StudioGeometry> _geometryMap() => _geometry
      .putIfAbsent(_screen, () => <String, Map<String, StudioGeometry>>{})
      .putIfAbsent(_breakpoint, () => <String, StudioGeometry>{});

  StudioGeometry _defaultGeometry(String path) {
    final int index = int.tryParse(path.split('.').first) ?? 0;
    return StudioGeometry(
      x: 8 + (index % 4) * 16,
      y: 8 + (index % 8) * 56,
      width: studioDefaultNodeWidth,
      height: studioDefaultNodeHeight,
    );
  }

  StudioGeometry _clampGeometry(StudioGeometry geometry, Size frame) {
    final double width = math.min(
      math.max(
        geometry.width.isFinite ? geometry.width : studioMinNodeWidth,
        studioMinNodeWidth,
      ),
      frame.width,
    );
    final double height = math.min(
      math.max(
        geometry.height.isFinite ? geometry.height : studioMinNodeHeight,
        studioMinNodeHeight,
      ),
      frame.height,
    );
    final double x = math.max(
      0,
      math.min(geometry.x.isFinite ? geometry.x : 0, frame.width - width),
    );
    final double y = math.max(
      0,
      math.min(geometry.y.isFinite ? geometry.y : 0, frame.height - height),
    );
    return StudioGeometry(x: x, y: y, width: width, height: height);
  }

  double _snap(double value) {
    if (!value.isFinite) return 0;
    if (!_snappingEnabled) return value;
    return (value / _snapGrid).round() * _snapGrid;
  }

  /// Sustituye el documento abierto y vuelve a la selección inicial.
  void loadDocument(DesignSeed document) {
    _document = document;
    _screen = _firstScreen(document);
    _breakpoint = designBreakpoints.first;
    _selectedNodePath = '';
    _geometry.clear();
    notifyListeners();
  }
}
