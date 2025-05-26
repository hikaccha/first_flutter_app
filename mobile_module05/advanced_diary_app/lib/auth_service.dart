import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
    );
  }

  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? 'No email',
      displayName: firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User',
      photoURL: firebaseUser.photoURL,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}

class AuthService {
  static const String _userKey = 'current_user';
  static const String _authProviderKey = 'auth_provider';

  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;
  bool _isInitialized = false;
  StreamSubscription? _firebaseAuthSubscription;

  // Firebase Auth instances
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ["email", "profile"],
    signInOption: SignInOption.standard,
    serverClientId:
        "661106763380-o10t1083ktopct8cmceehiaaigpfnluc.apps.googleusercontent.com",
  );

  // GitHub OAuth設定
  final String _githubClientId = 'Ov23liDLYPY18Btsh1ls';

  Stream<User?> get authStateChanges => _authStateController.stream;
  User? get currentUser => _currentUser;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Firebase Auth の状態変化を監視
    _firebaseAuthSubscription = _firebaseAuth
        .authStateChanges()
        .listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _currentUser = User.fromFirebaseUser(firebaseUser);
        _saveUserToPrefs(_currentUser!);
      } else {
        _currentUser = null;
        _clearUserFromPrefs();
      }
      _authStateController.add(_currentUser);
    });

    // 現在の認証状態をチェック
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      _currentUser = User.fromFirebaseUser(firebaseUser);
      _authStateController.add(_currentUser);
    } else {
      _authStateController.add(null);
    }

    _isInitialized = true;
  }

  Future<User?> signInWithGoogle() async {
    await _initialize();

    try {
      print('Google Sign-In: Starting sign in process...');

      await _saveAuthProvider('google');

      // Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In: User cancelled sign in');
        return null;
      }

      print(
          'Google Sign-In: Successfully signed in with Google account: ${googleUser.email}');

      // 認証トークンを取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google Sign-In: Invalid tokens received');
        return null;
      }

      // Firebase用の資格情報を作成
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseに認証情報を登録
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('Google Sign-In: Firebase user is null after sign in');
        return null;
      }

      print(
          'Google Sign-In: Successfully signed in with Firebase: ${firebaseUser.uid}');
      return _currentUser;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> signInWithGitHub(BuildContext context) async {
    await _initialize();

    try {
      print('GitHub Sign-In: Starting sign in process...');

      await _saveAuthProvider('github');

      // Firebase GitHub Auth Provider を使用
      final githubProvider = firebase_auth.GithubAuthProvider();
      githubProvider.addScope('user:email');

      print('GitHub Sign-In: Attempting Firebase sign-in with provider...');

      final result = await _firebaseAuth.signInWithProvider(githubProvider);

      if (result.user != null) {
        print('GitHub Sign-In: Successfully signed in with Firebase');
        print(
            'GitHub Sign-In: User: ${result.user!.email} (${result.user!.uid})');
        return _currentUser;
      } else {
        print('GitHub Sign-In: Firebase auth returned null user');
        return null;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('GitHub Sign-In: Firebase auth exception: ${e.code}');
      print('GitHub Sign-In: Error message: ${e.message}');

      if (context.mounted) {
        _showAuthErrorDialog(context, 'GitHub認証エラー', e.message ?? '認証に失敗しました。');
      }
      return null;
    } catch (e) {
      print('GitHub Sign-In: Unexpected error: $e');

      if (context.mounted) {
        _showAuthErrorDialog(context, 'GitHub認証エラー', '予期しないエラーが発生しました。');
      }
      return null;
    }
  }

  void _showAuthErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAuthProvider(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authProviderKey, provider);
      print('Auth provider saved: $provider');
    } catch (e) {
      print('Error saving auth provider: $e');
    }
  }

  Future<String?> _getAuthProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authProviderKey);
    } catch (e) {
      print('Error getting auth provider: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print('Sign out: Starting sign out process...');

      final authProvider = await _getAuthProvider();
      print('Sign out: Previous auth provider: $authProvider');

      // Firebase Authからサインアウト
      await _firebaseAuth.signOut();
      print('Sign out: Firebase Auth sign out completed');

      // Google Sign-Inからサインアウト（Googleの場合）
      if (authProvider == 'google') {
        try {
          await _googleSignIn.signOut();
          print('Sign out: Google Sign-In sign out completed');
        } catch (e) {
          print('Sign out: Error signing out from Google: $e');
        }
      }

      // 保存されたデータをクリア
      await _clearUserFromPrefs();

      print('Sign out: Successfully signed out');
    } catch (e) {
      print('Sign out: Error during sign out: $e');
      // エラーが発生してもデータはクリア
      try {
        await _clearUserFromPrefs();
      } catch (clearError) {
        print('Sign out: Error clearing user data: $clearError');
      }
    }
  }

  Future<User?> getCurrentUser() async {
    await _initialize();
    return _currentUser;
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController.close();
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user to SharedPreferences: $e');
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authProviderKey);
    } catch (e) {
      print('Error clearing user from SharedPreferences: $e');
    }
  }
}
