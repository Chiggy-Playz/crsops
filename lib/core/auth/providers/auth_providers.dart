import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_client_provider.dart';
import '../models/app_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/roles_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
RolesRepository rolesRepository(Ref ref) => RolesRepository(ref.watch(supabaseClientProvider));

@riverpod
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

@riverpod
Future<AppSession?> session(Ref ref) async {
  final authState = await ref.watch(authStateChangesProvider.future);
  final user = authState.session?.user;
  if (user == null) return null;

  final rolesRepo = ref.watch(rolesRepositoryProvider);
  final role = await rolesRepo.fetchRole(user.id);
  final moduleAccess = await rolesRepo.fetchModuleAccess(user.id);

  return AppSession(
    userId: user.id,
    email: user.email ?? '',
    role: role,
    moduleAccess: moduleAccess,
  );
}
