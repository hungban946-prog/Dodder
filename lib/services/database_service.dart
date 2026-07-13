import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> createCouple({
    required String user1Id,
    required String code,
  }) async {
    await _client.from('couples').insert({
      'user1_id': user1Id,
      'invite_code': code,
      'status': 'pending',
    });
  }

  static Future<void> joinCouple({
    required String user2Id,
    required String code,
  }) async {
    final existing = await _client
        .from('couples')
        .select()
        .eq('invite_code', code)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing == null) {
      throw Exception('Mã không tồn tại hoặc đã được sử dụng');
    }

    await _client.from('couples').update({
      'user2_id': user2Id,
      'status': 'connected',
    }).eq('id', existing['id']);
  }
}