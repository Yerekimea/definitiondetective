import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

const String apiBaseUrl = 'http://10.0.2.2:9002';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0f0f0f),
      ),
      home: const HomeScreen(),
    );
  }
}

// Custom Header Widget matching web design
class CustomHeader extends StatelessWidget {
  final VoidCallback? onLeaderboardTap;
  final VoidCallback? onStoreTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSoundToggleTap;
  final bool isSoundMuted;

  const CustomHeader({
    super.key,
    this.onLeaderboardTap,
    this.onStoreTap,
    this.onProfileTap,
    this.onSoundToggleTap,
    this.isSoundMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
          ),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo and title
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Definition Detective',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Navigation links
          Row(
            children: [
              _NavLink(
                label: 'Leaderboard',
                onTap: onLeaderboardTap,
              ),
              const SizedBox(width: 24),
              _NavLink(
                label: 'Store',
                onTap: onStoreTap,
              ),
            ],
          ),
          // Sound toggle and profile menu
          const SizedBox(width: 24),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isSoundMuted ? Icons.volume_off : Icons.volume_up,
                  size: 20,
                ),
                onPressed: onSoundToggleTap,
                tooltip: isSoundMuted ? 'Unmute' : 'Mute',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 8),
              _ProfileMenu(onProfileTap: onProfileTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _NavLink({required this.label, this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isHovered
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const _ProfileMenu({this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.account_circle,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
      onSelected: (value) {
        if (value == 'profile') {
          onProfileTap?.call();
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 18),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 12),
              Text('Logout'),
            ],
          ),
        ),
      ],
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
  bool isSoundMuted = false;

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  void _showLeaderboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leaderboard coming soon!')),
    );
  }

  void _showStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store coming soon!')),
    );
  }

  void _showProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile coming soon!')),
    );
  }

  void _toggleSound() {
    setState(() {
      isSoundMuted = !isSoundMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomHeader(
            onLeaderboardTap: _showLeaderboard,
            onStoreTap: _showStore,
            onProfileTap: _showProfile,
            onSoundToggleTap: _toggleSound,
            isSoundMuted: isSoundMuted,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Guess the word from its definition!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha((0.7 * 255).toInt()),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Stats Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withAlpha((0.2 * 255).toInt()),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Stats',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatRow(context, 'Score:', '$score'),
                          const SizedBox(height: 12),
                          _buildStatRow(context, 'Level:', '$level'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startGame,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Game'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
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
  bool isSoundMuted = false;

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

  void _toggleSound() {
    setState(() {
      isSoundMuted = !isSoundMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayWord = currentWord
        .split('')
        .map((letter) =>
            guessedLetters.contains(letter.toLowerCase()) ? letter : '_')
        .join(' ');

    return Scaffold(
      body: Column(
        children: [
          CustomHeader(
            onSoundToggleTap: _toggleSound,
            isSoundMuted: isSoundMuted,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Definition Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withAlpha((0.2 * 255).toInt()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Definition',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          definition,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha((0.8 * 255).toInt()),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Word Display
                  Text(
                    displayWord,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  if (gameOver)
                    // Game Over Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: won ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            won ? 'You Won!' : 'Game Over',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: won ? Colors.green : Colors.red,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The word was: ${currentWord.toUpperCase()}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(_initializeGame);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                                child: const Text('Play Again'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Back Home'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // Guessing Interface
                    Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: 'abcdefghijklmnopqrstuvwxyz'
                              .split('')
                              .map((letter) => _buildLetterButton(context, letter))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        if (guessedLetters
                            .where((l) => !currentWord.contains(l))
                            .isNotEmpty)
                          Text(
                            'Incorrect: ${guessedLetters.where((l) => !currentWord.contains(l)).join(', ').toUpperCase()}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red,
                                ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterButton(BuildContext context, String letter) {
    final isGuessed = guessedLetters.contains(letter);
    final isCorrect = currentWord.contains(letter);

    return SizedBox(
      width: 40,
      height: 40,
      child: ElevatedButton(
        onPressed: isGuessed || gameOver ? null : () => _guessLetter(letter),
        style: ElevatedButton.styleFrom(
          backgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isGuessed
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          disabledBackgroundColor:
              isGuessed ? (isCorrect ? Colors.green : Colors.red) : null,
          disabledForegroundColor: isGuessed ? Colors.white : null,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
