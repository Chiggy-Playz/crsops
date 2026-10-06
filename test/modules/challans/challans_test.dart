import 'package:crs_ops/modules/challans/challan_search.dart';
import 'package:crs_ops/modules/challans/financial_year.dart';
import 'package:crs_ops/modules/challans/history_text.dart';
import 'package:crs_ops/modules/challans/models/challan.dart';
import 'package:crs_ops/modules/challans/models/challan_direction.dart';
import 'package:crs_ops/modules/challans/models/challan_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_challan_repository.dart';

/// A row as `challans.challan_overview` returns it.
Map<String, dynamic> _overviewRow({
  int number = 12,
  int itemCount = 3,
  int addressVersion = 1,
  int latestAddressVersion = 1,
}) => {
  'id': 'c1',
  'direction': 'outward',
  'financial_year': 2026,
  'number': number,
  'challan_date': '2026-10-06',
  'handled_by_name': 'RAMESH',
  'handled_by_employee_id': null,
  'vehicle_number': 'DL1C1234',
  'declared_value': 50000,
  'notes': null,
  'bill_number': null,
  'received_on': null,
  'digitally_signed': false,
  'cancelled_at': null,
  'cancel_reason': null,
  'created_at': '2026-10-06T10:00:00+00:00',
  'updated_at': '2026-10-06T10:00:00+00:00',
  'client_id': 'k1',
  'client_name': 'Vega Corporate',
  'address_id': 'a1',
  'address_label': 'Main',
  'address_version_id': 'v1',
  'address_version': addressVersion,
  'latest_address_version': latestAddressVersion,
  'name_on_challan': 'VEGA CORPORATE PVT LTD',
  'address': 'Sector 8\nNoida',
  'state_code': '09',
  'state_name': 'Uttar Pradesh',
  'gstin': null,
  'item_count': itemCount,
  'total_quantity': 5,
  'first_item': 'DELL LAPTOP',
  'reverses_challan_id': null,
  'reverses_number': null,
  'reverses_financial_year': null,
  'returned_by_challan_id': null,
  'returned_by_number': null,
  'returned_by_financial_year': null,
};

ChallanEvent _event(
  String type,
  Map<String, dynamic> changes, {
  String? note,
}) => ChallanEvent(
  id: 1,
  challanId: 'c1',
  eventType: type,
  changes: changes,
  note: note,
  createdAt: DateTime.utc(2026, 10, 6),
);

void main() {
  group('financial year', () {
    test('April starts a new year; March belongs to the one before', () {
      expect(financialYearOf(DateTime(2026, 4, 1)), 2026);
      expect(financialYearOf(DateTime(2027, 3, 31)), 2026);
      expect(financialYearOf(DateTime(2026, 1, 15)), 2025);
    });

    test('labels', () {
      expect(financialYearLabel(2026), '2026-27');
      expect(financialYearLabel(2099), '2099-00');
      expect(challanNumberLabel(12, 2026), '12 / 2026-27');
    });
  });

  group('Challan from the overview view', () {
    test('reads every column', () {
      final challan = ChallanMapper.fromMap(_overviewRow());
      expect(challan.direction, ChallanDirection.outward);
      expect(challan.numberLabel, '12 / 2026-27');
      expect(challan.challanDate, DateTime(2026, 10, 6));
      expect(challan.items, isEmpty);
      expect(challan.hasNewerAddress, isFalse);
    });

    test('notices the address was edited since', () {
      final challan = ChallanMapper.fromMap(
        _overviewRow(addressVersion: 1, latestAddressVersion: 2),
      );
      expect(challan.hasNewerAddress, isTrue);
    });

    test('summarises the items', () {
      expect(
        ChallanMapper.fromMap(_overviewRow()).itemsSummary,
        'DELL LAPTOP and 2 more',
      );
      expect(
        ChallanMapper.fromMap(_overviewRow(itemCount: 1)).itemsSummary,
        'DELL LAPTOP',
      );
    });
  });

  group('describeChallanEvent', () {
    test('an edit lists what changed', () {
      final text = describeChallanEvent(
        _event('edited', {
          'handled_by_name': {'from': 'RAMESH', 'to': 'SURESH'},
          'items': {
            'from': [{}, {}],
            'to': [{}, {}, {}],
          },
        }),
        ChallanDirection.outward,
      );
      expect(text.title, 'Edited');
      expect(text.details, [
        'Delivered by: RAMESH → SURESH',
        'Items: 2 → 3 lines',
      ]);
    });

    test('a cancel shows the reason and the return challan', () {
      final text = describeChallanEvent(
        _event('cancelled', {'return_number': 4}, note: 'Wrong client'),
        ChallanDirection.outward,
      );
      expect(text.details, [
        'Reason: Wrong client',
        'Goods brought back on inward challan 4',
      ]);
    });

    test('follow-ups read as sentences', () {
      expect(
        describeChallanEvent(
          _event('received', {
            'received_on': {'from': null, 'to': '2026-10-08'},
          }),
          ChallanDirection.outward,
        ).title,
        'Signed copy received on 8 Oct 2026',
      );
      expect(
        describeChallanEvent(
          _event('bill_number', {
            'bill_number': {'from': 'B1', 'to': null},
          }),
          ChallanDirection.outward,
        ).title,
        'Bill number removed',
      );
    });
  });

  group('search', () {
    test('groups by client name, keeping each client\'s order', () {
      final groups = groupByClient([
        fakeChallan(id: 'a', number: 9, clientId: 'v', clientName: 'vega'),
        fakeChallan(id: 'b', number: 8, clientId: 'o', clientName: 'Offshoot'),
        fakeChallan(id: 'c', number: 7, clientId: 'v', clientName: 'vega'),
      ]);
      expect(groups.map((g) => g.clientName), ['Offshoot', 'vega']);
      expect(groups[1].challans.map((c) => c.number), [9, 7]);
    });

    test('filters with only whitespace count as empty', () {
      expect(const ChallanSearchFilters(text: '  ').isEmpty, isTrue);
      expect(ChallanSearchFilters(from: DateTime(2026)).isEmpty, isFalse);
    });

    test('equal filters are equal, so results are cached', () {
      expect(
        const ChallanSearchFilters(text: 'x', clientIds: ['a']),
        const ChallanSearchFilters(text: 'x', clientIds: ['a']),
      );
    });
  });
}
