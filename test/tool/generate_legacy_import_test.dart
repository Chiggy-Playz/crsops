import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_legacy_import.dart';

void main() {
  group('correctAttendanceDate', () {
    test('adds 5:30 to recover the IST calendar date', () {
      expect(
        correctAttendanceDate('2024-12-31T18:30:00.000Z'),
        DateTime.utc(2025, 1, 1),
      );
    });
  });

  group('assertKeyDateMatches', () {
    test('passes when the doc key agrees with the corrected date', () {
      expect(
        () => assertKeyDateMatches(
          '1-1-2025-Ha1ewjlJG0NNtjZBeq3t',
          'Ha1ewjlJG0NNtjZBeq3t',
          DateTime.utc(2025, 1, 1),
        ),
        returnsNormally,
      );
    });

    test('throws when the doc key disagrees with the corrected date', () {
      expect(
        () => assertKeyDateMatches(
          '1-10-2025-At9udibSIegWWpAoKk8I',
          'At9udibSIegWWpAoKk8I',
          DateTime.utc(2025, 1, 10), // wrong: key is day=1,month=10
        ),
        throwsFormatException,
      );
    });
  });

  group('mapSalary', () {
    test('maps 0 to null (never recorded, not a real ₹0 salary)', () {
      expect(mapSalary(0), isNull);
    });

    test('passes a real salary through unchanged', () {
      expect(mapSalary(14000), 14000);
    });
  });

  group('sqlEscapeName', () {
    test('trims leading and trailing whitespace', () {
      expect(
        sqlEscapeName('Pranjal Delivery ref apna website advertisement '),
        'Pranjal Delivery ref apna website advertisement',
      );
    });

    test('doubles embedded single quotes', () {
      expect(sqlEscapeName("O'Brien"), "O''Brien");
    });
  });

  group('statusesFor', () {
    test('maps present/absent/holiday 1:1, unflagged', () {
      expect(statusesFor('present'), ('present', 'present', false));
      expect(statusesFor('absent'), ('absent', 'absent', false));
      expect(statusesFor('holiday'), ('holiday', 'holiday', false));
    });

    test('maps halfDay to a flagged present/absent default', () {
      expect(statusesFor('halfDay'), ('present', 'absent', true));
    });

    test('rejects an unrecognized status', () {
      expect(() => statusesFor('onLeave'), throwsFormatException);
    });
  });

  group('deriveEvents', () {
    test(
      'disabled:false employee gets joined only, dated at the first record',
      () {
        final events = deriveEvents(
          attendanceDates: [
            DateTime.utc(2025, 3, 1),
            DateTime.utc(2025, 1, 1),
            DateTime.utc(2025, 2, 1),
          ],
          disabled: false,
        );
        expect(events.joined, DateTime.utc(2025, 1, 1));
        expect(events.left, isNull);
      },
    );

    test('disabled:true employee also gets left, dated at the last record', () {
      final events = deriveEvents(
        attendanceDates: [DateTime.utc(2025, 1, 1), DateTime.utc(2025, 3, 1)],
        disabled: true,
      );
      expect(events.joined, DateTime.utc(2025, 1, 1));
      expect(events.left, DateTime.utc(2025, 3, 1));
    });

    test('throws when there is no attendance to derive a join date from', () {
      expect(
        () => deriveEvents(attendanceDates: [], disabled: false),
        throwsStateError,
      );
    });
  });

  group('generateUuidV4', () {
    test('produces a well-formed, version-4/variant-10 UUID', () {
      final uuid = generateUuidV4(Random(0));
      expect(
        uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });

  group('formatDate', () {
    test('zero-pads month and day', () {
      expect(formatDate(DateTime.utc(2025, 1, 9)), '2025-01-09');
    });
  });
}
