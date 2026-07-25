import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

class VoiceQuizScreen extends StatefulWidget {
  const VoiceQuizScreen({super.key});

  @override
  State<VoiceQuizScreen> createState() => _VoiceQuizScreenState();
}

class _VoiceQuizScreenState extends State<VoiceQuizScreen> {
  final TtsService _tts = TtsService();
  final VoiceService _voiceService = VoiceService();
  
  int _currentQuestionIndex = 0;
  bool _isListening = false;
  bool _isGameActive = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'ما هي عاصمة مصر؟ واحد: القاهرة، اثنان: الإسكندرية، ثلاثة: أسوان',
      'validAnswers': ['قاهرة', 'القاهرة', 'واحد', '1', 'الاول', 'الأول'],
    },
    {
      'question': 'ما هو الحيوان الذي يسمى سفينة الصحراء؟ واحد: الحصان، اثنان: الجمل، ثلاثة: الفيل',
      'validAnswers': ['جمل', 'الجمل', 'اثنان', 'اثنين', '2', 'الثاني'],
    },
    {
      'question': 'كم عدد قارات العالم؟ واحد: خمسة، اثنان: ستة، ثلاثة: سبعة',
      'validAnswers': ['سبعة', 'سبع', 'ثلاثة', 'تلاتة', '3', 'الثالث'],
    },
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
      "لعبة أسئلة وأجوبة. سأطرح عليك سؤالاً وأعطيك اختيارات. "
      "بعد سماع السؤال، اضغط مرتين على الشاشة وقل إجابتك، يمكنك قول رقم الاختيار أو الإجابة نفسها."
      "اضغط مرتين الآن للبدء."
    );
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _currentQuestionIndex = 0;
    });
    _askQuestion();
  }

  void _askQuestion() async {
    if (_currentQuestionIndex >= _questions.length) {
      await _tts.speak("مبروك! لقد أجبت على جميع الأسئلة بنجاح. اضغط مرتين للعب مرة أخرى.");
      setState(() {
        _isGameActive = false;
      });
      return;
    }

    await _tts.speak(_questions[_currentQuestionIndex]['question']);
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

    // Auto stop after 10 seconds if no valid answer
    Timer(const Duration(seconds: 10), () {
      if (_isListening) {
        _voiceService.stopListening();
        setState(() => _isListening = false);
        _tts.speak("لم أسمع إجابة. اضغط مرتين للمحاولة مرة أخرى.");
      }
    });
  }

  void _checkAnswer(String spokenText, bool isFinal) async {
    if (!_isListening) return;

    final String lowerText = spokenText.toLowerCase();
    final List<String> validAnswers = _questions[_currentQuestionIndex]['validAnswers'];

    bool isCorrect = false;
    for (String answer in validAnswers) {
      if (lowerText.contains(answer)) {
        isCorrect = true;
        break;
      }
    }

    if (isCorrect) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
      await _tts.speak("إجابة صحيحة! أحسنت.");
      setState(() {
        _currentQuestionIndex++;
      });
      Timer(const Duration(seconds: 2), _askQuestion);
    } else if (isFinal && spokenText.isNotEmpty) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      Vibration.vibrate(duration: 500);
      await _tts.speak("إجابة خاطئة. حاول مرة أخرى. اضغط مرتين للإجابة.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      appBar: AppBar(
        title: const Text('أسئلة وأجوبة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onDoubleTap: _startListening,
        child: Container(
          color: Colors.transparent, // To capture taps everywhere
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.quiz,
                size: 120,
                color: _isListening ? Colors.redAccent : Colors.white54,
              ),
              const SizedBox(height: 32),
              Text(
                _isListening ? 'جاري الاستماع...' : 'اضغط مرتين للإجابة',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isGameActive)
                Text(
                  'سؤال ${_currentQuestionIndex + 1} من ${_questions.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
