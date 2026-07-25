import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'volunteer_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _requestPermissions() async {
    // Request all permissions upfront so a sighted helper can allow them.
    await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ].request();
  }

  Future<void> _startApp() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Request permissions before doing anything
    await _requestPermissions();

    // Read the welcome text
    await Future.delayed(const Duration(milliseconds: 800));

    String greeting = _tts.getGreeting();
    if (settings.isFirstRun) {
      await _tts.speak(
        "$greeting أهلاً بك في نور، أنا مساعدك الذكي. سأساعدك في رؤية العالم من حولك. يمكنك لمس الشاشة مرتين دائماً للتحدث معي.",
      );
      await settings.completeFirstRun();
    } else {
      await _tts.speak("$greeting أهلاً بك مجدداً في نور.");
    }

    // Wait a bit, then navigate based on role
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      final roleProvider = Provider.of<UserRoleProvider>(
        context,
        listen: false,
      );

      Widget nextScreen;
      if (roleProvider.role == UserRole.unselected) {
        nextScreen = const RoleSelectionScreen();
      } else if (roleProvider.role == UserRole.volunteer) {
        nextScreen = const VolunteerMainScreen();
      } else {
        nextScreen = const HomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 150, color: Colors.white),
            const SizedBox(height: 32),
            Text('نور', style: Theme.of(context).textTheme.displayLarge),
          ],
        ),
      ),
    );
  }
}
