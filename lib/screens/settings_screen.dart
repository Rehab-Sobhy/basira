import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emergencyController = TextEditingController();
  final _volunteerController = TextEditingController();
  final _apiController = TextEditingController();
  final _openaiController = TextEditingController();
  final _groqController = TextEditingController();
  final _voiceService = VoiceService();

  bool _isListeningVolunteer = false;
  bool _isListeningEmergency = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _emergencyController.text = settings.emergencyNumber;
    _volunteerController.text = settings.volunteerNumber;
    _apiController.text = settings.apiKey;
    _openaiController.text = settings.openaiKey;
    _groqController.text = settings.groqKey;
  }

  Future<void> _toggleVoice(
    TextEditingController controller,
    bool isVolunteer,
  ) async {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
      setState(() {
        _isListeningVolunteer = false;
        _isListeningEmergency = false;
      });
      final digits = _voiceService.extractDigits(
        _voiceService.lastRecognizedWords,
      );
      if (digits.isNotEmpty) {
        controller.text = digits;
        // Trigger the provider update manually or rely on Save button
      }
      Vibration.vibrate(duration: 100);
    } else {
      if (!_voiceService.isAvailable) await _voiceService.init();
      setState(() {
        _isListeningVolunteer = isVolunteer;
        _isListeningEmergency = !isVolunteer;
      });
      Vibration.vibrate(duration: 100);
      _voiceService.startListening((text, isFinal) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    _volunteerController.dispose();
    _apiController.dispose();
    _openaiController.dispose();
    _groqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات (للمساعد)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هذه الشاشة مصممة ليتم استخدامها من قبل شخص مبصر لمساعدة الكفيف في إعداد التطبيق.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                const Text(
                  'أرقام التواصل:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _volunteerController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم هاتف المتطوع',
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListeningVolunteer ? Icons.stop : Icons.mic,
                        color: _isListeningVolunteer
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () => _toggleVoice(_volunteerController, true),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) => settings.setVolunteerNumber(val),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _emergencyController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم هاتف الطوارئ',
                    prefixIcon: const Icon(Icons.warning),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListeningEmergency ? Icons.stop : Icons.mic,
                        color: _isListeningEmergency
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () =>
                          _toggleVoice(_emergencyController, false),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) => settings.setEmergencyNumber(val),
                ),

                const SizedBox(height: 32),
                const Text(
                  'مزود الخدمة (AI Provider):',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Gemini'),
                      selected: settings.aiProvider == AiProvider.gemini,
                      onSelected: (val) =>
                          settings.setAiProvider(AiProvider.gemini),
                    ),
                    ChoiceChip(
                      label: const Text('OpenAI'),
                      selected: settings.aiProvider == AiProvider.openai,
                      onSelected: (val) =>
                          settings.setAiProvider(AiProvider.openai),
                    ),
                    ChoiceChip(
                      label: const Text('Groq (Llama)'),
                      selected: settings.aiProvider == AiProvider.groq,
                      onSelected: (val) =>
                          settings.setAiProvider(AiProvider.groq),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.aiProvider == AiProvider.gemini)
                  Column(
                    children: [
                      TextField(
                        controller: _apiController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Gemini API Key',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                          helperText: 'احصل عليه من aistudio.google.com',
                          helperStyle: TextStyle(color: Colors.white54),
                        ),
                        onChanged: (val) => settings.setApiKey(val),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('https://aistudio.google.com/app/apikey'),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('اضغط هنا للحصول على مفتاح Gemini'),
                      ),
                    ],
                  )
                else if (settings.aiProvider == AiProvider.openai)
                  Column(
                    children: [
                      TextField(
                        controller: _openaiController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'OpenAI API Key',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                          helperText: 'احصل عليه من platform.openai.com',
                          helperStyle: TextStyle(color: Colors.white54),
                        ),
                        onChanged: (val) => settings.setOpenaiKey(val),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('https://platform.openai.com/api-keys'),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('اضغط هنا للحصول على مفتاح OpenAI'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _groqController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Groq API Key',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                          helperText: 'احصل عليه من console.groq.com',
                          helperStyle: TextStyle(color: Colors.white54),
                        ),
                        onChanged: (val) => settings.setGroqKey(val),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('https://console.groq.com/keys'),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('اضغط هنا للحصول على مفتاح مجاني'),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
                const Text(
                  'إعدادات الصوت:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'سرعة النطق: ${settings.ttsRate.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Slider(
                  value: settings.ttsRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (val) {
                    settings.setTtsSettings(val, settings.ttsVolume);
                    TtsService().setSettings(rate: val);
                  },
                ),
                Text(
                  'مستوى الصوت: ${settings.ttsVolume.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Slider(
                  value: settings.ttsVolume,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (val) {
                    settings.setTtsSettings(settings.ttsRate, val);
                    TtsService().setSettings(volume: val);
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'إدارة البيانات:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    settings.clearHistory();
                    TtsService().speak("تم مسح السجل.");
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'مسح سجل الاستكشاف',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('حفظ ورجوع'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
