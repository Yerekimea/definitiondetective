import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter engine bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  String debugInfo = '';

  try {
    // Load environment variables from .env file
    // In main.dart, temporarily change this line:
await dotenv.load(fileName: "/workspaces/definitiondetective/app/.env");
    //await dotenv.load(fileName: ".env");
    debugInfo += '✅ .env file loaded\n';
    
    // Check if API key exists
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      debugInfo += '❌ GEMINI_API_KEY is NULL\n';
    } else if (apiKey.isEmpty) {
      debugInfo += '❌ GEMINI_API_KEY is EMPTY\n';
    } else {
      debugInfo += '✅ GEMINI_API_KEY loaded: ${apiKey.substring(0, 5)}...\n';
    }

    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugInfo += '✅ Firebase initialized successfully\n';

    runApp(MyApp(debugInfo: debugInfo));
    
  } catch (e, stackTrace) {
    debugInfo += '❌ ERROR in main(): $e\n';
    runApp(MyApp(debugInfo: debugInfo));
  }
}

class MyApp extends StatelessWidget {
  final String debugInfo;
  
  const MyApp({super.key, required this.debugInfo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Definition Detective',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(debugInfo: debugInfo),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String debugInfo;
  
  const HomeScreen({super.key, required this.debugInfo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? geminiKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    // Retrieve your secret key from .env
    final key = dotenv.env['GEMINI_API_KEY'];
    
    setState(() {
      geminiKey = key;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definition Detective - DEBUG'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Icon(
              _isLoading ? Icons.hourglass_empty : 
                 geminiKey == null ? Icons.error_outline : Icons.check_circle,
              color: _isLoading ? Colors.blue : 
                     geminiKey == null ? Colors.orange : Colors.green,
              size: 64,
            ),
            
            SizedBox(height: 20),
            
            // Status Text
            Text(
              _isLoading ? 'Loading...' : 
                 geminiKey == null ? 'Configuration Issue' : 'Ready!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isLoading ? Colors.blue : 
                       geminiKey == null ? Colors.orange : Colors.green,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Debug Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Debug Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    _buildInfoRow('App Status:', _isLoading ? 'Loading' : 'Ready'),
                    _buildInfoRow('API Key Status:', geminiKey == null ? 'MISSING' : 'PRESENT'),
                    SizedBox(height: 10),
                    Text(
                      'Startup Log:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.debugInfo,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Help Text if API Key is Missing
            if (!_isLoading && geminiKey == null)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Configuration Issue Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'The .env file was found but GEMINI_API_KEY is missing or empty.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Please check:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text('1. .env file exists in project root'),
                      Text('2. Contains: GEMINI_API_KEY=your_key'),
                      Text('3. No quotes or spaces around the value'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: value == 'MISSING' ? Colors.red : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}