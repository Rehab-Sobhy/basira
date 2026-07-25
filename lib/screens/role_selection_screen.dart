import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_role_provider.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';
import 'volunteer_main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _speakIntro();
  }

  Future<void> _speakIntro() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _tts.speak(
      "أهلاً بك في نور. يرجى اختيار دورك. اضغط في النصف العلوي إذا كنت محتاجاً للمساعدة، أو في النصف السفلي إذا كنت متطوعاً.",
    );
  }

  void _selectRole(BuildContext context, UserRole role) async {
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    await roleProvider.setRole(role);

    if (!context.mounted) return;

    if (role == UserRole.blind) {
      await _tts.speak("تم اختيار محتاج مساعدة.");
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      await _tts.speak("تم اختيار متطوع.");
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VolunteerMainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Semantics(
              label: 'أحتاج مساعدة - كفيف أو ضعيف بصر',
              hint: 'اضغط مرتين للاختيار',
              button: true,
              child: InkWell(
                onTap: () {
                  _tts.speak(
                    'أحتاج مساعدة - كفيف أو ضعيف بصر. اضغط مرتين للاختيار.',
                  );
                },
                onDoubleTap: () => _selectRole(context, UserRole.blind),
                child: Container(
                  width: double.infinity,
                  color: Colors.blue.shade900,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.accessibility_new,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'أحتاج مساعدة\n(كفيف / ضعيف بصر)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'أريد المساعدة - متطوع',
              hint: 'اضغط مرتين للاختيار',
              button: true,
              child: InkWell(
                onTap: () {
                  _tts.speak('أريد المساعدة - متطوع. اضغط مرتين للاختيار.');
                },
                onDoubleTap: () => _selectRole(context, UserRole.volunteer),
                child: Container(
                  width: double.infinity,
                  color: Colors.teal.shade700,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'أريد المساعدة\n(متطوع)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
