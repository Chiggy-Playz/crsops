import 'package:crs_ops/core/employees/models/employee_ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmployeeLedgerEntry round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '33333333-3333-3333-3333-333333333333',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'entry_date': '2024-02-01',
      'amount': 5000.0,
      'entry_type': 'advance',
      'note': 'urgent need',
      'created_by': null,
      'created_at': '2024-02-01T00:00:00.000Z',
    };

    final entry = EmployeeLedgerEntryMapper.fromMap(json);

    expect(entry.employeeId, '11111111-1111-1111-1111-111111111111');
    expect(entry.amount, 5000.0);
    expect(entry.entryType, 'advance');
    expect(entry.note, 'urgent need');
  });
}
