import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = TtsService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الاستكشاف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'مسح السجل',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('مسح السجل؟'),
                  content: const Text('هل أنت متأكد من رغبتك في مسح جميع البيانات المسجلة؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<SettingsProvider>(context, listen: false).clearHistory();
                        Navigator.pop(context);
                        tts.speak("تم مسح السجل بنجاح.");
                      },
                      child: const Text('مسح', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.history.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد سجل حالياً',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: settings.history.length,
            itemBuilder: (context, index) {
              final item = settings.history[index];
              final DateTime date = DateTime.parse(item['timestamp']);
              final String formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(date);

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.button1,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item['type'],
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      item['result'],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  onTap: () {
                    tts.speak(item['result']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
