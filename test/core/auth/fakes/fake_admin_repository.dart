import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:crs_ops/core/auth/repositories/admin_repository.dart';

/// Configurable AdminRepository double: seeded reads plus recorded writes,
/// so manager-page tests assert behavior without Supabase.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    List<Profile> profiles = const [],
    Map<String, String> roles = const {},
    List<({String id, String name})> modules = const [],
    Map<String, Set<String>> access = const {},
    List<({String email, String? note, DateTime addedAt})> emails = const [],
  }) : _profiles = List.of(profiles),
       _roles = Map.of(roles),
       _modules = List.of(modules),
       _access = {for (final e in access.entries) e.key: Set.of(e.value)},
       _emails = List.of(emails);

  final List<Profile> _profiles;
  final Map<String, String> _roles;
  final List<({String id, String name})> _modules;
  final Map<String, Set<String>> _access;
  final List<({String email, String? note, DateTime addedAt})> _emails;

  final List<({String userId, String roleId})> setRoles = [];
  final List<({String userId, String moduleId})> grantedAccess = [];
  final List<String> addedEmails = [];
  final List<String> removedEmails = [];

  @override
  Future<List<({String email, String? note, DateTime addedAt})>>
  fetchAllowedEmails() async => List.of(_emails);

  @override
  Future<void> addAllowedEmail({required String email, String? note}) async {
    addedEmails.add(email);
    _emails.add((email: email, note: note, addedAt: DateTime(2024)));
  }

  @override
  Future<void> removeAllowedEmail(String email) async {
    removedEmails.add(email);
    _emails.removeWhere((e) => e.email == email);
  }

  @override
  Future<List<Profile>> fetchProfiles() async => List.of(_profiles);

  @override
  Future<Map<String, String>> fetchUserRoles() async => Map.of(_roles);

  @override
  Future<void> setRole({required String userId, required String roleId}) async {
    setRoles.add((userId: userId, roleId: roleId));
    _roles[userId] = roleId;
  }

  @override
  Future<List<({String id, String name})>> fetchModules() async =>
      List.of(_modules);

  @override
  Future<Map<String, Set<String>>> fetchModuleAccess() async => {
    for (final e in _access.entries) e.key: Set.of(e.value),
  };

  @override
  Future<void> grantModuleAccess({
    required String userId,
    required String moduleId,
  }) async {
    grantedAccess.add((userId: userId, moduleId: moduleId));
    _access.putIfAbsent(userId, () => {}).add(moduleId);
  }
}
