import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Default API base for Android emulator -> localhost of host machine
String apiBaseUrl = 'http://10.0.2.2:9002';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    // Allow overriding the API base URL from an environment variable
    apiBaseUrl = dotenv.env['WEB_API_BASE_URL'] ?? apiBaseUrl;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    // If dotenv or Firebase fail, still run the app using defaults
    runApp(const MyApp());
  }
}

// ------------------------- Additional Screens -------------------------

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userProfiles')
            .orderBy('totalScore', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Player';
              final score = data['totalScore'] ?? 0;
              final level = data['highestLevel'] ?? 1;
              final rank = index + 1;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    username.toString().substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text('$rank. $username'),
                subtitle: Text('Level $level'),
                trailing: Text(score.toString()),
              );
            },
          );
        },
      ),
    );
  }
}

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  final List<Map<String, dynamic>> themes = const [
    {
      'id': 'dark',
      'name': 'Default Dark',
      'description': 'The standard dark theme.',
    },
    {
      'id': 'light',
      'name': 'Default Light',
      'description': 'The standard light theme.',
    },
    {
      'id': 'noir',
      'name': 'Film Noir',
      'description': 'A classic black and white detective look.',
      'isPurchasable': true,
    },
    {
      'id': 'cyberpunk',
      'name': 'Cyberpunk',
      'description': 'A neon-lit futuristic theme.',
      'isPurchasable': true,
    },
  ];

  final List<Map<String, dynamic>> hintPacks = const [
    {
      'id': 'small_hints',
      'name': '5 Hint Pack',
      'amount': 5,
      'description': 'A few hints to get you unstuck.',
    },
    {
      'id': 'large_hints',
      'name': '25 Hint Pack',
      'amount': 25,
      'description': 'Enough hints for the toughest cases.',
    },
  ];

  Future<void> _purchaseHints(BuildContext context, int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('userProfiles')
        .doc(user.uid);
    await ref.set({
      'hints': FieldValue.increment(amount),
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Received $amount hints')));
  }

  Future<void> _purchaseTheme(BuildContext context, String themeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('userProfiles')
        .doc(user.uid);
    await ref.set({
      'purchasedThemes': FieldValue.arrayUnion([themeId]),
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Applied theme $themeId')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cosmetic Themes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...themes.map(
                (t) => Card(
                  child: ListTile(
                    title: Text(t['name']),
                    subtitle: Text(t['description']),
                    trailing: ElevatedButton(
                      onPressed: () => _purchaseTheme(context, t['id']),
                      child: const Text('Apply'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hint Packs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...hintPacks.map(
                (p) => Card(
                  child: ListTile(
                    title: Text(p['name']),
                    subtitle: Text(p['description']),
                    trailing: ElevatedButton(
                      onPressed: () => _purchaseHints(context, p['amount']),
                      child: const Text('Purchase'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('userProfiles')
        .doc(user.uid);
    await ref.set({'username': _controller.text}, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('userProfiles')
        .doc(user.uid)
        .delete();
    await user.delete();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();
    final docRef = FirebaseFirestore.instance
        .collection('userProfiles')
        .doc(user.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          _controller.text = data['username'] ?? user.email ?? 'Player';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(_controller.text.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveUsername,
                  child: const Text('Save'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete Account'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController(
    text: 'alex.doe@example.com',
  );
  final TextEditingController _password = TextEditingController(
    text: 'password',
  );
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: Text(_loading ? 'Signing in...' : 'Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _name = TextEditingController(text: 'Alex Doe');
  final TextEditingController _email = TextEditingController(
    text: 'alex.doe@example.com',
  );
  final TextEditingController _password = TextEditingController(
    text: 'password',
  );
  bool _loading = false;

  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .set({
              'username': _name.text,
              'email': _email.text,
              'totalScore': 0,
              'highestLevel': 1,
              'rank': 'Novice',
              'hints': 0,
            });
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: Text(_loading ? 'Creating account...' : 'Create Account'),
            ),
          ],
        ),
      ),
    );
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
            color: Theme.of(
              context,
            ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
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
              _NavLink(label: 'Leaderboard', onTap: onLeaderboardTap),
              const SizedBox(width: 24),
              _NavLink(label: 'Store', onTap: onStoreTap),
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
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GameScreen()));
  }

  void _showLeaderboard() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Leaderboard coming soon!')));
  }

  void _showStore() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Store coming soon!')));
  }

  void _showProfile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile coming soon!')));
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Guess the word from its definition!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Stats Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Stats',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
    // Play feedback sound based on guess correctness
    final lower = letter.toLowerCase();
    if (currentWord.contains(lower)) {
      _playSound('correct');
    } else {
      _playSound('incorrect');
    }
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
      Future.microtask(() => _playSound('win'));
    } else if (guessedLetters.length >= 6) {
      setState(() {
        gameOver = true;
        won = false;
      });
    }
  }

  Future<void> _playSound(String key) async {
    if (isSoundMuted) return;
    try {
      final uri = Uri.parse('\$apiBaseUrl/api/sound');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sound': key}),
      );
      if (res.statusCode != 200) return;
      final Map<String, dynamic> body = jsonDecode(res.body);
      final String? dataUri = body['soundDataUri'];
      if (dataUri == null) return;
      // dataUri is like: data:audio/wav;base64,AAAA...
      final parts = dataUri.split(',');
      if (parts.length != 2) return;
      final rawBase64 = parts[1];
      final bytes = base64Decode(rawBase64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$key.wav');
      await file.writeAsBytes(bytes, flush: true);
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      // ignore errors silently for now
      // print('playSound error: '
      //     '\$e');
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
        .map(
          (letter) =>
              guessedLetters.contains(letter.toLowerCase()) ? letter : '_',
        )
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
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Definition',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          definition,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
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
                            style: Theme.of(context).textTheme.headlineSmall
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
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
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
                              .map(
                                (letter) => _buildLetterButton(context, letter),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        if (guessedLetters
                            .where((l) => !currentWord.contains(l))
                            .isNotEmpty)
                          Text(
                            'Incorrect: ${guessedLetters.where((l) => !currentWord.contains(l)).join(', ').toUpperCase()}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Colors.red),
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
          disabledBackgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : null,
          disabledForegroundColor: isGuessed ? Colors.white : null,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
