import 'package:crs_ops/core/clients/gstin.dart';
import 'package:crs_ops/core/clients/repositories/client_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _clientRow(String id, String name) => {
  'id': id,
  'name': name,
  'notes': null,
  'archived_at': null,
  'created_at': '2026-10-06T10:00:00Z',
};

Map<String, dynamic> _addressRow(String clientId, String label) => {
  'address_id': '$clientId-$label',
  'client_id': clientId,
  'label': label,
  'archived_at': null,
  'created_at': '2026-10-06T10:00:00Z',
  'version_id': 'v-$clientId-$label',
  'version': 1,
  'name_on_challan': 'NAME',
  'address': 'ADDRESS',
  'state_code': '07',
  'state_name': 'Delhi',
  'gstin': null,
};

void main() {
  group('clientsWithAddresses', () {
    test('gives each client its own addresses, sorted by label', () {
      final clients = clientsWithAddresses(
        [_clientRow('a', 'Offshoot'), _clientRow('b', 'Vega')],
        [
          _addressRow('a', 'Sector 8'),
          _addressRow('b', 'Main'),
          _addressRow('a', 'sector 4'),
        ],
      );

      expect(clients.map((c) => c.name), ['Offshoot', 'Vega']);
      expect(clients[0].addresses.map((a) => a.label), [
        'sector 4',
        'Sector 8',
      ]);
      expect(clients[1].addresses.map((a) => a.label), ['Main']);
    });

    test('a client with no address rows gets an empty list', () {
      final clients = clientsWithAddresses([_clientRow('a', 'X')], const []);
      expect(clients.single.addresses, isEmpty);
    });
  });

  group('GSTIN', () {
    test('blank is allowed, and cleaned to null', () {
      expect(validateGstin('  '), isNull);
      expect(cleanGstin('  '), isNull);
    });

    test('spaces and case are tidied before checking', () {
      expect(cleanGstin(' 07aaccv3676j1zy '), '07AACCV3676J1ZY');
      expect(validateGstin(' 07aaccv3676j1zy '), isNull);
    });

    test('wrong length and wrong shape are rejected', () {
      expect(validateGstin('NOT AVAILABLE'), isNotNull);
      expect(validateGstin('FOHPS7819D'), isNotNull);
      expect(validateGstin('0AAACCV3676J1ZY'), isNotNull);
    });

    test('the state code is the first two digits', () {
      expect(gstinStateCode('06AAKCC8620K1ZF'), '06');
      expect(gstinStateCode('NA'), isNull);
    });
  });
}
