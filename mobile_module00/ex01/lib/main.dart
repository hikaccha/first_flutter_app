import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainState();
}

class _MainState extends State<MainApp> {
  bool _isHelloWorld = false;

  void _toggleText() {
    setState(() {
      _isHelloWorld = !_isHelloWorld;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isHelloWorld ? 'Hello World' : 'A simple text',
                  style: TextStyle(
                    backgroundColor: Colors.green.shade900,
                    fontSize: 35,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _toggleText,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.green.shade900,
                ),
                child: const Text('Click me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
