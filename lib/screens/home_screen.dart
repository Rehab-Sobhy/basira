import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../widgets/large_button.dart';
import 'package:nour/models/camera_mode.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'request_help_screen.dart';
import 'games_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _tts.setSettings(rate: settings.ttsRate, volume: settings.ttsVolume);

      _tts.speak(
        "أهلاً بك في تطبيق نُور. "
        "لدينا خدمات: استكشاف الأشياء، قراءة النصوص، التعرف على العملات، كاشف الألوان، واختيار الملابس. "
        "كما يمكنك طلب مساعدة من متطوع، أو الاتصال بالطوارئ، أو تجربة لعبة الأصوات الجديدة. "
        "طريقة الاستخدام: اضغط مرة واحدة على أي زر لسماع اسمه، واضغط مرتين متتاليتين لفتح الخدمة.",
      );
    });
  }

  Future<void> _handleEmergency() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(
        pattern: [500, 1000, 500, 1000],
        intensities: [1, 255, 1, 255],
      );
    }

    try {
      await _tts.speak("جاري بدء إجراءات الطوارئ.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      String locationLink = "موقعي غير متاح حالياً";
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        locationLink =
            "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      }

      final String emergencyNo = settings.emergencyNumber;
      final String message =
          "تنبيه طوارئ من تطبيق نور! أنا بحاجة للمساعدة العاجلة. موقعي: $locationLink";

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: emergencyNo,
        queryParameters: <String, String>{'body': message},
      );

      _tts.speak("جاري إرسال موقعك والاتصال برقم الطوارئ.");

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        final Uri telUri = Uri.parse("tel:$emergencyNo");
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          _tts.speak("عذراً، لا يمكنني الاتصال بالطوارئ حالياً.");
        }
      }
    } catch (e) {
      debugPrint("Emergency Error: $e");
      await _tts.speak("حدث خطأ أثناء إجراء الطوارئ.");
    }
  }

  Future<void> _callVolunteer() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RequestHelpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نور'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LargeButton(
              text: 'استكشاف الأشياء',
              color: AppTheme.button1,
              icon: Icons.camera_alt,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CameraScreen(mode: CameraMode.general),
                ),
              ),
            ),
            LargeButton(
              text: 'قراءة النصوص',
              color: const Color(0xFF673AB7),
              icon: Icons.text_snippet,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CameraScreen(mode: CameraMode.text),
                ),
              ),
            ),
            LargeButton(
              text: 'التعرف على العملات',
              color: const Color(0xFF009688),
              icon: Icons.payments,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CameraScreen(mode: CameraMode.currency),
                ),
              ),
            ),
            LargeButton(
              text: 'كاشف الألوان',
              color: const Color(0xFFFF9800),
              icon: Icons.palette,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CameraScreen(mode: CameraMode.color),
                ),
              ),
            ),
            LargeButton(
              text: 'اختيار اللبس',
              color: AppTheme.button2,
              icon: Icons.checkroom,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CameraScreen(mode: CameraMode.outfit),
                ),
              ),
            ),
            LargeButton(
              text: 'طلب مساعدة',
              color: AppTheme.button3,
              icon: Icons.support_agent,
              onDoubleTap: _callVolunteer,
            ),
            LargeButton(
              text: 'لعبة الأصوات',
              color: Colors.purple,
              icon: Icons.games,
              onDoubleTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GamesMenuScreen(),
                ),
              ),
            ),
            LargeButton(
              text: 'الطوارئ',
              color: AppTheme.emergencyButton,
              icon: Icons.warning_rounded,
              onDoubleTap: _handleEmergency,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
