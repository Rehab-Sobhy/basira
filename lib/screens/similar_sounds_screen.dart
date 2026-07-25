import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

class SimilarSoundsScreen extends StatefulWidget {
  const SimilarSoundsScreen({super.key});

  @override
  State<SimilarSoundsScreen> createState() => _SimilarSoundsScreenState();
}

class _SimilarSoundsScreenState extends State<SimilarSoundsScreen> {
  final TtsService _tts = TtsService();
  final VoiceService _voiceService = VoiceService();
  
  bool _isListening = false;
  bool _isGameActive = false;
  bool _isPlayingSounds = false;
  int _currentLevel = 0;
  int _score = 0;

  // Using TTS pitch to create distinct sounds instead of URLs
  final double _pitch1 = 1.0;
  final double _pitch2 = 1.5;
  final double _pitch3 = 0.5;

  late List<Map<String, dynamic>> _levels;

  @override
  void initState() {
    super.initState();
    _levels = [
      {'soundA': _pitch1, 'soundB': _pitch1, 'isSame': true},
      {'soundA': _pitch1, 'soundB': _pitch2, 'isSame': false},
      {'soundA': _pitch2, 'soundB': _pitch2, 'isSame': true},
      {'soundA': _pitch2, 'soundB': _pitch3, 'isSame': false},
      {'soundA': _pitch3, 'soundB': _pitch1, 'isSame': false},
    ];
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    await _voiceService.init();
    _announceInstructions();
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _tts.setSettings(pitch: 1.0); // Reset pitch
    _tts.stop();
    super.dispose();
  }

  void _announceInstructions() async {
    await _tts.speak(
      "لعبة تمييز الأصوات المتشابهة. سأقوم بتشغيل صوتين متتاليين. "
      "عليك أن تخبرني هل هما نفس الصوت أم مختلفان. "
      "قل 'متشابهة' أو 'مختلفة' بعد سماع الصوتين. اضغط مرتين للبدء."
    );
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _currentLevel = 0;
      _score = 0;
    });
    _playLevel();
  }

  Future<void> _playLevel() async {
    if (_currentLevel >= _levels.length) {
      await _tts.speak("لقد أنهيت جميع المستويات! رصيدك $_score من ${_levels.length}. اضغط مرتين للعب مرة أخرى.");
      setState(() {
        _isGameActive = false;
      });
      return;
    }

    setState(() => _isPlayingSounds = true);
    
    final level = _levels[_currentLevel];
    
    // Play Sound A
    await _tts.setSettings(pitch: level['soundA']);
    await _tts.speak("بيييب");
    await Future.delayed(const Duration(milliseconds: 1500)); // Wait for sound to finish
    
    // Play Sound B
    await _tts.setSettings(pitch: level['soundB']);
    await _tts.speak("بيييب");
    await Future.delayed(const Duration(milliseconds: 1500));
    
    await _tts.setSettings(pitch: 1.0); // Reset pitch for instructions

    setState(() => _isPlayingSounds = false);
    await _tts.speak("هل الأصوات متشابهة أم مختلفة؟ اضغط مرتين وأجب.");
  }

  void _startListening() {
    if (!_isGameActive) {
      _startGame();
      return;
    }

    if (_isListening || _isPlayingSounds) return;

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

    final String lowerText = spokenText.toLowerCase();
    final bool isSame = _levels[_currentLevel]['isSame'];
    
    bool userSaidSame = lowerText.contains('متشابهة') || lowerText.contains('نفس') || lowerText.contains('متشابه');
    bool userSaidDifferent = lowerText.contains('مختلفة') || lowerText.contains('مختلف') || lowerText.contains('لا');

    if (userSaidSame || userSaidDifferent) {
        _voiceService.stopListening();
        setState(() => _isListening = false);

        bool isCorrect = (isSame && userSaidSame) || (!isSame && userSaidDifferent);

        if (isCorrect) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
          setState(() => _score++);
          await _tts.speak("إجابة صحيحة!");
        } else {
          Vibration.vibrate(duration: 500);
          await _tts.speak("إجابة خاطئة. الصوتان كانا ${isSame ? 'متشابهين' : 'مختلفين'}.");
        }

        setState(() {
          _currentLevel++;
        });
        
        Timer(const Duration(seconds: 2), _playLevel);
    } else if (isFinal) {
        _voiceService.stopListening();
        setState(() => _isListening = false);
        await _tts.speak("لم أفهم الإجابة. قل متشابهة أو مختلفة. اضغط مرتين للإجابة.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text('تمييز الأصوات'),
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
              Icon(
                _isPlayingSounds ? Icons.volume_up : (_isListening ? Icons.mic : Icons.hearing),
                size: 120,
                color: _isPlayingSounds ? Colors.greenAccent : (_isListening ? Colors.redAccent : Colors.white54),
              ),
              const SizedBox(height: 32),
              Text(
                _isPlayingSounds ? 'استمع جيداً...' : (_isListening ? 'جاري الاستماع...' : 'اضغط مرتين للإجابة'),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isGameActive)
                Text(
                  'المستوى ${_currentLevel + 1} من ${_levels.length} | النقاط: $_score',
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
