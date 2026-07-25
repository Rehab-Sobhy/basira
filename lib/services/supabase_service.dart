import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> ensureLoggedIn() async {
    if (!isInitialized) return;
    await signInAnonymously();
  }

  Future<void> signInAnonymously() async {
    if (!isInitialized) return;
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        await _client.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
    }
  }

  Future<void> updateVolunteerProfile({
    required String name,
    required String phone,
    required bool isActive,
  }) async {
    if (!isInitialized) throw Exception('Supabase غير متصل');
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }
      
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('المستخدم غير مسجل الدخول');

      await _client.from('volunteers').upsert({
        'id': currentUserId,
        'name': name,
        'phone_number': phone,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating volunteer profile: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamActiveVolunteers() {
    if (!isInitialized) return const Stream.empty();
    return _client
        .from('volunteers')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('updated_at', ascending: false);
  }

  Future<void> createHelpRequest(String phoneNumber, {bool isVideo = false}) async {
    if (!isInitialized) throw Exception('Supabase غير متصل');
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        await signInAnonymously();
      }

      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('المستخدم غير مسجل الدخول');

      await _client.from('help_requests').insert({
        'blind_user_id': currentUserId,
        'blind_phone_number': phoneNumber,
        'status': 'pending',
        'is_video': isVideo,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating help request: $e');
      rethrow;
    }
  }


  Stream<List<Map<String, dynamic>>> streamPendingRequests() {
    if (!isInitialized) return const Stream.empty();
    return _client
        .from('help_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> acceptRequest(int requestId) async {
    if (!isInitialized) throw Exception('Supabase غير متصل');
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _client.from('help_requests').update({
        'status': 'accepted',
        'volunteer_id': currentUserId,
      }).eq('id', requestId);
    } catch (e) {
      debugPrint('Error accepting request: $e');
      rethrow;
    }
  }

  /// Stream the blind user's own latest request to track status changes
  Stream<List<Map<String, dynamic>>> streamMyRequests() {
    if (!isInitialized) return const Stream.empty();
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();
    return _client
        .from('help_requests')
        .stream(primaryKey: ['id'])
        .eq('blind_user_id', currentUserId)
        .order('created_at', ascending: false);
  }
}
