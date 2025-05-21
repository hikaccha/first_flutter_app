import 'package:flutter/material.dart';

// アプリケーションのエントリポイント
void main() {
  runApp(const MainApp());
}

// アプリケーションのルートウィジェット
// MaterialAppを設定してCalculatorScreenを表示する
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Calculator', home: const CalculatorScreen());
  }
}

// 電卓画面を表示するステートフルウィジェット
// 計算ロジックとUIを管理する
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // 入力式と計算結果を管理するコントローラー
  // expressionControllerは入力式を保持し、resultControllerは計算結果を表示する
  final TextEditingController _expressionController = TextEditingController(
    text: '0',
  );
  final TextEditingController _resultController = TextEditingController(
    text: '0',
  );

  // ボタンが押された時の処理
  // buttonTextにはボタンに表示されたテキストが渡される
  void _onButtonPressed(String buttonText) {
    setState(() {
      switch (buttonText) {
        case 'AC':
          // オールクリア: 入力式と結果をリセット
          _expressionController.text = '0';
          _resultController.text = '0';
          break;
        case 'C':
          // バックスペース: 1文字削除、または0にリセット
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
          // イコール: 計算実行して入力式を結果で上書き
          _calculateResult();
          _expressionController.text = _resultController.text;
          break;
        // case 'null':
        //   // 何もしない (将来の拡張用プレースホルダー)
        //   break;
        default:
          // 数字や演算子の入力処理
          if (_expressionController.text == '0') {
            // 初期状態（0）での処理
            if (buttonText == '-') {
              // マイナス記号はそのまま負数として使用
              _expressionController.text = '-';
            } else if (buttonText != '.' && buttonText != '00') {
              // 数字であれば0を上書き
              _expressionController.text = buttonText;
            } else {
              // 小数点や00は追加
              _expressionController.text += buttonText;
            }
          } else {
            // 通常状態での処理: テキストに追加
            _expressionController.text += buttonText;
          }
          // 入力のたびに計算結果を更新
          _calculateResult();
      }
    });
  }

  // 計算処理を実行するメソッド
  // 入力式を解析して計算し、結果をresultControllerに設定する
  void _calculateResult() {
    try {
      String expression = _expressionController.text;

      // 式が空または0だけの場合は計算しない
      if (expression.isEmpty || expression == '0') {
        _resultController.text = '0';
        return;
      }

      // 式が演算子で終わっている場合は計算を保留
      String lastChar = expression[expression.length - 1];
      if (lastChar == '+' ||
          lastChar == '-' ||
          lastChar == '*' ||
          lastChar == '/') {
        return; // エラーにせず処理を終了
      }

      // ステップ1: 式を数値と演算子のトークンに分解
      List<dynamic> tokens = [];
      String currentNumber = '';
      bool expectOperand = true; // 演算子の直後かどうかを判断するフラグ

      for (int i = 0; i < expression.length; i++) {
        String char = expression[i];

        if (char == '+' || char == '-' || char == '*' || char == '/') {
          // 演算子を処理

          // 現在の数値をトークンに追加
          if (currentNumber.isNotEmpty) {
            tokens.add(double.parse(currentNumber));
            currentNumber = '';
            expectOperand = false;
          }

          // 特殊ケース1: 式の先頭のマイナスは負数の符号として扱う
          if (i == 0 && char == '-') {
            currentNumber = '-';
            continue;
          }

          // 特殊ケース2: 演算子の後のマイナスは負数の符号として扱う
          // (例: 5*-3 の "-" は負の数の符号)
          if (char == '-' && expectOperand) {
            currentNumber = '-';
            continue;
          }

          // 通常の演算子はトークンに追加
          tokens.add(char);
          expectOperand = true;
        } else {
          // 数字や小数点は現在の数値に追加
          currentNumber += char;
        }
      }

      // 最後の数値をトークンに追加
      if (currentNumber.isNotEmpty) {
        tokens.add(double.parse(currentNumber));
      }

      // ステップ2: 演算子の優先順位に従って計算
      // 最初に乗算と除算を処理
      int i = 0;
      while (i < tokens.length) {
        if (i + 2 < tokens.length &&
            (tokens[i + 1] == '*' || tokens[i + 1] == '/')) {
          double leftOperand = tokens[i];
          String operator = tokens[i + 1];
          double rightOperand = tokens[i + 2];
          double result;

          if (operator == '*') {
            result = leftOperand * rightOperand;
          } else {
            // ゼロ除算チェック
            if (rightOperand == 0) {
              _resultController.text = 'Error: Division by zero';
              return;
            }
            result = leftOperand / rightOperand;
          }

          // 計算結果で元のトークンを置き換え
          tokens.removeRange(i, i + 3);
          tokens.insert(i, result);
        } else {
          i++;
        }
      }

      // トークンがない場合は0を返す
      if (tokens.isEmpty) {
        _resultController.text = '0';
        return;
      }

      // 次に加算と減算を処理
      double result = tokens[0];
      for (i = 1; i < tokens.length - 1; i += 2) {
        double rightOperand = tokens[i + 1];
        if (tokens[i] == '+') {
          result += rightOperand;
        } else if (tokens[i] == '-') {
          result -= rightOperand;
        }
      }

      // 結果のフォーマット: 整数の場合は小数点以下を表示しない
      if (result == result.toInt()) {
        _resultController.text = result.toInt().toString();
      } else {
        _resultController.text = result.toString();
      }
    } catch (e) {
      // エラーが発生した場合は「Error」と表示
      _resultController.text = 'Error';
    }
  }

  // 電卓のボタンを構築するヘルパーメソッド
  // text: ボタンに表示するテキスト
  // color: ボタンの背景色
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
            // 入力式を表示するテキストフィールド
            TextField(
              controller: _expressionController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // 計算結果を表示するテキストフィールド
            TextField(
              controller: _resultController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // 電卓のボタン部分
            Expanded(
              child: Column(
                children: [
                  // 1行目: 7,8,9,C,AC
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('C', color: Colors.red[100]),
                      _buildButton('AC', color: Colors.red[100]),
                    ],
                  ),
                  // 2行目: 4,5,6,+,-
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('+', color: Colors.blue[100]),
                      _buildButton('-', color: Colors.blue[100]),
                    ],
                  ),
                  // 3行目: 1,2,3,*,/
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('*', color: Colors.blue[100]),
                      _buildButton('/', color: Colors.blue[100]),
                    ],
                  ),
                  // 4行目: 0,.,00,=
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
    // コントローラーを破棄してメモリリークを防止
    _expressionController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
