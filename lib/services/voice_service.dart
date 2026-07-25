import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';



class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      _isAvailable = await _speech.initialize(

        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
        debugLogging: true,
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('STT Init Exception: $e');
      return false;
    }
  }

  void startListening(Function(String, bool) onResult, {
    Function(String)? onError,
    String localeId = 'ar-SA',
    bool partialResults = true,
  }) {
    if (_isAvailable) {
      _speech.listen(
        onResult: (result) {
          if (partialResults || result.finalResult) {
            onResult(result.recognizedWords, result.finalResult);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: partialResults,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          localeId: localeId,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } else {
      if (onError != null) onError("Microphone not available");
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Extracts only digits from a string, converting Arabic words and numerals.
  String extractDigits(String text) {
    if (text.isEmpty) return "";

    String result = text.toLowerCase();

    // Map Arabic words to digits
    final arabicWords = {
      'صفر': '0',
      'زيرو': '0',
      'واحد': '1',
      'اثنان': '2',
      'اثنين': '2',
      'ثلاثة': '3',
      'اربعة': '4',
      'أربعة': '4',
      'خمسة': '5',
      'ستة': '6',
      'سبعة': '7',
      'ثمانية': '8',
      'تسعة': '9',
    };


    // Map English words to digits
    final englishWords = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
    };

    // Replace words with digits
    arabicWords.forEach((word, digit) {
      result = result.replaceAll(word, digit);
    });
    englishWords.forEach((word, digit) {
      result = result.replaceAll(word, digit);
    });

    // Handle Arabic numerals
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }

    // Remove everything except digits
    return result.replaceAll(RegExp(r'[^\d]'), '');
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;
  String get lastRecognizedWords => _speech.lastRecognizedWords;
}

