import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scientific Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _display = '0';

  // Button colors
  static const Color _bgDark = Color(0xFF1E1E1E);
  static const Color _btnDark = Color(0xFF2D2D2D);
  static const Color _btnScientific = Color(0xFF4A7A8A);
  static const Color _btnOrange = Color(0xFFFF9500);
  static const Color _btnRed = Color(0xFFE53935);
  static const Color _btnGreen = Color(0xFF43A047);
  static const Color _btnPink = Color(0xFFE91E63);

  void _onButtonPressed(String label) {
    setState(() {
      switch (label) {
        case 'C':
          _expression = '';
          _display = '0';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _display = _expression.isEmpty ? '0' : _expression;
          }
          break;
        case '=':
          _calculate();
          break;
        default:
          _expression += label;
          _display = _expression;
      }
    });
  }

  void _calculate() {
    try {
      // Replace display-friendly symbols with math equivalents
      String expr = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', pi.toString())
          .replaceAll('e', e.toString());

      // Handle sqrt(
      expr = _processFunctions(expr);

      final result = _evalExpression(expr);

      if (result == result.truncateToDouble()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _expression = _display;
    } catch (e) {
      _display = 'Hata';
      _expression = '';
    }
  }

  String _processFunctions(String expr) {
    // sin(x), cos(x), tan(x), log(x), sqrt(x)
    expr = _replaceFunctionCalls(expr, 'sin', (x) => sin(x * pi / 180));
    expr = _replaceFunctionCalls(expr, 'cos', (x) => cos(x * pi / 180));
    expr = _replaceFunctionCalls(expr, 'tan', (x) => tan(x * pi / 180));
    expr = _replaceFunctionCalls(expr, 'log', (x) => log(x) / ln10);
    expr = _replaceFunctionCalls(expr, 'sqrt', (x) => sqrt(x));
    return expr;
  }

  String _replaceFunctionCalls(String expr, String funcName, double Function(double) func) {
    final regex = RegExp('$funcName\\(([^()]+)\\)');
    while (regex.hasMatch(expr)) {
      expr = expr.replaceAllMapped(regex, (match) {
        final inner = match.group(1)!;
        final val = _evalExpression(inner);
        return func(val).toString();
      });
    }
    return expr;
  }

  double _evalExpression(String expr) {
    // Handle ^ (power)
    expr = expr.replaceAllMapped(
      RegExp(r'([\d.]+)\^([\d.]+)'),
      (m) => pow(double.parse(m.group(1)!), double.parse(m.group(2)!)).toString(),
    );

    // Simple recursive descent parser
    return _parseExpr(expr.replaceAll(' ', ''));
  }

  // Simple expression evaluator (+-*/)
  int _pos = 0;
  String _currentExpr = '';

  double _parseExpr(String expr) {
    _currentExpr = expr;
    _pos = 0;
    return _parseAddSub();
  }

  double _parseAddSub() {
    double result = _parseMulDiv();
    while (_pos < _currentExpr.length &&
        (_currentExpr[_pos] == '+' || _currentExpr[_pos] == '-')) {
      final op = _currentExpr[_pos++];
      final right = _parseMulDiv();
      result = op == '+' ? result + right : result - right;
    }
    return result;
  }

  double _parseMulDiv() {
    double result = _parseUnary();
    while (_pos < _currentExpr.length &&
        (_currentExpr[_pos] == '*' || _currentExpr[_pos] == '/')) {
      final op = _currentExpr[_pos++];
      final right = _parseUnary();
      result = op == '*' ? result * right : result / right;
    }
    return result;
  }

  double _parseUnary() {
    if (_pos < _currentExpr.length && _currentExpr[_pos] == '-') {
      _pos++;
      return -_parsePrimary();
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    if (_pos < _currentExpr.length && _currentExpr[_pos] == '(') {
      _pos++; // skip '('
      final result = _parseAddSub();
      if (_pos < _currentExpr.length && _currentExpr[_pos] == ')') {
        _pos++; // skip ')'
      }
      return result;
    }
    // Parse number
    int start = _pos;
    while (_pos < _currentExpr.length &&
        (RegExp(r'[\d.]').hasMatch(_currentExpr[_pos]))) {
      _pos++;
    }
    if (start == _pos) throw FormatException('Unexpected character at $_pos');
    return double.parse(_currentExpr.substring(start, _pos));
  }

  Widget _buildButton({
    required String label,
    required Color color,
    int flex = 1,
    Color textColor = Colors.white,
    double fontSize = 20,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _onButtonPressed(label),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Scientific Calculator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Display
            Expanded(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            // Buttons
            Container(
              color: _bgDark,
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  // Row 1: sin, cos, tan, log
                  Row(children: [
                    _buildButton(label: 'sin(', color: _btnScientific, fontSize: 16),
                    _buildButton(label: 'cos(', color: _btnScientific, fontSize: 16),
                    _buildButton(label: 'tan(', color: _btnScientific, fontSize: 16),
                    _buildButton(label: 'log(', color: _btnScientific, fontSize: 16),
                  ]),
                  // Row 2: sqrt, ^, (, )
                  Row(children: [
                    _buildButton(label: 'sqrt(', color: _btnScientific, fontSize: 15),
                    _buildButton(label: '^', color: _btnScientific),
                    _buildButton(label: '(', color: _btnScientific),
                    _buildButton(label: ')', color: _btnScientific),
                  ]),
                  // Row 3: 7, 8, 9, ÷
                  Row(children: [
                    _buildButton(label: '7', color: _btnDark),
                    _buildButton(label: '8', color: _btnDark),
                    _buildButton(label: '9', color: _btnDark),
                    _buildButton(label: '÷', color: _btnOrange),
                  ]),
                  // Row 4: 4, 5, 6, ×
                  Row(children: [
                    _buildButton(label: '4', color: _btnDark),
                    _buildButton(label: '5', color: _btnDark),
                    _buildButton(label: '6', color: _btnDark),
                    _buildButton(label: '×', color: _btnOrange),
                  ]),
                  // Row 5: 1, 2, 3, -
                  Row(children: [
                    _buildButton(label: '1', color: _btnDark),
                    _buildButton(label: '2', color: _btnDark),
                    _buildButton(label: '3', color: _btnDark),
                    _buildButton(label: '-', color: _btnOrange),
                  ]),
                  // Row 6: 0, ., ⌫, +
                  Row(children: [
                    _buildButton(label: '0', color: _btnDark),
                    _buildButton(label: '.', color: _btnDark),
                    _buildButton(label: '⌫', color: _btnPink),
                    _buildButton(label: '+', color: _btnOrange),
                  ]),
                  // Row 7: C (span 2), = (span 2)
                  Row(children: [
                    _buildButton(label: 'C', color: _btnRed, flex: 2),
                    _buildButton(label: '=', color: _btnGreen, flex: 2),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}