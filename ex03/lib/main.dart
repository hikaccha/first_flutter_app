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
    setState(() {
      switch (buttonText) {
        case 'AC':
          _expressionController.text = '0';
          _resultController.text = '0';
          break;
        case 'C':
          if (_expressionController.text.length > 1) {
            _expressionController.text = _expressionController.text.substring(
              0,
              _expressionController.text.length - 1,
            );
          } else {
            _expressionController.text = '0';
          }
          _calculateResult();
          break;
        case '=':
          _calculateResult();
          _expressionController.text = _resultController.text;
          break;
        case 'null':
          // Do nothing for null button
          break;
        default:
          if (_expressionController.text == '0' &&
              buttonText != '.' &&
              buttonText != '00') {
            _expressionController.text = buttonText;
          } else {
            _expressionController.text += buttonText;
          }
          _calculateResult();
      }
    });
  }

  void _calculateResult() {
    try {
      String expression = _expressionController.text;

      // Handle negative numbers
      expression = expression.replaceAll('--', '+');

      // Split the expression into numbers and operators
      List<String> tokens = [];
      String currentNumber = '';

      for (int i = 0; i < expression.length; i++) {
        String char = expression[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (currentNumber.isNotEmpty) {
            tokens.add(currentNumber);
            currentNumber = '';
          }
          tokens.add(char);
        } else {
          currentNumber += char;
        }
      }
      if (currentNumber.isNotEmpty) {
        tokens.add(currentNumber);
      }

      // First pass: multiplication and division
      for (int i = 1; i < tokens.length - 1; i += 2) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double num1 = double.parse(tokens[i - 1]);
          double num2 = double.parse(tokens[i + 1]);
          double result;

          if (tokens[i] == '*') {
            result = num1 * num2;
          } else {
            if (num2 == 0) {
              _resultController.text = 'Error: Division by zero';
              return;
            }
            result = num1 / num2;
          }

          tokens[i - 1] = result.toString();
          tokens.removeAt(i);
          tokens.removeAt(i);
          i -= 2;
        }
      }

      // Second pass: addition and subtraction
      double finalResult = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length - 1; i += 2) {
        double num2 = double.parse(tokens[i + 1]);
        if (tokens[i] == '+') {
          finalResult += num2;
        } else {
          finalResult -= num2;
        }
      }

      // Format the result to avoid unnecessary decimal places
      if (finalResult == finalResult.toInt()) {
        _resultController.text = finalResult.toInt().toString();
      } else {
        _resultController.text = finalResult.toString();
      }
    } catch (e) {
      _resultController.text = 'Error';
    }
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
                  // First row: 7,8,9,C,AC
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
