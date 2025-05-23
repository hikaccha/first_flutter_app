import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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
  static const String _githubTokenKey = 'github_token';
  static const String _authProviderKey = 'auth_provider';

  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;
  bool _isInitialized = false;
  StreamSubscription? _firebaseAuthSubscription;

  // GitHub認証の進行状態を追跡
  bool _isGitHubAuthInProgress = false;
  DateTime? _githubAuthStartTime;
  Timer? _periodicAuthCheckTimer;

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
  final String _githubClientSecret = '4ff1d587b68f3c12fbd57ea732de75ed8b3b457a';

  // Firebase URL を使用（推奨）
  final String _githubRedirectUrl =
      'https://dairy-app-43710.firebaseapp.com/__/auth/handler';

  Stream<User?> get authStateChanges => _authStateController.stream;

  User? get currentUser => _currentUser;

  AuthService() {
    _initialize();
    _startPeriodicAuthCheck();
    _setupAppLifecycleListener();
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

    // 最初の状態チェック
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      _currentUser = User.fromFirebaseUser(firebaseUser);
      _authStateController.add(_currentUser);
    } else {
      // SharedPreferencesからの復元を試みる
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          Map<String, dynamic> userData;
          try {
            userData = Map<String, dynamic>.from(
              Map.castFrom(
                Uri.splitQueryString(userJson)
                    .map((key, value) => MapEntry(key, value)),
              ),
            );
            // 保存されたユーザー情報があっても、認証状態が切れている場合はクリア
            if (_firebaseAuth.currentUser == null) {
              await signOut();
            } else {
              _currentUser = User.fromJson(userData);
              _authStateController.add(_currentUser);
            }
          } catch (e) {
            print('Error parsing user data: $e');
            await signOut();
          }
        } else {
          _authStateController.add(null);
        }
      } catch (e) {
        print('Error initializing auth state: $e');
        _authStateController.add(null);
      }
    }

    _isInitialized = true;
  }

  Future<User?> signInWithGoogle() async {
    await _initialize();

    try {
      print('Google Sign-In: Starting sign in process...');
      print('=== Google Sign-In Configuration ===');
      print('Package Name: com.example.diary_app');
      print(
          'Server Client ID: 661106763380-o10t1083ktopct8cmceehiaaigpfnluc.apps.googleusercontent.com');
      print(
          'Current SHA-1: 24:CF:72:F3:3B:58:E4:52:AF:73:88:19:CD:4D:28:EF:5A:C6:9A:D9');
      print('Firebase Project: dairy-app-43710');

      // Google Play Services の確認
      print('=== Google Play Services Check ===');
      try {
        final isAvailable = await _googleSignIn.isSignedIn();
        print('Google Sign-In service available: true');
        print('Currently signed in: $isAvailable');
      } catch (serviceError) {
        print('Google Play Services issue: $serviceError');
      }

      print(
          'Google Sign-In: Current Firebase user: ${_firebaseAuth.currentUser?.uid}');
      print(
          'Google Sign-In: Current Google user: ${_googleSignIn.currentUser?.email}');

      // Google Sign-Inの現在のユーザーを確認
      GoogleSignInAccount? currentGoogleUser = _googleSignIn.currentUser;

      // 前回のログイン方法を保存
      await _saveAuthProvider('google');

      // 既存のGoogleアカウントがあるか確認
      if (currentGoogleUser == null) {
        // サイレント認証を試行（キャッシュからの復元）
        currentGoogleUser = await _googleSignIn.signInSilently();
        print(
            'Google Sign-In: Silent sign-in result: ${currentGoogleUser?.email}');
      }

      // サイレント認証が失敗した場合、通常のサインインを実行
      if (currentGoogleUser == null) {
        print('Google Sign-In: Performing interactive sign-in...');
        currentGoogleUser = await _googleSignIn.signIn();
      }

      if (currentGoogleUser == null) {
        print('Google Sign-In: User cancelled sign in');
        return null;
      }

      print(
          'Google Sign-In: Successfully signed in with Google account: ${currentGoogleUser.email}');

      // 認証トークンを取得
      final GoogleSignInAuthentication googleAuth =
          await currentGoogleUser.authentication;

      print('Google Sign-In: Got authentication tokens');
      print(
          'Google Sign-In: Access Token exists: ${googleAuth.accessToken != null}');
      print('Google Sign-In: ID Token exists: ${googleAuth.idToken != null}');

      // トークンの妥当性を確認
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google Sign-In: Invalid tokens received');
        // トークンが無効な場合、サインアウトして再試行
        await _googleSignIn.signOut();
        print('Google Sign-In: Signed out and retrying...');

        currentGoogleUser = await _googleSignIn.signIn();
        if (currentGoogleUser == null) {
          print('Google Sign-In: Retry cancelled by user');
          return null;
        }

        final retryAuth = await currentGoogleUser.authentication;
        if (retryAuth.accessToken == null || retryAuth.idToken == null) {
          print('Google Sign-In: Still invalid tokens after retry');
          return null;
        }

        // 再取得したトークンを使用
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: retryAuth.accessToken,
          idToken: retryAuth.idToken,
        );

        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        final firebaseUser = userCredential.user;

        if (firebaseUser == null) {
          print('Google Sign-In: Firebase user is null after retry');
          return null;
        }

        print(
            'Google Sign-In: Successfully signed in with Firebase after retry: ${firebaseUser.uid}');
        return _currentUser;
      }

      // Firebase用の資格情報を作成
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 現在のFirebaseユーザーと同じアカウントかチェック
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null &&
          currentFirebaseUser.email == currentGoogleUser.email) {
        print('Google Sign-In: Already signed in with same account');
        return _currentUser;
      }

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

      // Firebase認証リスナーが自動的に _currentUser をセットします
      return _currentUser;
    } catch (e) {
      print('Google Sign-In Error: $e');
      print('Google Sign-In Error details: ${e.toString()}');

      // ApiException: 10 の詳細分析
      if (e.toString().contains('ApiException: 10')) {
        print('=== ApiException: 10 Analysis ===');
        print('This error typically indicates:');
        print('1. SHA-1 fingerprint not registered in Firebase Console');
        print('2. Wrong serverClientId configuration');
        print('3. Firebase Console Google Sign-In not enabled');
        print('4. App not authorized in Google Cloud Console');

        print(
            'Current SHA-1: 24:CF:72:F3:3B:58:E4:52:AF:73:88:19:CD:4D:28:EF:5A:C6:9A:D9');
        print(
            'Server Client ID: 661106763380-o10t1083ktopct8cmceehiaaigpfnluc.apps.googleusercontent.com');
        print('Package Name: com.example.diary_app');

        // Firebase Console URL を生成
        print(
            'Firebase Console URL: https://console.firebase.google.com/project/dairy-app-43710/settings/general');
        print(
            'Check: Project Settings > General > Android apps > SHA certificate fingerprints');
      }

      // エラーの種類に応じて適切な処理
      if (e.toString().contains('network_error') ||
          e.toString().contains('sign_in_failed')) {
        print('Google Sign-In: Network error detected, clearing cache...');
        try {
          await _googleSignIn.signOut();
        } catch (signOutError) {
          print('Google Sign-In: Error during cleanup: $signOutError');
        }
      }

      return null;
    }
  }

  Future<User?> signInWithGitHub(BuildContext context) async {
    await _initialize();

    try {
      print('=== GitHub Sign-In Debug Info ===');
      print('Platform: Android');
      print('Client ID: $_githubClientId');
      print('Redirect URL: $_githubRedirectUrl');
      print('Note: sessionStorage issues may occur on Android Chrome');
      print(
          'Reference: https://github.com/firebase/firebase-js-sdk/issues/8629');

      // Firebase設定の確認
      print('=== Firebase Configuration Check ===');
      await _checkFirebaseConfig();

      // ブラウザの可用性チェック
      print('=== Browser Availability Check ===');
      await _checkBrowserAvailability();

      // 前回のログイン方法を保存
      await _saveAuthProvider('github');

      // GitHub認証の追跡を開始
      _isGitHubAuthInProgress = true;
      _githubAuthStartTime = DateTime.now();
      print('GitHub authentication tracking started');

      // 前回のトークンをクリア
      await _clearGitHubToken();

      // 状態パラメータを生成（CSRF保護）
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      // GitHub OAuth URL を構築
      final String authUrl = 'https://github.com/login/oauth/authorize'
          '?client_id=$_githubClientId'
          '&redirect_uri=${Uri.encodeComponent(_githubRedirectUrl)}'
          '&scope=user:email'
          '&state=$state';

      print('=== OAuth URL ===');
      print('Auth URL: $authUrl');

      // ブラウザでGitHub認証ページを開く
      try {
        final uri = Uri.parse(authUrl);
        print('=== Launch Attempt ===');
        print('URI: $uri');

        final canLaunch = await canLaunchUrl(uri);
        print('Can launch URL: $canLaunch');

        if (canLaunch) {
          print('Attempting to launch browser...');

          // Android用により詳細な起動設定
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            browserConfiguration: const BrowserConfiguration(
              showTitle: true,
            ),
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );

          print('Launch result: $launched');

          if (launched) {
            print('GitHub Sign-In: Successfully launched browser');

            // Firebase URL を使用する場合の処理
            if (_githubRedirectUrl.startsWith('https://')) {
              print('GitHub Sign-In: Using Firebase redirect URL');
              print(
                  'Warning: sessionStorage issues may appear but authentication often succeeds');
              print(
                  'If error message appears, manually return to app to check authentication status');

              return await _handleFirebaseGitHubAuth(state);
            } else {
              // カスタムURL schemeの場合（現在は未実装）
              _showGitHubAuthInfo(context);
              return null;
            }
          } else {
            print('GitHub Sign-In: Failed to launch URL');
            _showBrowserIssueDialog(context);
            return null;
          }
        } else {
          print('GitHub Sign-In: Cannot launch URL: $authUrl');

          // Fallback: 異なる起動方法を試行
          print('Trying alternative launch method...');
          final fallbackLaunched = await _tryFallbackLaunch(uri);

          if (!fallbackLaunched) {
            _showBrowserIssueDialog(context);
            return null;
          } else {
            return await _handleFirebaseGitHubAuth(state);
          }
        }
      } catch (e) {
        print('GitHub Sign-In: Error launching URL: $e');
        _showBrowserIssueDialog(context);
        return null;
      }
    } catch (e) {
      print('GitHub Sign-In Error: $e');
      return null;
    }
  }

  Future<void> _checkFirebaseConfig() async {
    try {
      final app = Firebase.app();
      print('GitHub Sign-In: Firebase app configured: ${app.name}');
      print('GitHub Sign-In: Firebase project ID: ${app.options.projectId}');

      // GitHub認証プロバイダーが利用可能かチェック
      final providers =
          await _firebaseAuth.fetchSignInMethodsForEmail('test@example.com');
      print('GitHub Sign-In: Available providers: $providers');
    } catch (e) {
      print('GitHub Sign-In: Firebase config check error: $e');
    }
  }

  Future<User?> _handleFirebaseGitHubAuth(String state) async {
    try {
      print('GitHub Sign-In: Using Firebase Auth provider');

      // Firebase GitHub Auth Provider を使用
      final githubProvider = firebase_auth.GithubAuthProvider();
      githubProvider.addScope('user:email');
      githubProvider.setCustomParameters({
        'allow_signup': 'true',
        'state': state, // 状態パラメータを明示的に設定
      });

      print('GitHub Sign-In: Attempting Firebase sign-in with provider...');

      try {
        final result = await _firebaseAuth.signInWithProvider(githubProvider);

        if (result.user != null) {
          print('GitHub Sign-In: Successfully signed in with Firebase');
          print(
              'GitHub Sign-In: User: ${result.user!.email} (${result.user!.uid})');

          // 認証追跡を終了
          _isGitHubAuthInProgress = false;
          _githubAuthStartTime = null;

          // Firebase認証リスナーが自動的に _currentUser をセットします
          return _currentUser;
        } else {
          print('GitHub Sign-In: Firebase auth returned null user');
          return null;
        }
      } on firebase_auth.FirebaseAuthException catch (e) {
        print('GitHub Sign-In: Firebase auth exception: ${e.code}');
        print('GitHub Sign-In: Error message: ${e.message}');

        // "missing initial state" エラーの特別な処理
        if (e.message?.contains('missing initial state') == true ||
            e.message?.contains('sessionStorage') == true ||
            e.code == 'web-storage-unsupported') {
          print('GitHub Sign-In: Detected sessionStorage issue');
          print('Continuing authentication monitoring in background...');

          // エラーを表示せず、バックグラウンドで認証完了を待つ
          _startBackgroundAuthMonitoring();
          return null; // ユーザーには正常完了として扱う
        }

        // その他のFirebase認証エラー処理
        if (e.code == 'operation-not-supported-in-this-environment' ||
            e.code == 'popup-blocked' ||
            e.code == 'popup-closed-by-user') {
          print(
              'GitHub Sign-In: Firebase provider not available, trying fallback...');
          return await _handleManualGitHubAuth(state);
        }

        // 認証追跡を終了
        _isGitHubAuthInProgress = false;
        _githubAuthStartTime = null;

        return null;
      }
    } catch (e) {
      print('GitHub Sign-In: Unexpected error: $e');

      // sessionStorage問題の可能性をチェック
      if (e.toString().contains('missing initial state') ||
          e.toString().contains('sessionStorage')) {
        print('GitHub Sign-In: Detected sessionStorage issue in catch block');
        return await _handleSessionStorageIssue(state);
      }

      // 一般的なエラーの場合もfallbackを試行
      return await _handleManualGitHubAuth(state);
    }
  }

  Future<User?> _handleSessionStorageIssue(String state) async {
    try {
      print('=== SessionStorage Issue Handler ===');
      print('Attempting to resolve sessionStorage/state management issue...');
      print('This is a known Firebase Auth SDK issue:');
      print('https://github.com/firebase/firebase-js-sdk/issues/8629');

      // sessionStorage問題の詳細説明
      print('=== SessionStorage Problem Analysis ===');
      print('Error: "Unable to process request due to missing initial state"');
      print(
          'Cause: Browser sessionStorage access issues or partitioned storage');
      print('Environment: Android Chrome with strict storage policies');
      print('Impact: Authentication succeeds but redirect state is lost');

      // 方法1: Firebase Auth状態の強制チェック
      print('Method 1: Checking Firebase Auth state...');

      // 現在のFirebase認証状態を確認
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        print('Success: User is already authenticated in Firebase');
        print('User: ${currentUser.email} (${currentUser.uid})');

        // GitHub特有の情報を確認
        for (final providerData in currentUser.providerData) {
          if (providerData.providerId == 'github.com') {
            print('GitHub provider found: ${providerData.email}');
            return _currentUser; // 既に認証済み
          }
        }
      }

      // 方法2: 短時間待機後の再チェック
      print('Method 2: Waiting for state synchronization...');
      await Future.delayed(const Duration(seconds: 3));

      final delayedUser = _firebaseAuth.currentUser;
      if (delayedUser != null && delayedUser.uid != currentUser?.uid) {
        print('Success: Authentication completed after delay');
        return _currentUser;
      }

      // 方法3: 新しいブラウザセッションで再試行
      print('Method 3: Attempting fresh authentication session...');
      return await _retryGitHubAuthWithClearState(state);
    } catch (e) {
      print('SessionStorage issue handler error: $e');
      return null;
    }
  }

  Future<User?> _retryGitHubAuthWithClearState(String state) async {
    try {
      print('=== Fresh Authentication Attempt ===');

      // Firebase Auth キャッシュをクリア
      await _firebaseAuth.signOut();
      await Future.delayed(const Duration(seconds: 1));

      // 新しい状態で GitHub Auth を再試行
      print('Retrying GitHub authentication with fresh state...');

      final githubProvider = firebase_auth.GithubAuthProvider();
      githubProvider.addScope('user:email');

      // より明示的な状態管理
      final newState = DateTime.now().millisecondsSinceEpoch.toString();
      githubProvider.setCustomParameters({
        'allow_signup': 'true',
        'state': newState,
        'prompt': 'select_account', // アカウント選択を強制
      });

      print('Attempting Firebase sign-in with cleared state...');

      final result = await _firebaseAuth.signInWithProvider(githubProvider);

      if (result.user != null) {
        print('Success: GitHub authentication completed after retry');
        print('User: ${result.user!.email} (${result.user!.uid})');
        return _currentUser;
      } else {
        print('Retry failed: No user returned');
        return null;
      }
    } catch (e) {
      print('Fresh authentication attempt failed: $e');

      // 最終的なfallback: manual flow
      print('Falling back to manual authentication guidance...');
      return null;
    }
  }

  Future<User?> _handleManualGitHubAuth(String state) async {
    try {
      print('GitHub Sign-In: Using manual OAuth flow');

      // 新しいブラウザウィンドウでGitHub認証を開く
      final String authUrl = 'https://github.com/login/oauth/authorize'
          '?client_id=$_githubClientId'
          '&redirect_uri=${Uri.encodeComponent(_githubRedirectUrl)}'
          '&scope=user:email'
          '&state=$state';

      print('GitHub Sign-In: Manual auth URL: $authUrl');

      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('GitHub Sign-In: Manual auth browser launched successfully');
        // 注意: 手動フローの場合、ユーザーが認証を完了した後、
        // アプリに戻る仕組みが必要です（Deep LinkまたはWebView）
        return null;
      } else {
        print('GitHub Sign-In: Failed to launch manual auth browser');
        return null;
      }
    } catch (e) {
      print('GitHub Sign-In: Manual auth error: $e');
      return null;
    }
  }

  void _showGitHubAuthInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub認証'),
        content: const Text(
          'ブラウザでGitHub認証を完了してください。\n'
          'Firebase認証を使用している場合、認証は自動的に完了します。',
        ),
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

  Future<void> _saveGitHubToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_githubTokenKey, token);
      print('GitHub token saved to preferences');
    } catch (e) {
      print('Error saving GitHub token: $e');
    }
  }

  Future<void> _clearGitHubToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_githubTokenKey);
      print('GitHub token cleared');
    } catch (e) {
      print('Error clearing GitHub token: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('Sign out: Starting sign out process...');

      // 前回のログイン方法を取得
      final authProvider = await _getAuthProvider();
      print('Sign out: Previous auth provider: $authProvider');

      // Firebase Authからサインアウト
      await _firebaseAuth.signOut();
      print('Sign out: Firebase Auth sign out completed');

      // プロバイダー固有のサインアウト処理
      if (authProvider == 'google') {
        try {
          // Google Sign-Inからサインアウト（disconnectは使わない）
          await _googleSignIn.signOut();
          print('Sign out: Google Sign-In sign out completed');
        } catch (e) {
          print('Sign out: Error signing out from Google: $e');
          // エラーが発生してもサインアウト処理は続行
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

  // Clean up resources
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _periodicAuthCheckTimer?.cancel();
    _authStateController.close();

    // システムチャンネルリスナーをクリア
    SystemChannels.lifecycle.setMessageHandler(null);
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _userKey, Uri(queryParameters: user.toJson()).query);
    } catch (e) {
      print('Error saving user to SharedPreferences: $e');
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_githubTokenKey);
      await prefs.remove(_authProviderKey);
    } catch (e) {
      print('Error clearing user from SharedPreferences: $e');
    }
  }

  Future<void> _checkBrowserAvailability() async {
    try {
      // テストURLでブラウザの可用性をチェック
      final testUri = Uri.parse('https://www.google.com');
      final canLaunch = await canLaunchUrl(testUri);
      print('Browser available: $canLaunch');

      if (!canLaunch) {
        print('WARNING: No browser available for OAuth');
      }
    } catch (e) {
      print('Browser check error: $e');
    }
  }

  void _showBrowserIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ブラウザの問題'),
        content: const Text(
          'GitHub認証にはブラウザが必要です。\n\n'
          'Chromeの設定を確認してください：\n'
          '• 設定 → セキュリティとプライバシー\n'
          '• 「外部アプリで開く」を有効にする',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _tryFallbackLaunch(Uri uri) async {
    try {
      print('Fallback: Trying platformChanel launch...');

      // 方法1: インテント起動を試行
      final intentLaunched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (intentLaunched) {
        print('Fallback: Intent launch successful');
        return true;
      }

      // 方法2: in-app WebView
      print('Fallback: Trying in-app WebView...');
      final webViewLaunched = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

      if (webViewLaunched) {
        print('Fallback: WebView launch successful');
        return true;
      }

      print('Fallback: All methods failed');
      return false;
    } catch (e) {
      print('Fallback launch error: $e');
      return false;
    }
  }

  void _showSessionStorageIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セッションストレージの問題'),
        content: const Text(
          'セッションストレージの問題が発生している可能性があります。\n\n'
          'この問題が続く場合、アプリの再起動を試みてください。\n'
          'もし問題が解決しない場合、システムの設定を確認してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPeriodicAuthCheck() async {
    // 既存のタイマーをキャンセル
    _periodicAuthCheckTimer?.cancel();

    // 10秒ごとにFirebase認証状態をチェック（sessionStorage問題対応）
    _periodicAuthCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null && _currentUser == null) {
        print('AuthService: Detected delayed Firebase authentication');
        print(
            'User: ${currentFirebaseUser.email} (${currentFirebaseUser.uid})');

        // GitHub認証の可能性をチェック
        for (final providerData in currentFirebaseUser.providerData) {
          if (providerData.providerId == 'github.com') {
            print(
                'AuthService: GitHub authentication detected in periodic check');
            _currentUser = User.fromFirebaseUser(currentFirebaseUser);
            _authStateController.add(_currentUser);

            // GitHub認証追跡を終了
            _isGitHubAuthInProgress = false;
            _githubAuthStartTime = null;
            break;
          }
        }
      }
    });
  }

  void _setupAppLifecycleListener() {
    // システムチャンネルを使用してアプリの状態変化を監視
    SystemChannels.lifecycle.setMessageHandler((message) async {
      print('App lifecycle changed: $message');

      if (message == 'AppLifecycleState.resumed' && _isGitHubAuthInProgress) {
        print(
            'App resumed during GitHub authentication, checking auth state...');
        await _checkAuthStateAfterResume();
      }

      return null;
    });
  }

  Future<void> _checkAuthStateAfterResume() async {
    try {
      // アプリ復帰時のGitHub認証状態チェック
      await Future.delayed(const Duration(seconds: 1)); // 状態の安定化を待つ

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // GitHub認証が完了しているかチェック
        for (final providerData in currentUser.providerData) {
          if (providerData.providerId == 'github.com') {
            print('GitHub authentication detected after app resume!');
            print('User: ${currentUser.email} (${currentUser.uid})');

            _isGitHubAuthInProgress = false;
            _githubAuthStartTime = null;

            // 認証完了を通知
            _currentUser = User.fromFirebaseUser(currentUser);
            _authStateController.add(_currentUser);
            await _saveUserToPrefs(_currentUser!);

            return;
          }
        }
      }

      // 認証がまだ完了していない場合、もう少し待つ
      if (_isGitHubAuthInProgress && _githubAuthStartTime != null) {
        final elapsed = DateTime.now().difference(_githubAuthStartTime!);
        if (elapsed.inMinutes < 5) {
          // 5分以内なら継続監視
          print('GitHub auth still in progress, continuing monitoring...');
          _startIntensiveAuthMonitoring();
        } else {
          print('GitHub auth timeout, stopping monitoring');
          _isGitHubAuthInProgress = false;
          _githubAuthStartTime = null;
        }
      }
    } catch (e) {
      print('Error checking auth state after resume: $e');
    }
  }

  void _startIntensiveAuthMonitoring() {
    // 集中的な認証監視（2秒間隔で10回）
    int checkCount = 0;
    final intensiveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkCount++;

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        for (final providerData in currentUser.providerData) {
          if (providerData.providerId == 'github.com') {
            print(
                'GitHub authentication completed during intensive monitoring!');

            _isGitHubAuthInProgress = false;
            _githubAuthStartTime = null;

            _currentUser = User.fromFirebaseUser(currentUser);
            _authStateController.add(_currentUser);

            timer.cancel();
            return;
          }
        }
      }

      if (checkCount >= 10) {
        print('Intensive monitoring completed, no GitHub auth detected');
        timer.cancel();
        _isGitHubAuthInProgress = false;
      }
    });
  }

  void _startBackgroundAuthMonitoring() {
    // sessionStorageエラー発生時の特別な監視
    print(
        'Starting background authentication monitoring for sessionStorage issue');

    // 30秒間、2秒間隔で集中監視
    int checkCount = 0;
    final backgroundTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkCount++;

      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null && _currentUser == null) {
        print('Background monitoring: Authentication detected!');

        // GitHub認証の確認
        for (final providerData in currentFirebaseUser.providerData) {
          if (providerData.providerId == 'github.com') {
            print('Background monitoring: GitHub authentication completed!');
            _currentUser = User.fromFirebaseUser(currentFirebaseUser);
            _authStateController.add(_currentUser);

            _isGitHubAuthInProgress = false;
            _githubAuthStartTime = null;

            timer.cancel();
            return;
          }
        }
      }

      // 30秒後に監視終了
      if (checkCount >= 15) {
        print('Background monitoring completed');
        timer.cancel();
        _isGitHubAuthInProgress = false;
      }
    });
  }
}
