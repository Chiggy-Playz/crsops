import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/app_session.dart';

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
      if (rows.isEmpty) return null;
      // superadmin > admin > employee if somehow more than one row exists
      final roleIds = rows.map((r) => r['role_id'] as String).toSet();
      if (roleIds.contains('superadmin')) return AppRole.superadmin;
      if (roleIds.contains('admin')) return AppRole.admin;
      return AppRole.employee;
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
