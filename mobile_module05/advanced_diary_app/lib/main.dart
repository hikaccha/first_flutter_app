import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'auth_service.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AuthService _authService = AuthService();
  bool _initializing = true;
  bool _isLoggedIn = false;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoggedIn = user != null;
        _initializing = false;
      });
    }
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
          _initializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _initializing
          ? const _LoadingScreen()
          : _isLoggedIn
              ? ProfilePage()
              : const StartPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('ログイン'),
        ),
      ),
    );
  }
}
