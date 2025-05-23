import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    // 既に認証されているかチェック
    _checkAlreadyLoggedIn();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // 既にロード中なら処理をスキップ

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else if (mounted) {
        _showErrorDialog('Googleログインに失敗しました');
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      if (mounted) {
        _showErrorDialog('Googleログインに失敗しました: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGitHub() async {
    if (_isLoading) return; // 既にロード中なら処理をスキップ

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final result = await _authService.signInWithGitHub(context);
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else if (mounted) {
        // リダイレクトURLの問題かもしれないのでその旨を表示
        _showErrorDialog('GitHubログインに失敗しました。リダイレクトURLの設定を確認してください。');
        setState(() {
          _lastError = 'GitHub認証に失敗しました。リダイレクトURLが正しく設定されていない可能性があります。';
        });
      }
    } catch (e) {
      print('GitHub Sign-In Error: $e');
      if (mounted) {
        _showErrorDialog('GitHubログインに失敗しました: ${e.toString()}');
        setState(() {
          _lastError = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    // Googleでログイン
                    ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      icon: Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 24.0,
                      ),
                      label: const Text('Googleでログイン'),
                    ),
                    const SizedBox(height: 24),
                    // GitHubでログイン
                    ElevatedButton.icon(
                      onPressed: _signInWithGitHub,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      icon: Image.network(
                        'https://github.githubassets.com/assets/GitHub-Mark-ea2971cee799.png',
                        height: 24.0,
                      ),
                      label: const Text('GitHubでログイン'),
                    ),

                    if (_lastError != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'エラー情報:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _lastError!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
