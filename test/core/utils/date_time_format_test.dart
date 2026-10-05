import 'package:crs_ops/core/utils/date_time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateOnly', () {
    test('truncates a datetime to yyyy-MM-dd', () {
      expect(dateOnly(DateTime(2024, 6, 3, 15, 30, 45)), '2024-06-03');
    });

    test('midnight stays on the same date', () {
      expect(dateOnly(DateTime(2024, 6, 3)), '2024-06-03');
    });
  });
}
