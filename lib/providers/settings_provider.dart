import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { gemini, openai, groq }

class SettingsProvider with ChangeNotifier {
  String _emergencyNumber = "122";
  String _volunteerNumber = "";
  String _apiKey = ""; // Gemini Key
  String _openaiKey = "";
  String _groqKey = "";

  AiProvider _aiProvider = AiProvider.groq;
  double _ttsRate = 0.5;
  double _ttsVolume = 1.0;
  List<Map<String, dynamic>> _history = [];
  bool _isFirstRun = true;

  String get emergencyNumber => _emergencyNumber;
  String get volunteerNumber => _volunteerNumber;
  String get apiKey => _apiKey;
  String get openaiKey => _openaiKey;
  String get groqKey => _groqKey;
  AiProvider get aiProvider => _aiProvider;
  double get ttsRate => _ttsRate;
  double get ttsVolume => _ttsVolume;
  List<Map<String, dynamic>> get history => _history;
  bool get isFirstRun => _isFirstRun;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyNumber = prefs.getString('emergencyNumber') ?? "122";
    _volunteerNumber = prefs.getString('volunteerNumber') ?? "";
    _apiKey = prefs.getString('apiKey') ?? "";

    String savedOpenaiKey = prefs.getString('openaiKey') ?? "";
    _openaiKey = savedOpenaiKey;

    _groqKey = prefs.getString('groqKey') ?? _groqKey;


    final providerIndex = prefs.getInt('aiProvider') ?? AiProvider.groq.index;
    _aiProvider = AiProvider.values[providerIndex];

    _ttsRate = prefs.getDouble('ttsRate') ?? 0.5;
    _ttsVolume = prefs.getDouble('ttsVolume') ?? 1.0;

    final historyString = prefs.getString('history') ?? '[]';
    final List<dynamic> decodedHistory = json.decode(historyString);
    _history = decodedHistory
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    _isFirstRun = prefs.getBool('isFirstRun') ?? true;

    notifyListeners();
  }

  Future<void> setEmergencyNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyNumber', number);
    _emergencyNumber = number;
    notifyListeners();
  }

  Future<void> setVolunteerNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('volunteerNumber', number);
    _volunteerNumber = number;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', key);
    _apiKey = key;
    notifyListeners();
  }

  Future<void> setOpenaiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openaiKey', key);
    _openaiKey = key;
    notifyListeners();
  }

  Future<void> setGroqKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groqKey', key);
    _groqKey = key;
    notifyListeners();
  }

  Future<void> setAiProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aiProvider', provider.index);
    _aiProvider = provider;
    notifyListeners();
  }

  Future<void> setTtsSettings(double rate, double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsRate', rate);
    await prefs.setDouble('ttsVolume', volume);
    _ttsRate = rate;
    _ttsVolume = volume;
    notifyListeners();
  }

  Future<void> addToHistory(String type, String result) async {
    final prefs = await SharedPreferences.getInstance();
    final newItem = {
      'type': type,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _history.insert(0, newItem); // Add to beginning
    if (_history.length > 50) _history.removeLast(); // Keep last 50

    await prefs.setString('history', json.encode(_history));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    _history = [];
    notifyListeners();
  }

  Future<void> completeFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    _isFirstRun = false;
    notifyListeners();
  }
}
