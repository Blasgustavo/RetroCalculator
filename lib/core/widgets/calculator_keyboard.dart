import 'package:flutter/material.dart';

import '../design_system/skin_tokens.dart';

class CalculatorKeyboard extends StatelessWidget {
  const CalculatorKeyboard({
    super.key,
    required this.rows,
    required this.labels,
    required this.onKeyTap,
    this.tokens = SkinTokens.classicAmber,
  });

  final List<List<String>> rows;
  final Map<String, String> labels;
  final ValueChanged<String> onKeyTap;
  final SkinTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final List<String> row in rows)
          Expanded(
            child: Row(
              children: <Widget>[
                for (final String key in row)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.keyPadding),
                      child: ElevatedButton(
                        key: Key('calc.key.$key'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, tokens.keyMinHeight),
                          backgroundColor: tokens.keyBackground,
                          foregroundColor: tokens.keyForeground,
                          side: tokens.keyBorder == null
                              ? null
                              : BorderSide(color: tokens.keyBorder!),
                          shape: tokens.keyRadius == null
                              ? null
                              : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    tokens.keyRadius!,
                                  ),
                                ),
                        ),
                        onPressed: () => onKeyTap(key),
                        child: FittedBox(child: Text(labels[key] ?? key)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
