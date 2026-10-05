import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/profile.dart';
import '../repositories/admin_repository.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) =>
    SupabaseAdminRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<({String email, String? note, DateTime addedAt})>> allowedEmails(
  Ref ref,
) => ref.watch(adminRepositoryProvider).fetchAllowedEmails();

@riverpod
Future<List<Profile>> profiles(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchProfiles();

@riverpod
Future<Map<String, String>> userRoles(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchUserRoles();

@riverpod
Future<List<({String id, String name})>> modules(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchModules();

@riverpod
Future<Map<String, Set<String>>> moduleAccess(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchModuleAccess();
