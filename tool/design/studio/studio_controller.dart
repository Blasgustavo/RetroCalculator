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
import 'package:retro_calculator/core/design_system/token_validation.dart'
    show colorKeys, minValues, minTouchTarget, validateTokens;

import '../artifacts.dart' show designNodeToJson;
import '../schema.dart';
import 'studio_formula_validation.dart';
import 'studio_geometry.dart';

/// Ruta relativa al directorio de trabajo (la raíz del proyecto cuando se
/// lanza con `flutter run -t tool/design/studio/main.dart`).
const String studioDefaultDesignPath = 'design/app.design.json';

/// Propiedades del nodo que el inspector puede editar, en el orden de los
/// campos. Lista declarada: no se hardcodea en la UI.
const List<String> studioEditableNodeProperties = <String>[
  'key',
  'titleKey',
  'when',
  'value',
  'height',
  'alignment',
];

const Set<String> studioStringNodeProperties = <String>{
  'key',
  'titleKey',
  'when',
  'alignment',
};

const Set<String> studioNumNodeProperties = <String>{'value', 'height'};

/// Claves de token que el inspector puede editar (deny-by-default).
final Set<String> studioEditableTokenKeys = <String>{
  ...colorKeys,
  ...minValues.keys,
};

/// Valor tipado de una propiedad editable del nodo, o `null` si no existe o no
/// es editable. El inspector genera sus campos a partir de esta misma lista.
Object? studioNodePropertyValue(DesignNode node, String property) {
  if (!studioEditableNodeProperties.contains(property)) return null;
  return switch (property) {
    'key' => node.key,
    'titleKey' => node.titleKey,
    'when' => node.when,
    'value' => node.value,
    'height' => node.height,
    'alignment' => node.alignment,
    _ => null,
  };
}

/// Texto inicial de un campo de propiedad del nodo.
String? studioNodePropertyText(DesignNode node, String property) =>
    studioNodePropertyValue(node, property)?.toString();

/// Error en vivo de un campo numérico del inspector. Las reglas de `height`
/// reutilizan `minTouchTarget`; el controller aplica el mismo mínimo.
String? studioNodePropertyError(String property, String text) {
  if (!studioNumNodeProperties.contains(property)) return null;
  if (text.trim().isEmpty) return null;
  final num? value = num.tryParse(text.trim());
  if (value == null || !value.isFinite) return 'Debe ser un número';
  if (property == 'height' && value < minTouchTarget) {
    return 'La altura mínima es 48 dp';
  }
  return null;
}

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
           : designBreakpoints.first,
       _selectedSkinId = document.skins.isEmpty
           ? null
           : document.skins.first.id,
       _selectedProfileId = document.profiles.isEmpty
           ? null
           : document.profiles.first.id;

  DesignSeed _document;
  String _screen;
  String _breakpoint;
  String _selectedNodePath = '';
  String? _selectedSkinId;
  String? _selectedProfileId;

  // Geometría del editor, separada del documento: pantalla → breakpoint →
  // ruta del nodo → rectángulo. Cambiar de breakpoint conserva la posición.
  final Map<String, Map<String, Map<String, StudioGeometry>>> _geometry =
      <String, Map<String, Map<String, StudioGeometry>>>{};

  // T24 — estado de edición de capas, también separado del documento (ADR-0015):
  // pantalla → breakpoint → conjunto de rutas. Solo las rutas presentes son
  // `true`; ausencia = valor por defecto (`false`).
  final Map<String, Map<String, Set<String>>> _hidden =
      <String, Map<String, Set<String>>>{};
  final Map<String, Map<String, Set<String>>> _locked =
      <String, Map<String, Set<String>>>{};
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
  // T24 — capas: visibilidad, bloqueo y reordenación
  // ---------------------------------------------------------------------------

  /// Visibilidad de edición de un nodo. `false` por defecto, también en rutas
  /// inválidas: ocultar nunca elimina el nodo del spec (ADR-0015).
  bool isNodeHidden(String path) => _hiddenSet().contains(path);

  /// Bloqueo propio de un nodo, sin contar el de sus ancestros.
  bool isNodeLocked(String path) => _lockedSet().contains(path);

  void setNodeHidden(String path, bool value) {
    if (studioNodeAtPath(currentNodes, path) == null) return;
    if (isNodeEffectivelyLocked(path)) return;
    final Set<String> hidden = _hiddenSet();
    if (value == hidden.contains(path)) return;
    if (value) {
      hidden.add(path);
    } else {
      hidden.remove(path);
    }
    notifyListeners();
  }

  void setNodeLocked(String path, bool value) {
    if (studioNodeAtPath(currentNodes, path) == null) return;
    final Set<String> locked = _lockedSet();
    if (value == locked.contains(path)) return;
    if (value) {
      locked.add(path);
    } else {
      locked.remove(path);
    }
    notifyListeners();
  }

  /// `true` si el nodo o cualquiera de sus ancestros está bloqueado.
  bool isNodeEffectivelyLocked(String path) {
    if (path.isEmpty) return false;
    if (isNodeLocked(path)) return true;
    final List<String> tokens = path.split('.');
    String prefix = '';
    for (int i = 0; i < tokens.length - 1; i++) {
      prefix = prefix.isEmpty ? tokens[i] : '$prefix.${tokens[i]}';
      if (isNodeLocked(prefix)) return true;
    }
    return false;
  }

  /// ¿Se puede intercambiar el nodo con el hermano anterior (`up`) o siguiente?
  bool canMoveLayer(String path, {required bool up}) {
    if (studioNodeAtPath(currentNodes, path) == null) return false;
    if (isNodeEffectivelyLocked(path)) return false;
    final List<DesignNode>? siblings = _siblingList(path);
    if (siblings == null) return false;
    final int index = int.tryParse(_splitPath(path)!.token) ?? -1;
    if (index < 0) return false;
    return up ? index > 0 : index < siblings.length - 1;
  }

  /// Reordena el nodo dentro de su lista (raíz o `children`). El `child`
  /// único no tiene hermanos. Mueve también geometría, flags y selección para
  /// que sigan apuntando al mismo nodo después del cambio de ruta.
  void moveLayer(String path, {required bool up}) {
    if (!canMoveLayer(path, up: up)) return;
    final List<DesignNode> siblings = _siblingList(path)!;
    final int index = int.tryParse(_splitPath(path)!.token)!;
    final int target = index + (up ? -1 : 1);
    final String otherPath = _replaceLastToken(path, '$target');

    // Materializa la geometría derivada de la ruta antes de mover: así un
    // nodo sin rectángulo guardado no cambia de posición al reordenarse.
    for (final String candidate in _allNodePaths()) {
      if (_isUnder(candidate, path) || _isUnder(candidate, otherPath)) {
        _geometryMap()[candidate] = geometryOf(candidate)!;
      }
    }

    final DesignNode node = siblings[index];
    siblings[index] = siblings[target];
    siblings[target] = node;

    // Tras el intercambio, cada nodo toma la ruta que ocupaba el otro.
    final String newPath = otherPath;
    final String otherNewPath = path;
    _remapLayerState((String candidate) {
      if (_isUnder(candidate, path)) {
        return newPath + candidate.substring(path.length);
      }
      if (_isUnder(candidate, otherPath)) {
        return otherNewPath + candidate.substring(otherPath.length);
      }
      return candidate;
    });
    notifyListeners();
  }

  void _remapLayerState(String Function(String path) remap) {
    final Map<String, StudioGeometry> geometry = _geometryMap();
    final Map<String, StudioGeometry> remappedGeometry =
        <String, StudioGeometry>{
          for (final MapEntry<String, StudioGeometry> entry in geometry.entries)
            remap(entry.key): entry.value,
        };
    geometry
      ..clear()
      ..addAll(remappedGeometry);

    final Set<String> hidden = _hiddenSet();
    final Set<String> remappedHidden = hidden.map(remap).toSet();
    hidden
      ..clear()
      ..addAll(remappedHidden);

    final Set<String> locked = _lockedSet();
    final Set<String> remappedLocked = locked.map(remap).toSet();
    locked
      ..clear()
      ..addAll(remappedLocked);

    if (_selectedNodePath.isNotEmpty) {
      _selectedNodePath = remap(_selectedNodePath);
    }
  }

  ({String parent, String token})? _splitPath(String path) {
    if (path.isEmpty) return null;
    final int dot = path.lastIndexOf('.');
    if (dot < 0) return (parent: '', token: path);
    return (parent: path.substring(0, dot), token: path.substring(dot + 1));
  }

  String _replaceLastToken(String path, String token) {
    final String parent = _splitPath(path)!.parent;
    return parent.isEmpty ? token : '$parent.$token';
  }

  bool _isUnder(String candidate, String root) =>
      candidate == root || candidate.startsWith('$root.');

  /// Lista mutable de hermanos de [path] (raíz o `children` del padre).
  /// Devuelve `null` para el token `c` y para rutas sin lista asociada.
  List<DesignNode>? _siblingList(String path) {
    final ({String parent, String token})? split = _splitPath(path);
    if (split == null || split.token == 'c') return null;
    final int index = int.tryParse(split.token) ?? -1;
    if (index < 0) return null;
    List<DesignNode>? siblings;
    if (split.parent.isEmpty) {
      siblings = _document.screens[_screen]?[_breakpoint];
    } else {
      final DesignNode? parent = studioNodeAtPath(currentNodes, split.parent);
      siblings = parent?.children;
    }
    if (siblings == null || index >= siblings.length) return null;
    return siblings;
  }

  /// Todas las rutas válidas del breakpoint activo, incluidos `child` y
  /// `children` en cualquier profundidad.
  List<String> _allNodePaths() {
    final List<String> paths = <String>[];
    void walk(
      List<DesignNode> nodes,
      String basePath, {
      bool singleChild = false,
    }) {
      for (int i = 0; i < nodes.length; i++) {
        final String path = singleChild
            ? '$basePath.c'
            : basePath.isEmpty
            ? '$i'
            : '$basePath.$i';
        paths.add(path);
        final DesignNode node = nodes[i];
        if (node.child != null) {
          walk(<DesignNode>[node.child!], path, singleChild: true);
        }
        final List<DesignNode>? children = node.children;
        if (children != null) walk(children, path);
      }
    }

    walk(currentNodes, '');
    return paths;
  }

  // ---------------------------------------------------------------------------
  // T25 — inspector: tokens de skin, propiedades del nodo y fórmulas
  //
  // Tokens, propiedades y fórmulas SÍ son documento (ADR-0015): se reescribe
  // el `DesignSeed` inmutable. Geometría, hidden y locked siguen fuera de él.
  // ---------------------------------------------------------------------------

  String? get selectedSkinId => _selectedSkinId;

  void selectSkin(String id) {
    if (id == _selectedSkinId || _skin(id) == null) return;
    _selectedSkinId = id;
    notifyListeners();
  }

  /// Copia de los tokens de [id]; `{}` si la skin no existe. La copia evita
  /// escribir en el documento sin pasar por [setSkinToken].
  Map<String, Object?> skinTokens(String id) {
    final SkinSpec? skin = _skin(id);
    return skin == null
        ? const <String, Object?>{}
        : Map<String, Object?>.from(skin.tokens);
  }

  /// Escribe un token conocido de una skin conocida. Los valores numéricos que
  /// llegan como texto de un `TextField` se normalizan; los inválidos se
  /// conservan para que `validateTokens` pueda mostrar el error en vivo.
  void setSkinToken(String id, String key, Object? value) {
    final int index = _document.skins.indexWhere(
      (SkinSpec skin) => skin.id == id,
    );
    if (index < 0 || !studioEditableTokenKeys.contains(key)) return;
    final SkinSpec skin = _document.skins[index];

    Object? normalized = value;
    if (value is String && minValues.containsKey(key)) {
      final num? parsed = num.tryParse(value.trim().replaceFirst(',', '.'));
      if (parsed != null && parsed.isFinite) normalized = parsed;
    }
    if (skin.tokens[key] == normalized) return;

    final Map<String, Object?> tokens = Map<String, Object?>.from(skin.tokens);
    if (normalized == null) {
      tokens.remove(key);
    } else {
      tokens[key] = normalized;
    }
    final List<SkinSpec> skins = List<SkinSpec>.from(_document.skins);
    skins[index] = SkinSpec(
      id: skin.id,
      nameKey: skin.nameKey,
      isDefault: skin.isDefault,
      tokens: tokens,
      images: skin.images,
    );
    _document = _documentWith(skins: skins);
    notifyListeners();
  }

  /// Reglas reales de `token_validation.dart`, sin duplicarlas aquí.
  List<String> validateSkinTokens(String id) {
    final SkinSpec? skin = _skin(id);
    if (skin == null) return <String>['skin desconocida: $id'];
    return validateTokens(skin.tokens);
  }

  /// Escribe una propiedad editable del nodo seleccionado por [path].
  ///
  /// Deny-by-default: solo las seis propiedades de
  /// [studioEditableNodeProperties], tipos correctos, `height >= 48` y nodos
  /// no bloqueados (incluidos sus ancestros). `null` borra la opcional.
  void setNodeProperty(String path, String property, Object? value) {
    if (!studioEditableNodeProperties.contains(property)) return;
    final DesignNode? node = studioNodeAtPath(currentNodes, path);
    if (node == null || isNodeEffectivelyLocked(path)) return;

    Object? normalized;
    if (value == null) {
      normalized = null;
    } else if (studioStringNodeProperties.contains(property)) {
      if (value is! String) return;
      normalized = value;
    } else if (studioNumNodeProperties.contains(property)) {
      if (value is num) {
        if (!value.isFinite) return;
        normalized = value;
      } else if (value is String) {
        final num? parsed = num.tryParse(value.trim());
        if (parsed == null || !parsed.isFinite) return;
        normalized = parsed;
      } else {
        return;
      }
      if (property == 'height' && (normalized as num) < minTouchTarget) {
        return;
      }
    } else {
      return;
    }
    if (studioNodePropertyValue(node, property) == normalized) return;

    final Map<String, Map<String, List<DesignNode>>> screens =
        Map<String, Map<String, List<DesignNode>>>.from(_document.screens);
    final Map<String, List<DesignNode>> breakpoints =
        Map<String, List<DesignNode>>.from(screens[_screen]!);
    breakpoints[_breakpoint] = _replaceNodeAtPath(
      breakpoints[_breakpoint]!,
      path.split('.'),
      _nodeWithProperty(node, property, normalized),
    );
    screens[_screen] = breakpoints;
    _document = _documentWith(screens: screens);
    notifyListeners();
  }

  String? get selectedProfileId => _selectedProfileId;

  void selectProfile(String id) {
    if (id == _selectedProfileId || _profile(id) == null) return;
    _selectedProfileId = id;
    notifyListeners();
  }

  /// Guarda la fórmula [name] del perfil [profileId] en el documento, aunque
  /// sea inválida: T27 es la barrera de compilación, no este editor.
  void setProfileFormula(String profileId, String name, String expression) {
    final int index = _document.profiles.indexWhere(
      (ProfileSpec profile) => profile.id == profileId,
    );
    if (index < 0) return;
    final ProfileSpec profile = _document.profiles[index];
    if (!profile.formulas.containsKey(name) ||
        profile.formulas[name] == expression) {
      return;
    }
    final Map<String, String> formulas = Map<String, String>.from(
      profile.formulas,
    );
    formulas[name] = expression;
    final List<ProfileSpec> profiles = List<ProfileSpec>.from(
      _document.profiles,
    );
    profiles[index] = ProfileSpec(
      id: profile.id,
      labelKey: profile.labelKey,
      capabilityId: profile.capabilityId,
      isScientific: profile.isScientific,
      defaultAngleMode: profile.defaultAngleMode,
      decimalDigits: profile.decimalDigits,
      inputs: profile.inputs,
      formulas: formulas,
      keyRows: profile.keyRows,
    );
    _document = _documentWith(profiles: profiles);
    notifyListeners();
  }

  /// Validación en vivo: sintaxis, variables, funciones de la capability,
  /// recursión y presupuesto. Nunca ejecuta ni evalúa numéricamente.
  List<String> validateProfileFormula(
    String profileId,
    String name,
    String expression,
  ) {
    final ProfileSpec? profile = _profile(profileId);
    if (profile == null) return <String>['perfil desconocido: $profileId'];
    return validateStudioFormula(
      name: name,
      expression: expression,
      inputs: profile.inputs,
      capabilityId: profile.capabilityId,
      formulaNames: _document.profiles
          .expand((ProfileSpec p) => p.formulas.keys)
          .toSet(),
    );
  }

  SkinSpec? _skin(String id) {
    for (final SkinSpec skin in _document.skins) {
      if (skin.id == id) return skin;
    }
    return null;
  }

  ProfileSpec? _profile(String id) {
    for (final ProfileSpec profile in _document.profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  DesignSeed _documentWith({
    List<SkinSpec>? skins,
    List<ProfileSpec>? profiles,
    Map<String, Map<String, List<DesignNode>>>? screens,
  }) {
    return DesignSeed(
      schemaVersion: _document.schemaVersion,
      version: _document.version,
      channels: _document.channels,
      skins: skins ?? _document.skins,
      images: _document.images,
      screens: screens ?? _document.screens,
      profiles: profiles ?? _document.profiles,
      dimensions: _document.dimensions,
      sounds: _document.sounds,
      monetization: _document.monetization,
      publishing: _document.publishing,
    );
  }

  DesignNode _nodeWithProperty(
    DesignNode node,
    String property,
    Object? value,
  ) {
    return DesignNode(
      type: node.type,
      key: property == 'key' ? value as String? : node.key,
      titleKey: property == 'titleKey' ? value as String? : node.titleKey,
      when: property == 'when' ? value as String? : node.when,
      value: property == 'value' ? value as num? : node.value,
      height: property == 'height' ? value as num? : node.height,
      alignment: property == 'alignment' ? value as String? : node.alignment,
      child: node.child,
      children: node.children,
    );
  }

  /// Reconstruye el camino hasta [path] (índices o `c`) devolviendo nuevos
  /// nodos y listas; el documento original nunca se muta.
  List<DesignNode> _replaceNodeAtPath(
    List<DesignNode> nodes,
    List<String> tokens,
    DesignNode updated,
  ) {
    if (tokens.isEmpty) return nodes;
    final int index = int.tryParse(tokens.first) ?? -1;
    if (index < 0 || index >= nodes.length) return nodes;
    final List<DesignNode> copy = List<DesignNode>.from(nodes);
    copy[index] = tokens.length == 1
        ? updated
        : _replaceNodeIn(copy[index], tokens.sublist(1), updated);
    return copy;
  }

  DesignNode _replaceNodeIn(
    DesignNode node,
    List<String> tokens,
    DesignNode updated,
  ) {
    if (tokens.isEmpty) return updated;
    final String token = tokens.first;
    if (token == 'c') {
      final DesignNode? child = node.child;
      if (child == null) return node;
      return _copyNode(
        node,
        child: tokens.length == 1
            ? updated
            : _replaceNodeIn(child, tokens.sublist(1), updated),
      );
    }
    final int index = int.tryParse(token) ?? -1;
    final List<DesignNode>? children = node.children;
    if (children == null || index < 0 || index >= children.length) {
      return node;
    }
    return _copyNode(
      node,
      children: _replaceNodeAtPath(children, tokens, updated),
    );
  }

  DesignNode _copyNode(
    DesignNode node, {
    DesignNode? child,
    List<DesignNode>? children,
  }) {
    return DesignNode(
      type: node.type,
      key: node.key,
      titleKey: node.titleKey,
      when: node.when,
      value: node.value,
      height: node.height,
      alignment: node.alignment,
      child: child ?? node.child,
      children: children ?? node.children,
    );
  }

  // ---------------------------------------------------------------------------
  // T23 — mover, redimensionar y serializar geometría
  // ---------------------------------------------------------------------------

  /// Sustituye el rectángulo de un nodo, siempre dentro del frame y con
  /// `width`/`height` >= 48 dp. Es el único punto de escritura de geometría:
  /// mover y redimensionar pasan por aquí, igual que la serialización.
  void setNodeGeometry(String path, StudioGeometry geometry) {
    if (studioNodeAtPath(currentNodes, path) == null) return;
    if (isNodeEffectivelyLocked(path)) return;
    _geometryMap()[path] = _clampGeometry(geometry, frame);
    notifyListeners();
  }

  /// Coloca un nodo en una posición absoluta del frame (con snapping opcional).
  void setNodePosition(String path, {required double x, required double y}) {
    if (isNodeEffectivelyLocked(path)) return;
    final StudioGeometry? geometry = geometryOf(path);
    if (geometry == null) return;
    setNodeGeometry(path, geometry.copyWith(x: _snap(x), y: _snap(y)));
  }

  /// Mueve un nodo por el delta del gesto; actualiza sus coordenadas x/y.
  void moveNode(String path, {required double dx, required double dy}) {
    if (isNodeEffectivelyLocked(path)) return;
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
    if (isNodeEffectivelyLocked(path)) return;
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

  Set<String> _hiddenSet() => _hidden
      .putIfAbsent(_screen, () => <String, Set<String>>{})
      .putIfAbsent(_breakpoint, () => <String>{});

  Set<String> _lockedSet() => _locked
      .putIfAbsent(_screen, () => <String, Set<String>>{})
      .putIfAbsent(_breakpoint, () => <String>{});

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
    _selectedSkinId = document.skins.isEmpty ? null : document.skins.first.id;
    _selectedProfileId = document.profiles.isEmpty
        ? null
        : document.profiles.first.id;
    _geometry.clear();
    _hidden.clear();
    _locked.clear();
    notifyListeners();
  }
}
