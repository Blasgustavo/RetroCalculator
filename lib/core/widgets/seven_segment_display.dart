import 'package:flutter/material.dart';

import '../design_system/skin_tokens.dart';

class SevenSegmentDisplay extends StatelessWidget {
  const SevenSegmentDisplay({
    super.key,
    required this.text,
    this.tokens = SkinTokens.classicAmber,
  });

  final String text;
  final SkinTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: tokens.displayPadding,
      decoration: BoxDecoration(
        color: tokens.displayBackground,
        borderRadius: BorderRadius.circular(tokens.displayRadius),
        border: Border.all(color: tokens.displayBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: CustomPaint(
          painter: _SevenSegmentPainter(
            text: text,
            digitWidth: tokens.digitWidth,
            digitHeight: tokens.digitHeight,
            color: tokens.segmentOn,
          ),
          size: Size(
            tokens.digitWidth * (text.isEmpty ? 1 : text.length),
            tokens.digitHeight,
          ),
        ),
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  const _SevenSegmentPainter({
    required this.text,
    required this.digitWidth,
    required this.digitHeight,
    required this.color,
  });

  static const Map<String, int> _patterns = <String, int>{
    '0': 0x3F,
    '1': 0x06,
    '2': 0x5B,
    '3': 0x4F,
    '4': 0x66,
    '5': 0x6D,
    '6': 0x7D,
    '7': 0x07,
    '8': 0x7F,
    '9': 0x6F,
    '-': 0x40,
  };

  final String text;
  final double digitWidth;
  final double digitHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint active = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint inactive = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double pad = 4;
    final double innerWidth = digitWidth - pad * 2;
    final double innerHeight = digitHeight - pad * 2;
    final String value = text.isEmpty ? '0' : text;

    for (int index = 0; index < value.length; index++) {
      final String char = value[index];
      final double left = index * digitWidth + pad;
      final double top = pad;
      final double middle = top + innerHeight / 2;
      final double bottom = top + innerHeight;
      final double right = left + innerWidth;

      if (char == '.') {
        canvas.drawCircle(Offset(left + 1, bottom), 2.5, active);
        continue;
      }

      final List<Offset> startPoints = <Offset>[
        Offset(left, top),
        Offset(right, top),
        Offset(right, middle),
        Offset(left, bottom),
        Offset(left, middle),
        Offset(left, top),
        Offset(left, middle),
      ];
      final List<Offset> endPoints = <Offset>[
        Offset(right, top),
        Offset(right, middle),
        Offset(right, bottom),
        Offset(right, bottom),
        Offset(left, middle),
        Offset(left, middle),
        Offset(right, middle),
      ];
      final int pattern = _patterns[char] ?? 0;
      for (int segment = 0; segment < 7; segment++) {
        final bool isOn = (pattern & (1 << segment)) != 0;
        canvas.drawLine(
          startPoints[segment],
          endPoints[segment],
          isOn ? active : inactive,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.color != color;
  }
}
