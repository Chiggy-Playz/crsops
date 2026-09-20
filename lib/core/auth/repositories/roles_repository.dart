import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/app_session.dart';

/// One role per user from a set of role ids, superadmin > admin > employee.
/// Null only when there are no rows at all. Shared with AdminRepository's
/// fetchUserRoles so the precedence rule lives in exactly one place. Pure
/// so it stays unit testable without a Supabase client.
AppRole? highestRole(Iterable<String> roleIds) {
  final ids = roleIds.toSet();
  if (ids.isEmpty) return null;
  if (ids.contains(AppRole.superadmin.name)) return AppRole.superadmin;
  if (ids.contains(AppRole.admin.name)) return AppRole.admin;
  return AppRole.employee;
}

class RolesRepository {
  RolesRepository(this._client);
  final SupabaseClient _client;

  Future<AppRole?> fetchRole(String userId) async {
    try {
      final rows = await _client
          .schema('core')
          .from('user_roles')
          .select('role_id')
          .eq('user_id', userId);
      // superadmin > admin > employee if somehow more than one row exists
      return highestRole(rows.map((r) => r['role_id'] as String));
    } catch (error) {
      throw translateException(error);
    }
  }

  Future<Set<String>> fetchModuleAccess(String userId) async {
    try {
      final rows = await _client
          .schema('core')
          .from('module_access')
          .select('module_id')
          .eq('user_id', userId);
      return rows.map((r) => r['module_id'] as String).toSet();
    } catch (error) {
      throw translateException(error);
    }
  }
}
