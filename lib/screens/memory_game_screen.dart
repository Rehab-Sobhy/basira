import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final TtsService _tts = TtsService();
  final List<int> _sequence = [];
  final List<int> _userInput = [];
  bool _isPlayingSequence = false;
  int _level = 1;
  bool _gameStarted = false;

  final Map<int, Map<String, dynamic>> _quadrants = {
    0: {'label': 'أعلى يسار', 'color': Colors.blue, 'vibration': 100},
    1: {'label': 'أعلى يمين', 'color': Colors.red, 'vibration': 200},
    2: {'label': 'أسفل يسار', 'color': Colors.green, 'vibration': 300},
    3: {'label': 'أسفل يمين', 'color': Colors.orange, 'vibration': 400},
  };

  @override
  void initState() {
    super.initState();
    _announceInstructions();
  }

  void _announceInstructions() {
    _tts.speak(
      "لعبة الذاكرة الصوتية. "
      "سأقوم بتشغيل سلسلة من الاتجاهات، وعليك تكرارها بالضغط على الشاشة. "
      "الشاشة مقسمة لأربعة أجزاء: أعلى يسار، أعلى يمين، أسفل يسار، وأسفل يمين. "
      "اضغط مرتين في أي مكان لبدء اللعبة.",
    );
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _level = 1;
      _sequence.clear();
      _userInput.clear();
    });
    _nextLevel();
  }

  void _nextLevel() async {
    _userInput.clear();
    _sequence.add(Random().nextInt(4));

    setState(() => _isPlayingSequence = true);

    await Future.delayed(const Duration(seconds: 1));

    for (int index in _sequence) {
      await _playQuadrant(index);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    setState(() => _isPlayingSequence = false);
    _tts.speak("دورك الآن.");
  }

  Future<void> _playQuadrant(int index) async {
    final quadrant = _quadrants[index]!;
    await _tts.speak(quadrant['label']);
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: quadrant['vibration']);
    }
  }

  void _handleTap(int index) {
    if (_isPlayingSequence || !_gameStarted) return;

    _playQuadrant(index);
    _userInput.add(index);

    if (_userInput.last != _sequence[_userInput.length - 1]) {
      _gameOver();
      return;
    }

    if (_userInput.length == _sequence.length) {
      _levelSuccess();
    }
  }

  void _levelSuccess() {
    _tts.speak("رائع! المستوى التالي.");
    setState(() {
      _level++;
    });
    Timer(const Duration(seconds: 2), _nextLevel);
  }

  void _gameOver() {
    _tts.speak(
      "للأسف، إجابة خاطئة. لقد وصلت للمستوى $_level. اضغط مرتين للبدء من جديد.",
    );
    setState(() {
      _gameStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('لعبة الذاكرة - مستوى $_level'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onDoubleTap: () {
          if (!_gameStarted) _startGame();
        },
        child: Column(
          children: [
            Expanded(
              child: Row(children: [_buildQuadrant(0), _buildQuadrant(1)]),
            ),
            Expanded(
              child: Row(children: [_buildQuadrant(2), _buildQuadrant(3)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrant(int index) {
    final quadrant = _quadrants[index]!;
    return Expanded(
      child: InkWell(
        onTap: () => _handleTap(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: quadrant['color'].withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: quadrant['color'], width: 2),
          ),
          child: Center(
            child: Semantics(
              label: quadrant['label'],
              child: Text(
                quadrant['label'],
                style: TextStyle(
                  color: quadrant['color'],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
