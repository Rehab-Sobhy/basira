import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  final FlutterTts flutterTts = FlutterTts();

  factory TtsService() {
    return _instance;
  }

  TtsService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA"); // Specific Saudi Arabic for more natural voice
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    // Attempt to set a more natural voice if available
    try {
      await flutterTts.setEngine("com.google.android.tts");
    } catch (_) {}
  }

  Future<void> setSettings({double? rate, double? volume, double? pitch}) async {
    if (rate != null) await flutterTts.setSpeechRate(rate);
    if (volume != null) await flutterTts.setVolume(volume);
    if (pitch != null) await flutterTts.setPitch(pitch);
  }

  Future<void> speak(String text) async {
    // Filter out common English technical terms that sound weird in Arabic TTS
    String cleanText = text
      .replaceAll("PostgrestException", "خطأ في الاتصال")
      .replaceAll("Exception", "خطأ")
      .replaceAll("Supabase", "سيرفر البيانات")
      .replaceAll("is_video", "الفيديو")
      .replaceAll("column", "خانة")
      .replaceAll("null", "غير موجود");

    await flutterTts.stop();
    await flutterTts.speak(cleanText);
  }


  Future<void> stop() async {
    await flutterTts.stop();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "صباح الخير.";
    } else if (hour < 17) {
      return "مساء الخير.";
    } else {
      return "مساء الخير، أتمنى أن يكون يومك هادئاً.";
    }
  }
}
