import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clients/providers/client_providers.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../challan_search.dart';
import '../financial_year.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../models/challan_event.dart';
import '../pdf/challan_pdf.dart';
import '../repositories/challan_repository.dart';

part 'challan_providers.g.dart';

@Riverpod(keepAlive: true)
ChallanRepository challanRepository(Ref ref) =>
    SupabaseChallanRepository(ref.watch(supabaseClientProvider));

/// Goes up by one after any challan change; everything that shows challans
/// watches it, so one [ChallansRevision.bump] refreshes all of it. They also
/// watch the clients revision, since challans show client details.
@Riverpod(keepAlive: true)
class ChallansRevision extends _$ChallansRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Outward or Inward, as picked on the list. Kept while the app runs, so
/// coming back to the tab shows the same list.
@Riverpod(keepAlive: true)
class SelectedDirection extends _$SelectedDirection {
  @override
  ChallanDirection build() => ChallanDirection.outward;

  void select(ChallanDirection direction) => state = direction;
}

/// The list's challans: this financial year's and last year's, newest first,
/// so the list never starts empty on 1 April. Anything older is found with
/// the search page.
@riverpod
Future<List<Challan>> recentChallans(
  Ref ref,
  ChallanDirection direction,
) async {
  ref.watch(challansRevisionProvider);
  ref.watch(clientsRevisionProvider);
  final repo = ref.watch(challanRepositoryProvider);
  final thisYear = financialYearOf(DateTime.now());
  final lists = await Future.wait([
    repo.fetchList(direction, thisYear),
    repo.fetchList(direction, thisYear - 1),
  ]);
  return [...lists[0], ...lists[1]];
}

@riverpod
Future<Challan> challan(Ref ref, String challanId) {
  ref.watch(challansRevisionProvider);
  ref.watch(clientsRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchById(challanId);
}

@riverpod
Future<List<Challan>> clientChallans(Ref ref, String clientId) {
  ref.watch(challansRevisionProvider);
  ref.watch(clientsRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchForClient(clientId);
}

@riverpod
Future<List<ChallanEvent>> challanHistory(Ref ref, String challanId) {
  ref.watch(challansRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchHistory(challanId);
}

@riverpod
Future<List<String>> handledByNames(Ref ref) {
  ref.watch(challansRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchHandledByNames();
}

@riverpod
Future<List<String>> itemUnits(Ref ref) {
  ref.watch(challansRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchUnits();
}

/// Results for the search page; refreshed after any challan change.
@riverpod
Future<List<Challan>> challanSearch(Ref ref, ChallanSearchFilters filters) {
  ref.watch(challansRevisionProvider);
  ref.watch(clientsRevisionProvider);
  return ref.watch(challanRepositoryProvider).search(filters);
}

/// The PDF's font and CANCELLED stamp, loaded once.
@Riverpod(keepAlive: true)
Future<ChallanPdfAssets> challanPdfAssets(Ref ref) => ChallanPdfAssets.load();
