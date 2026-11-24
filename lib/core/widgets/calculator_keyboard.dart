import 'package:flutter/material.dart';

class CalculatorKeyboard extends StatelessWidget {
  const CalculatorKeyboard({
    super.key,
    required this.rows,
    required this.labels,
    required this.onKeyTap,
  });

  final List<List<String>> rows;
  final Map<String, String> labels;
  final ValueChanged<String> onKeyTap;

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
                      padding: const EdgeInsets.all(3),
                      child: ElevatedButton(
                        key: Key('calc.key.$key'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 44),
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
