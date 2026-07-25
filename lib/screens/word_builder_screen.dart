import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({super.key});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> {
  final TtsService _tts = TtsService();
  final VoiceService _voiceService = VoiceService();
  
  bool _isListening = false;
  bool _isGameActive = false;
  String _currentLetter = '';
  int _score = 0;

  final List<String> _arabicLetters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش',
    'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'
  ];

  @override
  void initState() {
    super.initState();
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    await _voiceService.init();
    _announceInstructions();
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _tts.stop();
    super.dispose();
  }

  void _announceInstructions() async {
    await _tts.speak(
      "لعبة الكلمات. سأعطيك حرفاً، وعليك أن تقول كلمة تبدأ بهذا الحرف. "
      "اضغط مرتين لسماع الحرف والبدء."
    );
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _score = 0;
    });
    _nextLetter();
  }

  void _nextLetter() async {
    final random = Random();
    setState(() {
      _currentLetter = _arabicLetters[random.nextInt(_arabicLetters.length)];
    });
    await _tts.speak("حرف $_currentLetter. اضغط مرتين وقل كلمة تبدأ بحرف $_currentLetter.");
  }

  void _startListening() {
    if (!_isGameActive) {
      _startGame();
      return;
    }

    if (_isListening) return;

    setState(() => _isListening = true);
    Vibration.vibrate(duration: 100);
    
    _voiceService.startListening((text, isFinal) {
      _checkAnswer(text, isFinal);
    });

    Timer(const Duration(seconds: 10), () {
      if (_isListening) {
        _voiceService.stopListening();
        setState(() => _isListening = false);
        _tts.speak("انتهى الوقت. اضغط مرتين للمحاولة مرة أخرى.");
      }
    });
  }

  void _checkAnswer(String spokenText, bool isFinal) async {
    if (!_isListening) return;

    if (spokenText.isEmpty) {
        if (isFinal) {
            _voiceService.stopListening();
            setState(() => _isListening = false);
        }
        return;
    }

    // Clean up text
    String cleanedText = spokenText.trim();
    // Normalize alef
    cleanedText = cleanedText.replaceAll('إ', 'أ').replaceAll('آ', 'أ').replaceAll('ا', 'أ');
    String normalizedLetter = _currentLetter.replaceAll('إ', 'أ').replaceAll('آ', 'أ').replaceAll('ا', 'أ');

    if (cleanedText.startsWith(normalizedLetter)) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
      setState(() => _score++);
      await _tts.speak("ممتاز! $cleanedText تبدأ بحرف $_currentLetter. رصيدك الآن $_score نقطة.");
      Timer(const Duration(seconds: 3), _nextLetter);
    } else if (isFinal) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      Vibration.vibrate(duration: 500);
      await _tts.speak("كلمة $cleanedText لا تبدأ بحرف $_currentLetter. حاول مرة أخرى واضغط مرتين.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        title: const Text('لعبة الكلمات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onDoubleTap: _startListening,
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentLetter.isEmpty ? '?' : _currentLetter,
                style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Icon(
                _isListening ? Icons.mic : Icons.sort_by_alpha,
                size: 80,
                color: _isListening ? Colors.redAccent : Colors.white54,
              ),
              const SizedBox(height: 32),
              Text(
                _isListening ? 'جاري الاستماع...' : 'اضغط مرتين لقول الكلمة',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'النقاط: $_score',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
