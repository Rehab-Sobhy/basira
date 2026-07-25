import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/tts_service.dart';
import '../core/theme.dart';

class ResultScreen extends StatefulWidget {
  final String resultText;

  const ResultScreen({super.key, required this.resultText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _readResult();
  }

  Future<void> _readResult() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _tts.speak(widget.resultText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النتيجة'),
      ),
      body: GestureDetector(
        onTap: _readResult,
        child: Semantics(
          label: "النتيجة: ${widget.resultText}. اضغط لإعادة السماع",
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.accent,
                          size: 100,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.resultText,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 30,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.volume_up, color: AppTheme.secondaryText),
                            const SizedBox(width: 10),
                            Text(
                              "اضغط لإعادة السماع",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
