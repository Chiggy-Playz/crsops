import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/client.dart';
import '../models/indian_state.dart';
import '../repositories/client_repository.dart';

part 'client_providers.g.dart';

@Riverpod(keepAlive: true)
ClientRepository clientRepository(Ref ref) =>
    SupabaseClientRepository(ref.watch(supabaseClientProvider));

/// Goes up by one after any change to a client or its addresses. The list,
/// each client, and anything a module shows about clients watch this, so one
/// [ClientsRevision.bump] refreshes all of it.
@Riverpod(keepAlive: true)
class ClientsRevision extends _$ClientsRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

@riverpod
Future<List<Client>> clientList(Ref ref) {
  ref.watch(clientsRevisionProvider);
  return ref.watch(clientRepositoryProvider).fetchAll();
}

@riverpod
Future<Client> client(Ref ref, String clientId) {
  ref.watch(clientsRevisionProvider);
  return ref.watch(clientRepositoryProvider).fetchById(clientId);
}

/// Seeded once by a migration and never edited, so fetched once per session.
@Riverpod(keepAlive: true)
Future<List<IndianState>> indianStates(Ref ref) =>
    ref.watch(clientRepositoryProvider).fetchStates();
