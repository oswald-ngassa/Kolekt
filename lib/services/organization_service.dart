import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models.dart';

class OrganizationService {
  SupabaseClient get _client => Supabase.instance.client;
  dynamic _organizationChannel;

  void watchOrganizations(Future<void> Function() onChange) {
    if (_organizationChannel != null) return;
    _organizationChannel = _client
        .channel('public:organizations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'organizations',
          callback: (_) async => onChange(),
        )
        .subscribe();
  }

  Future<void> stopWatchingOrganizations() async {
    final channel = _organizationChannel;
    if (channel == null) return;
    _organizationChannel = null;
    await _client.removeChannel(channel);
  }

  Future<List<Organization>> loadMine() async {
    final rows =
        await _client.from('organizations').select().order('created_at');
    final userId = _client.auth.currentUser?.id;
    final memberships = userId == null
        ? <dynamic>[]
        : await _client
            .from('organization_members')
            .select('organization_id, role')
            .eq('user_id', userId);
    final roles = {
      for (final membership in memberships)
        membership['organization_id'] as String:
            membership['role'] as String? ?? 'Membre',
    };
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final snapshotValue = data['snapshot'];
      final snapshot = snapshotValue is Map
          ? Map<String, dynamic>.from(snapshotValue)
          : <String, dynamic>{};
      snapshot['id'] = data['id'];
      snapshot['join_code'] = data['join_code'];
      snapshot['owner_id'] = data['owner_id'];
      snapshot['current_user_role'] = data['owner_id'] == userId
          ? 'Propriétaire / Administrateur'
          : roles[data['id']] ?? 'Membre';
      return Organization.fromJson(snapshot);
    }).toList();
  }

  Future<void> save(Organization organization) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Connexion requise.');
    if (organization.ownerId == null || organization.ownerId == user.id) {
      organization.ownerId = user.id;
      organization.currentUserRole = 'Propriétaire / Administrateur';
    }
    final values = <String, dynamic>{
      'id': organization.id,
      'owner_id': organization.ownerId,
      'name': organization.name,
      'snapshot': organization.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (organization.joinCode != null) {
      values['join_code'] = organization.joinCode;
    }
    final row = await _client
        .from('organizations')
        .upsert(values)
        .select('join_code')
        .single();
    organization.joinCode = row['join_code'] as String?;
  }

  Future<String> joinByCode(String code) async {
    final result = await _client.rpc(
      'join_organization_by_code',
      params: {'target_join_code': code.trim().toUpperCase()},
    );
    if (result is! Map || result['organization_id'] is! String) {
      throw const AuthException('La réponse du serveur est invalide.');
    }
    return result['organization_id'] as String;
  }

  Future<void> deleteAllOwnedByCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('organizations').delete().eq('owner_id', user.id);
  }

  Future<void> deleteOrganization(String organizationId) async {
    await _client.from('organizations').delete().eq('id', organizationId);
  }

  Future<void> leaveOrganization(String organizationId) async {
    await _client.rpc(
      'leave_organization',
      params: {'target_organization_id': organizationId},
    );
  }

  Future<void> deleteCurrentAccount() async {
    await _client.rpc('delete_current_user');
  }
}
