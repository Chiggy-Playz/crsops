import 'package:crs_ops/core/employees/repositories/employee_ledger_entry_repository.dart';

class FakeEmployeeLedgerEntryRepository
    implements EmployeeLedgerEntryRepository {
  FakeEmployeeLedgerEntryRepository({List<String>? entryTypesSeed})
    : _entryTypes = List.of(
        entryTypesSeed ?? const ['advance', 'salary_payment'],
      );

  final List<String> _entryTypes;
  final List<Map<String, Object?>> addedEntries = [];

  @override
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    addedEntries.add({
      'employeeId': employeeId,
      'entryDate': entryDate,
      'amount': amount,
      'entryType': entryType,
      'note': note,
    });
    if (!_entryTypes.contains(entryType)) {
      _entryTypes
        ..add(entryType)
        ..sort();
    }
  }

  @override
  Future<List<String>> fetchDistinctEntryTypes() async => List.of(_entryTypes);

  final List<Map<String, Object?>> updatedEntries = [];
  final List<String> deletedIds = [];

  @override
  Future<void> updateEntry({
    required String id,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    updatedEntries.add({
      'id': id,
      'entryDate': entryDate,
      'amount': amount,
      'entryType': entryType,
      'note': note,
    });
  }

  @override
  Future<void> deleteEntry(String id) async {
    deletedIds.add(id);
  }
}
