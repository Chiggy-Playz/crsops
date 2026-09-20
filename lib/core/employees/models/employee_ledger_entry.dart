import 'package:dart_mappable/dart_mappable.dart';

part 'employee_ledger_entry.mapper.dart';

@MappableClass()
class EmployeeLedgerEntry with EmployeeLedgerEntryMappable {
  const EmployeeLedgerEntry({
    this.id,
    required this.employeeId,
    required this.entryDate,
    required this.amount,
    required this.entryType,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  @MappableField(key: 'id')
  final String? id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'entry_date')
  final DateTime entryDate;
  @MappableField(key: 'amount')
  final double amount;
  @MappableField(key: 'entry_type')
  final String entryType;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'created_by')
  final String? createdBy;
  @MappableField(key: 'created_at')
  final DateTime? createdAt;
}
