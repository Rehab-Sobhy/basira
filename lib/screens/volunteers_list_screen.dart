import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class VolunteersListScreen extends StatefulWidget {
  const VolunteersListScreen({super.key});

  @override
  State<VolunteersListScreen> createState() => _VolunteersListScreenState();
}

class _VolunteersListScreenState extends State<VolunteersListScreen> {
  final _supabaseService = SupabaseService();

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتطوعون المتاحون'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseService.streamActiveVolunteers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
          }

          final volunteers = snapshot.data ?? [];

          if (volunteers.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد متطوعون متاحون حالياً',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final volunteer = volunteers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 30,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  title: Text(
                    volunteer['name'] ?? 'متطوع',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'متاح للمساعدة',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.green, size: 40),
                    onPressed: () {
                      final phone = volunteer['phone_number'];
                      if (phone != null && phone.toString().isNotEmpty) {
                        _makePhoneCall(phone.toString());
                      }
                    },
                  ),
                  onTap: () {
                    final phone = volunteer['phone_number'];
                    if (phone != null && phone.toString().isNotEmpty) {
                      _makePhoneCall(phone.toString());
                    }
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
