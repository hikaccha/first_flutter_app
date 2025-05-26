import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Data
import 'data/services/firestore_service.dart';
import 'data/repositories/diary_repository_impl.dart';

// Domain
import 'domain/repositories/diary_repository.dart';

// Presentation
import 'presentation/providers/diary_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/main_tab_page.dart';

// Services
import 'data/services/auth_service.dart';

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

  runApp(const AdvancedDiaryApp());
}

class AdvancedDiaryApp extends StatelessWidget {
  const AdvancedDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // Repositories
        ProxyProvider<FirestoreService, DiaryRepository>(
          update: (_, firestoreService, __) =>
              DiaryRepositoryImpl(firestoreService),
        ),

        // Providers
        ChangeNotifierProxyProvider<DiaryRepository, DiaryProvider>(
          create: (context) => DiaryProvider(
            Provider.of<DiaryRepository>(context, listen: false),
          ),
          update: (_, repository, previous) =>
              previous ?? DiaryProvider(repository),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppNavigator(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/main': (context) => MainTabPage(),
        },
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  final AuthService _authService = AuthService();
  bool _initializing = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _setupAuthListener();
  }

  @override
  void dispose() {
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
    _authService.authStateChanges.listen((user) {
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
    if (_initializing) {
      return const SplashPage();
    }

    if (_isLoggedIn) {
      return MainTabPage();
    } else {
      return const LoginPage();
    }
  }
}
