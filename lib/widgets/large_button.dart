import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';

import 'package:animate_do/animate_do.dart';

class LargeButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onDoubleTap;
  final IconData icon;

  const LargeButton({
    super.key,
    required this.text,
    required this.color,
    required this.onDoubleTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: SizedBox(
          height: 160,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                bool hasVibrator = await Vibration.hasVibrator();
                if (hasVibrator) {
                  Vibration.vibrate(duration: 50);
                }
                final tts = TtsService();
                await tts.speak(text);
              },
              onDoubleTap: () async {
                bool hasVibrator = await Vibration.hasVibrator();
                if (hasVibrator) {
                  Vibration.vibrate(duration: 100);
                }
                onDoubleTap();
              },
              borderRadius: BorderRadius.circular(28.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Semantics(
                  label: text,
                  hint: "اضغط مرتين للتنفيذ",
                  button: true,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 26,
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}
