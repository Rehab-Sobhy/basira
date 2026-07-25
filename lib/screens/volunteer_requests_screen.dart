import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../services/video_call_service.dart';

class VolunteerRequestsScreen extends StatefulWidget {
  const VolunteerRequestsScreen({super.key});

  @override
  State<VolunteerRequestsScreen> createState() => _VolunteerRequestsScreenState();
}

class _VolunteerRequestsScreenState extends State<VolunteerRequestsScreen> {
  final _supabaseService = SupabaseService();
  final _videoCallService = VideoCallService();

  Future<void> _acceptAndCall(Map<String, dynamic> request) async {
    try {
      await _supabaseService.acceptRequest(request['id']);
      
      final isVideo = request['is_video'] == true;
      final phone = request['blind_phone_number'];

      if (isVideo) {
        // Unique room name using request ID
        final roomName = "basira_help_room_${request['id']}";
        await _videoCallService.joinRoom(
          roomName: roomName,
          userName: "Volunteer Helper",
        );
      } else if (phone != null && phone.toString().isNotEmpty) {
        final Uri launchUri = Uri(
          scheme: 'tel',
          path: phone.toString(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء قبول الطلب')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المساعدة'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseService.streamPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء تحميل الطلبات'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات مساعدة حالياً',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final isVideo = request['is_video'] == true;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isVideo ? Colors.blue : Colors.redAccent,
                    radius: 30,
                    child: Icon(isVideo ? Icons.video_call : Icons.emergency, color: Colors.white, size: 30),
                  ),
                  title: const Text(
                    'شخص يحتاج مساعدة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isVideo ? 'طلب مكالمة فيديو' : 'طلب مكالمة صوتية',
                    style: TextStyle(color: isVideo ? Colors.blue : Colors.orange, fontSize: 16),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _acceptAndCall(request),
                    child: Text(isVideo ? 'قبول وفيديو' : 'قبول واتصال', style: const TextStyle(color: Colors.white)),
                  ),
                  onTap: () => _acceptAndCall(request),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
