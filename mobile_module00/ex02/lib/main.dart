import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Calculator', home: const CalculatorScreen());
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _expressionController = TextEditingController(
    text: '0',
  );
  final TextEditingController _resultController = TextEditingController(
    text: '0',
  );

  void _onButtonPressed(String buttonText) {
    debugPrint('Button pressed: $buttonText');
    // Button press handling will be implemented in the next exercise
  }

  Widget _buildButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(20),
          ),
          child: Text(text, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Expression TextField
            TextField(
              controller: _expressionController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // Result TextField
            TextField(
              controller: _resultController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // Buttons
            Expanded(
              child: Column(
                children: [
                  // First row: AC, C, operators
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('C', color: Colors.red[100]),
                      _buildButton('AC', color: Colors.red[100]),
                    ],
                  ),
                  // Second row: 4,5,6,+,-
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('+', color: Colors.blue[100]),
                      _buildButton('-', color: Colors.blue[100]),
                    ],
                  ),
                  // Third row: 1,2,3,*,/
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('*', color: Colors.blue[100]),
                      _buildButton('/', color: Colors.blue[100]),
                    ],
                  ),
                  // Fourth row: 0,.,00,=
                  Row(
                    children: [
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('00'),
                      _buildButton('=', color: Colors.green[100]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _expressionController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
