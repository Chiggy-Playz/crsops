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

/// The financial year the list shows; starts at the current one.
@Riverpod(keepAlive: true)
class SelectedFinancialYear extends _$SelectedFinancialYear {
  @override
  int build() => financialYearOf(DateTime.now());

  void select(int year) => state = year;
}

@riverpod
Future<List<Challan>> challanList(
  Ref ref,
  ChallanDirection direction,
  int year,
) {
  ref.watch(challansRevisionProvider);
  ref.watch(clientsRevisionProvider);
  return ref.watch(challanRepositoryProvider).fetchList(direction, year);
}

/// The years to offer in the list's year picker: those with challans, plus
/// the current one (which may have none yet), newest first.
@riverpod
Future<List<int>> financialYears(Ref ref, ChallanDirection direction) async {
  ref.watch(challansRevisionProvider);
  final years = await ref
      .watch(challanRepositoryProvider)
      .fetchFinancialYears(direction);
  final current = financialYearOf(DateTime.now());
  return {current, ...years}.toList()..sort((a, b) => b.compareTo(a));
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
