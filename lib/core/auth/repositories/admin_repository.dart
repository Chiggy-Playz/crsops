import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/profile.dart';

/// Groups `module_access` rows by user id. Pure so the fold stays unit
/// tested without a Supabase client.
Map<String, Set<String>> groupModuleAccessByUser(
  List<Map<String, dynamic>> rows,
) {
  final byUser = <String, Set<String>>{};
  for (final r in rows) {
    byUser
        .putIfAbsent(r['user_id'] as String, () => {})
        .add(r['module_id'] as String);
  }
  return byUser;
}

abstract class AdminRepository {
  Future<List<({String email, String? note, DateTime addedAt})>>
  fetchAllowedEmails();
  Future<void> addAllowedEmail({required String email, String? note});
  Future<void> removeAllowedEmail(String email);

  Future<List<Profile>> fetchProfiles();

  /// Role id by user id. Users without a role are absent.
  Future<Map<String, String>> fetchUserRoles();

  /// Gives the user [roleId], replacing whatever role they had.
  Future<void> setRole({required String userId, required String roleId});

  Future<List<({String id, String name})>> fetchModules();
  Future<Map<String, Set<String>>> fetchModuleAccess();
  Future<void> grantModuleAccess({
    required String userId,
    required String moduleId,
  });
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<({String email, String? note, DateTime addedAt})>>
  fetchAllowedEmails() async {
    try {
      final rows = await _client
          .schema('core')
          .from('allowed_signup_emails')
          .select()
          .order('added_at', ascending: false);
      return rows
          .map(
            (r) => (
              email: r['email'] as String,
              note: r['note'] as String?,
              addedAt: DateTime.parse(r['added_at'] as String),
            ),
          )
          .toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> addAllowedEmail({required String email, String? note}) async {
    try {
      await _client.schema('core').from('allowed_signup_emails').insert({
        'email': email,
        'note': note,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> removeAllowedEmail(String email) async {
    try {
      await _client
          .schema('core')
          .from('allowed_signup_emails')
          .delete()
          .eq('email', email);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<Profile>> fetchProfiles() async {
    try {
      final rows = await _client
          .schema('core')
          .from('profiles')
          .select()
          .order('email', ascending: true);
      return rows.map(ProfileMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Map<String, String>> fetchUserRoles() async {
    try {
      final rows = await _client
          .schema('core')
          .from('user_roles')
          .select('user_id, role_id');
      return {
        for (final r in rows) r['user_id'] as String: r['role_id'] as String,
      };
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setRole({required String userId, required String roleId}) async {
    try {
      // user_id is the primary key, so this replaces any existing role.
      await _client.schema('core').from('user_roles').upsert({
        'user_id': userId,
        'role_id': roleId,
      }, onConflict: 'user_id');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<({String id, String name})>> fetchModules() async {
    try {
      final rows = await _client
          .schema('core')
          .from('modules')
          .select('id, name')
          .order('id', ascending: true);
      return rows
          .map((r) => (id: r['id'] as String, name: r['name'] as String))
          .toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Map<String, Set<String>>> fetchModuleAccess() async {
    try {
      final rows = await _client
          .schema('core')
          .from('module_access')
          .select('user_id, module_id');
      return groupModuleAccessByUser(rows);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> grantModuleAccess({
    required String userId,
    required String moduleId,
  }) async {
    try {
      await _client.schema('core').from('module_access').upsert({
        'user_id': userId,
        'module_id': moduleId,
      }, onConflict: 'user_id,module_id');
    } catch (error) {
      throw translateException(error);
    }
  }
}
