import 'package:crs_ops/modules/challans/challan_search.dart';
import 'package:crs_ops/modules/challans/models/challan.dart';
import 'package:crs_ops/modules/challans/models/challan_direction.dart';
import 'package:crs_ops/modules/challans/models/challan_event.dart';
import 'package:crs_ops/modules/challans/models/challan_item.dart';
import 'package:crs_ops/modules/challans/repositories/challan_repository.dart';

/// A challan for tests, dated [date] (default today) with one item.
Challan fakeChallan({
  required String id,
  required int number,
  ChallanDirection direction = ChallanDirection.outward,
  String clientId = 'client-1',
  String clientName = 'Vega Corporate',
  DateTime? date,
  int addressVersion = 1,
  int latestAddressVersion = 1,
  String firstItem = 'DELL LAPTOP',
  DateTime? receivedOn,
}) {
  final now = DateTime.now();
  final challanDate = date ?? DateTime(now.year, now.month, now.day);
  return Challan(
    id: id,
    direction: direction,
    financialYear: challanDate.month < 4
        ? challanDate.year - 1
        : challanDate.year,
    number: number,
    challanDate: challanDate,
    handledByName: 'RAMESH',
    receivedOn: receivedOn,
    digitallySigned: false,
    createdAt: challanDate,
    updatedAt: challanDate,
    clientId: clientId,
    clientName: clientName,
    addressId: '$clientId-a1',
    addressLabel: 'Main',
    addressVersion: addressVersion,
    latestAddressVersion: latestAddressVersion,
    nameOnChallan: clientName.toUpperCase(),
    address: 'Sector 8, Noida',
    stateCode: '07',
    stateName: 'Delhi',
    itemCount: 1,
    totalQuantity: 2,
    firstItem: firstItem,
    items: [ChallanItem(description: firstItem, quantity: 2)],
  );
}

/// In-memory challans that record what the app asked for.
class FakeChallanRepository implements ChallanRepository {
  FakeChallanRepository({List<Challan>? seed})
    : _challans = List.of(seed ?? const []);

  final List<Challan> _challans;

  final List<ChallanDraft> created = [];
  final Map<String, ChallanDraft> updated = {};
  final List<({String id, String? reason, bool createReturn})> cancelled = [];
  final Map<String, bool> signed = {};
  final List<ChallanSearchFilters> searches = [];

  @override
  Future<List<Challan>> fetchList(ChallanDirection direction, int year) async =>
      _challans
          .where((c) => c.direction == direction && c.financialYear == year)
          .toList()
        ..sort((a, b) => b.number.compareTo(a.number));

  @override
  Future<Challan> fetchById(String id) async =>
      _challans.firstWhere((c) => c.id == id);

  @override
  Future<List<Challan>> fetchForClient(String clientId) async =>
      _challans.where((c) => c.clientId == clientId).toList();

  @override
  Future<List<ChallanEvent>> fetchHistory(String challanId) async => [
    ChallanEvent(
      id: 1,
      challanId: challanId,
      eventType: 'created',
      createdAt: DateTime(2026, 10, 6, 10),
      createdByEmail: 'boss@x.com',
    ),
  ];

  @override
  Future<List<Challan>> search(ChallanSearchFilters filters) async {
    searches.add(filters);
    final text = filters.text.toLowerCase();
    return _challans
        .where(
          (c) =>
              text.isEmpty ||
              c.clientName.toLowerCase().contains(text) ||
              (c.firstItem ?? '').toLowerCase().contains(text),
        )
        .toList();
  }

  @override
  Future<List<Challan>> withItems(List<Challan> challans) async => [
    for (final c in challans) _challans.firstWhere((s) => s.id == c.id),
  ];

  @override
  Future<List<String>> fetchHandledByNames() async => ['RAMESH', 'SURESH'];

  @override
  Future<List<String>> fetchUnits() async => ['SET', 'NOS'];

  @override
  Future<String> create(ChallanDraft draft) async {
    created.add(draft);
    final id = 'new-${created.length}';
    _challans.add(
      fakeChallan(
        id: id,
        number: 100 + created.length,
        direction: draft.direction,
        date: draft.challanDate,
      ),
    );
    return id;
  }

  @override
  Future<void> update(String id, ChallanDraft draft) async {
    updated[id] = draft;
  }

  @override
  Future<String?> cancel(
    String id, {
    String? reason,
    required bool createReturn,
  }) async {
    cancelled.add((id: id, reason: reason, createReturn: createReturn));
    final index = _challans.indexWhere((c) => c.id == id);
    _challans[index] = _challans[index].copyWith(
      cancelledAt: DateTime(2026),
      cancelReason: reason,
    );
    return createReturn ? 'return-1' : null;
  }

  @override
  Future<void> setReceived(String id, DateTime? receivedOn) async {
    final index = _challans.indexWhere((c) => c.id == id);
    _challans[index] = _challans[index].copyWith(receivedOn: receivedOn);
  }

  @override
  Future<void> setBillNumber(String id, String? billNumber) async {
    final index = _challans.indexWhere((c) => c.id == id);
    _challans[index] = _challans[index].copyWith(billNumber: billNumber);
  }

  @override
  Future<void> setDigitallySigned(String id, {required bool signed}) async {
    this.signed[id] = signed;
    final index = _challans.indexWhere((c) => c.id == id);
    _challans[index] = _challans[index].copyWith(digitallySigned: signed);
  }
}
