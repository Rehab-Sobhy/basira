import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/camera_mode.dart';
import '../providers/settings_provider.dart';
import 'ml_kit_service.dart';

class VisionService {
  final String apiKey;
  final String openaiKey;
  final String groqKey;
  final AiProvider provider;
  late final GenerativeModel _geminiModel;

  VisionService({
    required this.apiKey,
    required this.openaiKey,
    required this.groqKey,
    required this.provider,
  }) {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> analyzeImage(Uint8List imageBytes, CameraMode mode) async {
    switch (provider) {
      case AiProvider.gemini:
        return _analyzeWithGemini(imageBytes, mode);
      case AiProvider.openai:
        return _analyzeWithOpenAi(imageBytes, mode);
      case AiProvider.groq:
        return _analyzeWithGroq(imageBytes, mode);
    }
  }

  String _getPrompt(CameraMode mode) {
    switch (mode) {
      case CameraMode.general:
        return "صف لي بالضبط ماذا يوجد أمامي باللغة العربية بأسلوب بسيط ودقيق لمساعدة شخص كفيف.";
      case CameraMode.text:
        return "استخرج واقرأ كل النصوص الموجودة في هذه الصورة باللغة العربية.";
      case CameraMode.currency:
        return "حدد قيمة ونوع العملة الموجودة في هذه الصورة (مثلاً: خمسون جنيهاً مصرياً).";
      case CameraMode.color:
        return "حدد الألوان الغالبة في هذه الصورة بوضوح باللغة العربية.";
      case CameraMode.outfit:
        return "أنت خبير في الموضة وتنسيق الملابس. صف كل قطعة من الملابس في هذه الصورة بالتفصيل (النوع، اللون، النقشة). ثم أعطني رأياً صريحاً ومهنياً: هل الألوان متناسقة مع بعضها البعض؟ وهل الطقم مناسب للخروج لمناسبة رسمية أم كاجوال؟ رد باللغة العربية بأسلوب ودود وواضح لمساعدة شخص كفيف.";

    }
  }

  Future<String> _analyzeWithGemini(Uint8List imageBytes, CameraMode mode) async {
    if (apiKey.isEmpty || apiKey == "YOUR_API_KEY") {
      return "يرجى إعداد مفتاح Gemini في الإعدادات.";
    }

    try {
      final prompt = _getPrompt(mode);
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _geminiModel.generateContent(content);
      return response.text ?? "عذراً، لم أتمكن من الحصول على وصف.";
    } catch (e) {
      return "خطأ Gemini: ${e.toString()}";
    }
  }

  Future<String> _analyzeWithOpenAi(Uint8List imageBytes, CameraMode mode) async {
    if (openaiKey.isEmpty) {
      return "يرجى إعداد مفتاح OpenAI في الإعدادات.";
    }
    return _callOpenAiCompatible(
      url: 'https://api.openai.com/v1/chat/completions',
      key: openaiKey,
      model: 'gpt-4o',
      imageBytes: imageBytes,
      mode: mode,
    );
  }

  Future<String> _analyzeWithGroq(Uint8List imageBytes, CameraMode mode) async {
    if (groqKey.isEmpty) {
      return "يرجى إعداد مفتاح Groq في الإعدادات.";
    }

    // تحليل الصورة محلياً أولاً باستخدام ML Kit
    final localData = await MLKitService.analyzeImageLocally(imageBytes);

    return _callOpenAiCompatible(
      url: 'https://api.groq.com/openai/v1/chat/completions',
      key: groqKey,
      model: 'meta-llama/llama-4-scout-17b-16e-instruct',
      imageBytes: imageBytes,
      mode: mode,
      localData: localData,
    );
  }

  Future<String> _callOpenAiCompatible({
    required String url,
    required String key,
    required String model,
    required Uint8List imageBytes,
    required CameraMode mode,
    String? localData,
  }) async {
    try {
      String prompt = _getPrompt(mode);
      if (localData != null && localData.isNotEmpty) {
        prompt += "\n\nمعلومات إضافية تم استخراجها محلياً من الصورة لمساعدتك (استخدمها لزيادة الدقة):\n$localData";
      }
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            }
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return "خطأ من المزود (${response.statusCode}): ${error['error']['message']}";
      }
    } catch (e) {
      return "فشل الاتصال بالمزود: ${e.toString()}";
    }
  }
}
