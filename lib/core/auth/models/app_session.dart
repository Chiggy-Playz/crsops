import 'package:dart_mappable/dart_mappable.dart';

part 'app_session.mapper.dart';

@MappableEnum()
enum AppRole { superadmin, admin, employee }

@MappableClass()
class AppSession with AppSessionMappable {
  const AppSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.moduleAccess,
  });

  final String userId;
  final String email;
  final AppRole? role;
  final Set<String> moduleAccess;

  bool get isSuperadmin => role == AppRole.superadmin;
  bool get isAdminOrAbove => role == AppRole.superadmin || role == AppRole.admin;

  bool hasModuleAccess(String moduleId) => isAdminOrAbove || moduleAccess.contains(moduleId);
}
