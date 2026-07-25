// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:vibration/vibration.dart';
// import 'package:audioplayers/audioplayers.dart';
// import '../services/tts_service.dart';
// import '../services/voice_service.dart';

// class WhereAmIScreen extends StatefulWidget {
//   const WhereAmIScreen({super.key});

//   @override
//   State<WhereAmIScreen> createState() => _WhereAmIScreenState();
// }

// class _WhereAmIScreenState extends State<WhereAmIScreen> {
//   final TtsService _tts = TtsService();
//   final VoiceService _voiceService = VoiceService();
//   final AudioPlayer _audioPlayer = AudioPlayer();
  
//   bool _isListening = false;
//   bool _isGameActive = false;
//   bool _isPlayingSound = false;
//   int _currentLevel = 0;
//   int _score = 0;

//   final List<Map<String, dynamic>> _locations = [
//     {
//       'url': 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Ocean_waves_and_birds.ogg',
//       'question': 'أين أنا؟ هل في البحر، أم الشارع، أم الغابة؟',
//       'validAnswers': ['بحر', 'البحر'],
//       'name': 'البحر'
//     },
//     {
//       'url': 'https://upload.wikimedia.org/wikipedia/commons/e/ec/Rain_in_a_forest.ogg',
//       'question': 'أين أنا؟ هل هذا صوت المطر، أم شارع مزدحم، أم بحر؟',
//       'validAnswers': ['مطر', 'المطر'],
//       'name': 'المطر'
//     },
//     {
//       'url': 'https://upload.wikimedia.org/wikipedia/commons/2/23/Traffic_in_Cairo.ogg',
//       'question': 'أين أنا؟ هل أنا في البحر، أم الشارع، أم المنزل؟',
//       'validAnswers': ['شارع', 'الشارع', 'مرور', 'سيارات', 'زحمة'],
//       'name': 'الشارع'
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initVoiceService();
//   }

//   Future<void> _initVoiceService() async {
//     await _voiceService.init();
//     _announceInstructions();
//   }

//   @override
//   void dispose() {
//     _voiceService.stopListening();
//     _audioPlayer.dispose();
//     _tts.stop();
//     super.dispose();
//   }

//   void _announceInstructions() async {
//     await _tts.speak(
//       "لعبة أين أنا؟ سأقوم بتشغيل صوت لمكان معين. "
//       "استمع للصوت جيداً، ثم اضغط مرتين وقل أين أنا. "
//       "اضغط مرتين الآن للبدء."
//     );
//   }

//   void _startGame() {
//     setState(() {
//       _isGameActive = true;
//       _currentLevel = 0;
//       _score = 0;
//     });
//     _playLevel();
//   }

//   Future<void> _playLevel() async {
//     if (_currentLevel >= _locations.length) {
//       await _tts.speak("لقد أنهيت جميع الأماكن! رصيدك $_score من ${_locations.length}. اضغط مرتين للعب مرة أخرى.");
//       setState(() {
//         _isGameActive = false;
//       });
//       return;
//     }

//     setState(() => _isPlayingSound = true);
    
//     final location = _locations[_currentLevel];
    
//     try {
//       await _audioPlayer.setReleaseMode(ReleaseMode.loop);
//       await _audioPlayer.play(UrlSource(location['url'])).timeout(const Duration(seconds: 5));
//       // Let the sound play for a few seconds before asking
//       await Future.delayed(const Duration(seconds: 4));
//     } catch (e) {
//       debugPrint("Audio load failed: $e");
//       // Fallback if audio fails to load
//       await _tts.speak("حدث خطأ في تحميل الصوت. تخيل أنك تسمع صوت ${location['name']}.");
//     }
    
//     await _tts.speak(location['question']);
//     setState(() => _isPlayingSound = false);
//   }

//   void _startListening() {
//     if (!_isGameActive) {
//       _startGame();
//       return;
//     }

//     if (_isListening) return;

//     setState(() => _isListening = true);
//     Vibration.vibrate(duration: 100);
    
//     // Pause background audio while listening
//     _audioPlayer.pause();

//     _voiceService.startListening((text) {
//       _checkAnswer(text);
//     });

//     Timer(const Duration(seconds: 5), () {
//       if (_isListening) {
//         _voiceService.stopListening();
//         _audioPlayer.resume();
//         setState(() => _isListening = false);
//         _tts.speak("لم أسمع إجابة. اضغط مرتين للمحاولة مرة أخرى.");
//       }
//     });
//   }

//   void _checkAnswer(String spokenText) async {
//     if (!_isListening) return;
//     _voiceService.stopListening();
//     await _audioPlayer.stop();
//     setState(() => _isListening = false);

//     final String lowerText = spokenText.toLowerCase();
//     final location = _locations[_currentLevel];
//     final List<String> validAnswers = location['validAnswers'];

//     bool isCorrect = false;
//     for (String answer in validAnswers) {
//       if (lowerText.contains(answer)) {
//         isCorrect = true;
//         break;
//       }
//     }

//     if (isCorrect) {
//       Vibration.vibrate(pattern: [0, 200, 100, 200]);
//       setState(() => _score++);
//       await _tts.speak("إجابة صحيحة! نحن فعلاً في ${location['name']}.");
//     } else {
//       Vibration.vibrate(duration: 500);
//       await _tts.speak("إجابة خاطئة. كنا في ${location['name']}.");
//     }

//     setState(() {
//       _currentLevel++;
//     });
    
//     Timer(const Duration(seconds: 3), _playLevel);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.lightBlue.shade900,
//       appBar: AppBar(
//         title: const Text('أين أنا؟'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GestureDetector(
//         onDoubleTap: _startListening,
//         child: Container(
//           color: Colors.transparent,
//           width: double.infinity,
//           height: double.infinity,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 _isPlayingSound ? Icons.explore : (_isListening ? Icons.mic : Icons.location_on),
//                 size: 120,
//                 color: _isPlayingSound ? Colors.greenAccent : (_isListening ? Colors.redAccent : Colors.white54),
//               ),
//               const SizedBox(height: 32),
//               Text(
//                 _isPlayingSound ? 'استمع للمكان...' : (_isListening ? 'جاري الاستماع...' : 'اضغط مرتين للإجابة'),
//                 style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               if (_isGameActive)
//                 Text(
//                   'المكان ${_currentLevel + 1} من ${_locations.length} | النقاط: $_score',
//                   style: const TextStyle(color: Colors.white70, fontSize: 20),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
