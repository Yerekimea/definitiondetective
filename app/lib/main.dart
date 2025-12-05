import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String API_BASE_URL = 'http://10.0.2.2:9002';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Definition Detective',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int score = 0;
  int level = 1;
  List<String> guessedLetters = [];

  void _startGame() {
    setState(() {
      guessedLetters = [];
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definition Detective'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Definition Detective',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Guess the word from its definition!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Stats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Score:', '$score'),
                      _buildStatRow('Level:', '$level'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Game'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leaderboard coming soon!')),
                  );
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text('View Leaderboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> words = ['example', 'flutter', 'definition', 'detective'];
  late String currentWord;
  late String definition;
  List<String> guessedLetters = [];
  bool gameOver = false;
  bool won = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    currentWord = (words..shuffle()).first;
    definition = 'A word puzzle game where you guess letters.'; // Placeholder
    guessedLetters = [];
    gameOver = false;
    won = false;
  }

  void _guessLetter(String letter) {
    if (guessedLetters.contains(letter) || gameOver) return;

    setState(() {
      guessedLetters.add(letter);
      _checkWin();
    });
  }

  void _checkWin() {
    final allLettersGuessed = currentWord
        .split('')
        .every((letter) => guessedLetters.contains(letter.toLowerCase()));
    if (allLettersGuessed) {
      setState(() {
        gameOver = true;
        won = true;
      });
    } else if (guessedLetters.length >= 6) {
      setState(() {
        gameOver = true;
        won = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayWord = currentWord
        .split('')
        .map((letter) => guessedLetters.contains(letter.toLowerCase()) ? letter : '_')
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Definition',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      definition,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              displayWord,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            if (gameOver)
              Card(
                color: won ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        won ? 'You Won!' : 'Game Over',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: won ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        won ? 'The word was: $currentWord' : 'The word was: $currentWord',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(_initializeGame);
                        },
                        child: const Text('Play Again'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back Home'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: 'abcdefghijklmnopqrstuvwxyz'
                        .split('')
                        .map((letter) => _buildLetterButton(letter))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Incorrect: ${guessedLetters.where((l) => !currentWord.contains(l)).join(', ')}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterButton(String letter) {
    final isGuessed = guessedLetters.contains(letter);
    final isCorrect = currentWord.contains(letter);

    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        onPressed: isGuessed || gameOver ? null : () => _guessLetter(letter),
        style: ElevatedButton.styleFrom(
          backgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : Colors.grey[300],
          disabledBackgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : Colors.grey[300],
          padding: EdgeInsets.zero,
        ),
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            color: isGuessed ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
