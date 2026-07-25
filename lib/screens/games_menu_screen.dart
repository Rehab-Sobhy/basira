import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/large_button.dart';
import 'memory_game_screen.dart';
import 'voice_quiz_screen.dart';
import 'word_builder_screen.dart';
import 'similar_sounds_screen.dart';


class GamesMenuScreen extends StatefulWidget {
  const GamesMenuScreen({super.key});

  @override
  State<GamesMenuScreen> createState() => _GamesMenuScreenState();
}

class _GamesMenuScreenState extends State<GamesMenuScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _tts.speak(
      "قائمة الألعاب الصوتية. اسحب لاختيار اللعبة ثم اضغط مرتين للبدء.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الألعاب الصوتية'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LargeButton(
              text: 'لعبة الذاكرة الصوتية',
              color: Colors.purple,
              icon: Icons.memory,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemoryGameScreen(),
                ),
              ),
            ),
            LargeButton(
              text: 'لعبة أسئلة وأجوبة',
              color: Colors.deepPurple,
              icon: Icons.quiz,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceQuizScreen(),
                ),
              ),
            ),
            LargeButton(
              text: 'لعبة الكلمات',
              color: Colors.indigo,
              icon: Icons.sort_by_alpha,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WordBuilderScreen(),
                ),
              ),
            ),
            LargeButton(
              text: 'تمييز الأصوات المتشابهة',
              color: Colors.blue,
              icon: Icons.hearing,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimilarSoundsScreen(),
                ),
              ),
            ),
            // LargeButton(
            //   text: 'أين أنا؟',
            //   color: Colors.lightBlue,
            //   icon: Icons.explore,
            //   onDoubleTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WhereAmIScreen())),
            // ),
          ],
        ),
      ),
    );
  }
}
