import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> userExists(String uid) async {
    final row =
        await _db.from('users').select('id').eq('id', uid).maybeSingle();
    return row != null;
  }

  Future<void> createUser(
    String uid, {
    required String name,
    String? phone,
    String? email,
    String? ville,
    String? pays,
    String? region,
    String? statutMarital,
    String? lieuResidence,
  }) async {
    await _db.from('users').upsert({
      'id': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'ville': ville,
      'pays': pays,
      'region': region,
      'statut_marital': statutMarital,
      'lieu_residence': lieuResidence,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final row = await _db.from('users').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return {
      ...Map<String, dynamic>.from(row),
      'statutMarital': row['statut_marital'],
      'lieuResidence': row['lieu_residence'],
    };
  }

  Future<String?> getName(String uid) async {
    final row =
        await _db.from('users').select('name').eq('id', uid).maybeSingle();
    return row?['name'] as String?;
  }

  Future<void> deleteUser(String uid) async {
    await _db.from('users').delete().eq('id', uid);
  }
}
