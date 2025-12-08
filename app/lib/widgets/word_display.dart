import 'package:flutter/material.dart';

/// Word display widget showing letter tiles
class WordDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> displayedWord;

  const WordDisplay({
    Key? key,
    required this.displayedWord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: displayedWord.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final char = item['char'] as String;
        final revealed = item['revealed'] as bool;

        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.blue,
                width: 4,
              ),
            ),
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: AnimatedOpacity(
              opacity: revealed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                revealed ? char.toUpperCase() : '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
