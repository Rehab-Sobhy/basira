import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../services/vision_service.dart';
import '../core/theme.dart';
import '../models/camera_mode.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraMode mode;

  const CameraScreen({super.key, required this.mode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isReady = false;
  bool _isProcessing = false;
  final TtsService _tts = TtsService();
  final VoiceService _voice = VoiceService();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initVoice();
    _tts.speak("تم فتح الكاميرا. اضغط مرتين أو قل صور للالتقاط.");
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      }
    } catch (e) {
      _tts.speak("حدث خطأ في فتح الكاميرا.");
    }
  }

  Future<void> _initVoice() async {
    bool available = await _voice.init();
    if (available) {
      _voice.startListening((text, isFinal) {
        if (text.toLowerCase().contains('صور') || text.toLowerCase().contains('التقط') || text.toLowerCase().contains('صورة')) {
          _takePicture();
        }
      });
    } else {
      debugPrint("Voice not available in CameraScreen");
    }
  }

  @override
  void dispose() {
    _voice.stopListening();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isReady || _isProcessing) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool hasKey = settings.aiProvider == AiProvider.gemini 
        ? (settings.apiKey.isNotEmpty && settings.apiKey != "YOUR_API_KEY") 
        : (settings.aiProvider == AiProvider.openai 
            ? settings.openaiKey.isNotEmpty 
            : settings.groqKey.isNotEmpty);


    if (!hasKey) {
      await _tts.speak("يرجى إدخال مفتاح الـ API في الإعدادات أولاً.");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(duration: 100);
    }
    await _tts.speak("جاري تحليل الصورة حياً. يرجى الانتظار ثواني.");

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      
      final visionService = VisionService(
        apiKey: settings.apiKey,
        openaiKey: settings.openaiKey,
        groqKey: settings.groqKey,
        provider: settings.aiProvider,
      );
      final String resultText = await visionService.analyzeImage(imageBytes, widget.mode);

      String typeLabel = "";
      switch (widget.mode) {
        case CameraMode.general: typeLabel = "استكشاف"; break;
        case CameraMode.outfit: typeLabel = "لبس"; break;
        case CameraMode.text: typeLabel = "نص"; break;
        case CameraMode.currency: typeLabel = "عملة"; break;
        case CameraMode.color: typeLabel = "لون"; break;
      }

      if (mounted) {
        Provider.of<SettingsProvider>(context, listen: false).addToHistory(typeLabel, resultText);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(resultText: resultText),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _tts.speak("فشل التحليل. تأكد من الاتصال بالإنترنت ومفتاح الـ API.");
    }
  }

  String _getAppBarTitle() {
    switch (widget.mode) {
      case CameraMode.general: return "استكشاف الأشياء";
      case CameraMode.outfit: return "اختيار اللبس";
      case CameraMode.text: return "قراءة النصوص";
      case CameraMode.currency: return "التعرف على العملات";
      case CameraMode.color: return "كاشف الألوان";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text("تحميل الكاميرا")),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: GestureDetector(
        onDoubleTap: _takePicture,
        onTap: () {
          _tts.speak("اضغط مرتين لالتقاط الصورة");
        },
        child: Semantics(
          label: "شاشة الكاميرا. اضغط مرتين لالتقاط الصورة",
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          "جاري تحليل الصورة...",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
