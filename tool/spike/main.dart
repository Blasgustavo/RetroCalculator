// Ejemplo ejecutable del spike: abre el builder de fluttercanvas dentro del
// Studio de desarrollo. No se usa en la app de producto (ADR-0011).
import 'package:flutter/material.dart';
import 'package:fluttercanvas/fluttercanvas.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FlutterCanvasBuilder(title: 'RetroDesign Studio spike'),
    ),
  );
}
