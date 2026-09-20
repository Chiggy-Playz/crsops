import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/app_session.dart';
import '../models/profile.dart';
import 'roles_repository.dart';

abstract class AdminRepository {
  Future<List<({String email, String? note, DateTime addedAt})>>
  fetchAllowedEmails();
  Future<void> addAllowedEmail({required String email, String? note});
  Future<void> removeAllowedEmail(String email);

  Future<List<Profile>> fetchProfiles();

  /// One role per user, using the shared superadmin > admin > employee
  /// precedence ([highestRole]), in case more than one row somehow exists
  /// for a user.
  Future<Map<String, String>> fetchUserRoles();
  Future<void> grantRole({required String userId, required String roleId});
  Future<void> revokeRole({required String userId, required String roleId});

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
          .order('email');
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
      final byUser = <String, Set<String>>{};
      for (final r in rows) {
        final userId = r['user_id'] as String;
        final roleId = r['role_id'] as String;
        byUser.putIfAbsent(userId, () => {}).add(roleId);
      }
      return {
        for (final entry in byUser.entries)
          entry.key: (highestRole(entry.value) ?? AppRole.employee).name,
      };
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> grantRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _client.schema('core').from('user_roles').upsert({
        'user_id': userId,
        'role_id': roleId,
      }, onConflict: 'user_id,role_id');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> revokeRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _client
          .schema('core')
          .from('user_roles')
          .delete()
          .eq('user_id', userId)
          .eq('role_id', roleId);
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
          .order('id');
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
      final byUser = <String, Set<String>>{};
      for (final r in rows) {
        final userId = r['user_id'] as String;
        final moduleId = r['module_id'] as String;
        byUser.putIfAbsent(userId, () => {}).add(moduleId);
      }
      return byUser;
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
