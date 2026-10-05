import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/app_session.dart';

/// The [AppRole] for a `core.roles` id. Unknown ids count as employee, the
/// least-privileged role. Pure so it stays unit testable without a Supabase
/// client.
AppRole roleFromId(String roleId) {
  for (final role in AppRole.values) {
    if (role.name == roleId) return role;
  }
  return AppRole.employee;
}

class RolesRepository {
  RolesRepository(this._client);
  final SupabaseClient _client;

  Future<AppRole?> fetchRole(String userId) async {
    try {
      final row = await _client
          .schema('core')
          .from('user_roles')
          .select('role_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return roleFromId(row['role_id'] as String);
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
