import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import '../widgets/game_widgets.dart';

// Game word data (simplified - replace with actual data source as needed)
class WordData {
  final String word;
  final String definition;
  final String difficulty;

  WordData({
    required this.word,
    required this.definition,
    required this.difficulty,
  });
}

// Sample words for demo (in production, use your actual game-data source)
final sampleWords = [
  WordData(
    word: 'PERPLEXING',
    definition: 'Confusing or difficult to understand; puzzling',
    difficulty: 'hard',
  ),
  WordData(
    word: 'ELOQUENT',
    definition: 'Fluent, persuasive, and expressive in speaking or writing',
    difficulty: 'medium',
  ),
  WordData(
    word: 'EPHEMERAL',
    definition: 'Lasting for a very short time; transitory',
    difficulty: 'hard',
  ),
  WordData(
    word: 'SERENE',
    definition: 'Calm, peaceful, and untroubled',
    difficulty: 'easy',
  ),
  WordData(
    word: 'METICULOUS',
    definition: 'Showing great attention to detail; very careful and precise',
    difficulty: 'hard',
  ),
];

const int MAX_INCORRECT_TRIES = 6;

class GameScreen extends StatefulWidget {
  final String apiBaseUrl;

  const GameScreen({
    super.key,
    required this.apiBaseUrl,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late AudioPlayer _audioPlayer;
  late WordData currentWord;
  late List<WordLetter> displayedWord;

  Set<String> guessedLetters = {};
  Set<String> correctLetters = {};
  Set<String> hintedLetters = {};
  String currentDefinition = '';
  String? currentHint;
  int score = 0;
  int level = 1;
  int hints = 0;
  bool gameOver = false;
  bool gameWon = false;
  bool isLoadingHint = false;
  Map<String, String?> sounds = {};

  final user = FirebaseAuth.instance.currentUser;
  late DocumentReference userProfileRef;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (user != null) {
      userProfileRef = FirebaseFirestore.instance.collection('userProfiles').doc(user!.uid);
    }
    _loadUserProfile();
    _loadSounds();
    _initializeGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // For demo, just pick a random word; in production use actual game-data logic
    currentWord = sampleWords[(DateTime.now().millisecondsSinceEpoch % sampleWords.length)];
    currentDefinition = currentWord.definition;
    guessedLetters.clear();
    correctLetters.clear();
    hintedLetters.clear();
    currentHint = null;
    gameOver = false;
    gameWon = false;
    _updateDisplayedWord();
    setState(() {});
  }

  void _updateDisplayedWord() {
    displayedWord = currentWord.word.split('').map((char) {
      final lowerChar = char.toLowerCase();
      final isRevealed = correctLetters.contains(lowerChar) || hintedLetters.contains(lowerChar);
      return WordLetter(char: char, revealed: isRevealed);
    }).toList();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;
    try {
      final doc = await userProfileRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          score = data['totalScore'] ?? 0;
          level = data['highestLevel'] ?? 1;
          hints = data['hints'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadSounds() async {
    final soundKeys = ['correct', 'incorrect', 'win'];
    final newSounds = <String, String?>{};

    for (final key in soundKeys) {
      try {
        // Try API first
        final res = await http
            .post(
              Uri.parse('${widget.apiBaseUrl}/api/sound'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'sound': key}),
            )
            .timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          newSounds[key] = json['soundDataUri'] as String?;
        }
      } catch (e) {
        debugPrint('Error loading sound $key: $e');
        newSounds[key] = null;
      }
    }

    setState(() => sounds = newSounds);
  }

  Future<void> _playSound(String soundKey) async {
    final soundUri = sounds[soundKey];
    if (soundUri == null) return;

    try {
      // If it's a data URI, decode and save to temp file
      if (soundUri.startsWith('data:audio')) {
        final base64Data = soundUri.split(',').last;
        final bytes = base64Decode(base64Data);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$soundKey.wav');
        await tempFile.writeAsBytes(bytes);
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
      } else {
        // Play from URL or asset
        await _audioPlayer.play(AssetSource(soundUri));
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _guessLetter(String letter) {
    if (gameOver || gameWon || guessedLetters.contains(letter)) return;

    final isCorrect = currentWord.word.toLowerCase().contains(letter);

    setState(() {
      guessedLetters.add(letter);
      if (isCorrect) {
        correctLetters.add(letter);
        _playSound('correct');
      } else {
        _playSound('incorrect');
      }
      _updateDisplayedWord();
      _checkGameState();
    });
  }

  void _checkGameState() {
    // Check win
    final allLettersRevealed = displayedWord.every((l) => l.revealed);
    if (allLettersRevealed) {
      gameWon = true;
      _playSound('win');
      _updateFirestoreUser(10 + (level * 5), level + 1);

      // Auto-advance after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            level++;
            _initializeGame();
          });
        }
      });
      return;
    }

    // Check loss
    final incorrectCount = guessedLetters.where((l) => !currentWord.word.toLowerCase().contains(l)).length;
    if (incorrectCount >= MAX_INCORRECT_TRIES) {
      gameOver = true;
    }
  }

  Future<void> _requestHint() async {
    if (isLoadingHint || (user != null && hints <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hints available. Watch an ad or buy more.')),
      );
      return;
    }

    setState(() => isLoadingHint = true);

    try {
      // Deduct hint from profile
      if (user != null && hints > 0) {
        await userProfileRef.set({'hints': FieldValue.increment(-1)}, SetOptions(merge: true));
      }

      // Request hint from API
      final res = await http
          .post(
            Uri.parse('${widget.apiBaseUrl}/api/hint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'word': currentWord.word,
              'incorrectGuesses': guessedLetters.where((l) => !currentWord.word.toLowerCase().contains(l)).toList(),
              'lettersToReveal': hintedLetters.length + 2,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final hint = json['hint'] as String?;
        if (hint != null) {
          setState(() {
            currentHint = hint;
            final newLetters = hint.split('').where((c) => c != '_').map((c) => c.toLowerCase()).toSet();
            hintedLetters.addAll(newLetters);
            _updateDisplayedWord();
          });
        }
      } else {
        // Refund hint on error
        if (user != null) {
          await userProfileRef.set({'hints': FieldValue.increment(1)}, SetOptions(merge: true));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get hint. Try again.')),
        );
      }
    } catch (e) {
      debugPrint('Error requesting hint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoadingHint = false);
    }
  }

  void _watchAdForHint() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdProgressDialog(
        onComplete: () async {
          // Increment hints
          if (user != null) {
            await userProfileRef.set({'hints': FieldValue.increment(1)}, SetOptions(merge: true));
            setState(() => hints++);
          }
          // Auto-use the hint
          await _requestHint();
        },
      ),
    );
  }

  Future<void> _updateFirestoreUser(int scoreGained, int newLevel) async {
    if (user == null) return;
    try {
      await userProfileRef.set(
        {
          'totalScore': FieldValue.increment(scoreGained),
          'highestLevel': newLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      setState(() {
        score += scoreGained;
        level = newLevel;
      });
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final incorrectCount = guessedLetters.where((l) => !currentWord.word.toLowerCase().contains(l)).length;
    final incorrectLetters = guessedLetters.where((l) => !currentWord.word.toLowerCase().contains(l)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Definition Detective'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            // Score badges
            ScoreBadge(score: score, hints: hints, level: level),

            // Definition card
            GameCard(
              title: 'Definition',
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                currentDefinition,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),

            // Word display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: WordDisplay(displayedWord: displayedWord),
            ),

            // Hint display
            if (currentHint != null)
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Hint: $currentHint',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

            // Incorrect guesses
            if (incorrectLetters.isNotEmpty)
              Text(
                'Incorrect (${incorrectCount}/${MAX_INCORRECT_TRIES}): ${incorrectLetters.join(', ').toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),

            // Game state: result or playing
            if (gameWon || gameOver)
              ResultDialog(
                isWon: gameWon,
                word: currentWord.word,
                scoreText: gameWon ? 'Score +${10 + (level * 5)}' : '',
                onRetry: () {
                  setState(_initializeGame);
                  Navigator.of(context).pop();
                },
                onHome: () => Navigator.of(context).pop(),
              )
            else
              Column(
                spacing: 12,
                children: [
                  // Hint buttons
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lightbulb),
                          label: const Text('Get Hint'),
                          onPressed: isLoadingHint ? null : _requestHint,
                        ),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_circle),
                          label: const Text('Watch Ad'),
                          onPressed: gameOver ? null : _watchAdForHint,
                        ),
                      ),
                    ],
                  ),

                  // Keyboard
                  KeyboardWidget(
                    onKeyTap: _guessLetter,
                    guessedLetters: guessedLetters,
                    correctLetters: correctLetters,
                    hintedLetters: hintedLetters,
                  ),
                ],
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
