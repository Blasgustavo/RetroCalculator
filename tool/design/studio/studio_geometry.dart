// Geometría editable del canvas del RetroDesign Studio (T23, plan V4).
//
// `DesignNode` es inmutable y `SpecRenderer` es un render puro que consume solo
// JSON. La posición y el tamaño que edita el Studio son estado del editor:
// viven aquí, fuera del documento y fuera del renderer. Así el spec emitido al
// compilador no cambia (compatibilidad de artefactos) y ningún nodo guarda
// estado propio.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show Size;

import '../schema.dart' show DesignSeed, seedMinTouchTarget;

/// Altura mínima de cualquier nodo, en particular de una tecla: espejo de
/// `keyMinHeight` (48 dp, `token_validation.minTouchTarget`). Innegociable.
const double studioMinNodeHeight = seedMinTouchTarget;

/// Ancho mínimo sensible y no negativo para cualquier nodo.
const double studioMinNodeWidth = seedMinTouchTarget;

const double studioDefaultNodeWidth = 120;
const double studioDefaultNodeHeight = studioMinNodeHeight;
const double studioDefaultSnapGrid = 8;

/// Frame lógico del breakpoint: el ancho respeta el mínimo declarado en
/// `dimensions.breakpoints` (mobile sin mínimo usa 360) y la altura es una
/// referencia estable para acotar el arrastre dentro del canvas.
Size studioFrameSize(DesignSeed document, String breakpoint) {
  final int minWidth = document.dimensions.breakpoints[breakpoint] ?? 0;
  final double width = math.max(
    studioDefaultNodeWidth * 3,
    minWidth.toDouble(),
  );
  final double height = switch (breakpoint) {
    'tablet' => 900,
    'desktop' => 768,
    _ => 640,
  };
  return Size(width, height);
}

/// Las ocho manillas de resize de un nodo seleccionado.
enum StudioResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

/// Rectángulo de un nodo en las coordenadas del frame del breakpoint.
@immutable
class StudioGeometry {
  const StudioGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  StudioGeometry copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return StudioGeometry(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Formato de la capa de geometría del Studio (no del spec de la app).
  Map<String, Object?> toJson() => <String, Object?>{
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  @override
  bool operator ==(Object other) =>
      other is StudioGeometry &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'StudioGeometry(x: $x, y: $y, w: $width, h: $height)';
}
