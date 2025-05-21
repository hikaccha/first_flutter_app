import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインがキャンセルされました')),
          );
        }
        return;
      }

      // 2. Get Google Auth
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase Auth Credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      String message = 'ログインに失敗しました';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'このメールアドレスは別の方法で登録されています';
      } else if (e.code == 'invalid-credential') {
        message = '認証情報が無効です';
      } else if (e.code == 'operation-not-allowed') {
        message = 'このログイン方法は許可されていません';
      } else if (e.code == 'user-disabled') {
        message = 'このアカウントは無効化されています';
      } else if (e.code == 'user-not-found') {
        message = 'ユーザーが見つかりません';
      } else if (e.code == 'wrong-password') {
        message = 'パスワードが間違っています';
      } else if (e.code == 'invalid-verification-code') {
        message = '認証コードが無効です';
      } else if (e.code == 'invalid-verification-id') {
        message = '認証IDが無効です';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      print('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予期せぬエラーが発生しました: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Unexpected Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Googleでログイン'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: GitHubログイン処理を実装
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('GitHubでログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
