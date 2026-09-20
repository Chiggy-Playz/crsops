import 'package:crs_ops/core/employees/repositories/event_type_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slugifyEventType', () {
    test('lowercases and trims', () {
      expect(slugifyEventType('  Warning  '), 'warning');
    });

    test('joins words with underscores', () {
      expect(slugifyEventType('Salary Revision'), 'salary_revision');
    });

    test('collapses separators and drops punctuation', () {
      expect(slugifyEventType('sick - leave!!'), 'sick_leave');
    });

    test('already-slug input passes through', () {
      expect(slugifyEventType('leave_sick'), 'leave_sick');
    });
  });
}
