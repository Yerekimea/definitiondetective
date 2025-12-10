import 'package:flutter/material.dart';

/// GameCard: A styled card for displaying game content (definition, word, etc.)
class GameCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;

  const GameCard({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// WordDisplay: Shows the word with revealed and hidden letters
class WordDisplay extends StatelessWidget {
  final List<WordLetter> displayedWord;
  final int? wordLength;

  const WordDisplay({super.key, required this.displayedWord, this.wordLength});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: displayedWord
          .asMap()
          .entries
          .map(
            (entry) => _WordLetterBox(
              char: entry.value.char,
              revealed: entry.value.revealed,
              index: entry.key,
            ),
          )
          .toList(),
    );
  }
}

class WordLetter {
  final String char;
  final bool revealed;

  WordLetter({required this.char, required this.revealed});
}

class _WordLetterBox extends StatelessWidget {
  final String char;
  final bool revealed;
  final int index;

  const _WordLetterBox({
    required this.char,
    required this.revealed,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: revealed ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 48,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
          color: revealed
              ? Theme.of(context).colorScheme.secondaryContainer
              : Colors.transparent,
        ),
        child: revealed
            ? Text(
                char.toUpperCase(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}

/// KeyboardWidget: Game keyboard with letter buttons
class KeyboardWidget extends StatelessWidget {
  final Function(String) onKeyTap;
  final Set<String> guessedLetters;
  final Set<String> correctLetters;
  final Set<String> hintedLetters;

  const KeyboardWidget({
    super.key,
    required this.onKeyTap,
    required this.guessedLetters,
    required this.correctLetters,
    required this.hintedLetters,
  });

  static const keys = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: keys
          .map(
            (row) => Wrap(
              spacing: 4,
              alignment: WrapAlignment.center,
              children: row
                  .map(
                    (letter) => _KeyboardButton(
                      letter: letter,
                      isGuessed: guessedLetters.contains(letter.toLowerCase()),
                      isCorrect: correctLetters.contains(letter.toLowerCase()),
                      isHinted: hintedLetters.contains(letter.toLowerCase()),
                      onPressed: () => onKeyTap(letter.toLowerCase()),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  final String letter;
  final bool isGuessed;
  final bool isCorrect;
  final bool isHinted;
  final VoidCallback onPressed;

  const _KeyboardButton({
    required this.letter,
    required this.isGuessed,
    required this.isCorrect,
    required this.isHinted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? foregroundColor;

    if (isHinted) {
      backgroundColor = Colors.blue.withOpacity(0.6);
      foregroundColor = Colors.white;
    } else if (isGuessed) {
      backgroundColor = isCorrect
          ? Colors.green.withOpacity(0.8)
          : Colors.red.withOpacity(0.8);
      foregroundColor = Colors.white;
    }

    return SizedBox(
      width: 36,
      height: 44,
      child: ElevatedButton(
        onPressed: isGuessed || isHinted ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : null,
          disabledForegroundColor: isGuessed ? Colors.white : null,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          letter,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

/// ResultDialog: Win/Loss result with action buttons
class ResultDialog extends StatelessWidget {
  final bool isWon;
  final String word;
  final String scoreText;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const ResultDialog({
    super.key,
    required this.isWon,
    required this.word,
    required this.scoreText,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isWon ? '🎉 You Won!' : '😢 Game Over',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isWon ? 'You solved the word!' : 'The word was:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            word.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWon ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          if (isWon)
            Text(scoreText, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      actions: [
        if (!isWon) TextButton(onPressed: onRetry, child: const Text('Retry')),
        TextButton(onPressed: onHome, child: const Text('Home')),
      ],
    );
  }
}

/// ScoreBadge: Displays score, hints, and level
class ScoreBadge extends StatelessWidget {
  final int score;
  final int hints;
  final int level;

  const ScoreBadge({
    super.key,
    required this.score,
    required this.hints,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BadgeItem(icon: Icons.stars, label: 'Score', value: score.toString()),
        _BadgeItem(
          icon: Icons.lightbulb,
          label: 'Hints',
          value: hints.toString(),
        ),
        _BadgeItem(
          icon: Icons.trending_up,
          label: 'Level',
          value: level.toString(),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// AdProgressDialog: Simulated rewarded ad with progress
class AdProgressDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const AdProgressDialog({super.key, required this.onComplete});

  @override
  State<AdProgressDialog> createState() => _AdProgressDialogState();
}

class _AdProgressDialogState extends State<AdProgressDialog> {
  late int _progress;

  @override
  void initState() {
    super.initState();
    _progress = 0;
    _simulateAd();
  }

  void _simulateAd() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _progress += 10);
        if (_progress < 100) {
          _simulateAd();
        } else {
          Navigator.of(context).pop();
          widget.onComplete();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your hint is sponsored by...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Video Ad Simulation',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress / 100, minHeight: 8),
          const SizedBox(height: 8),
          Text('$_progress%', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
