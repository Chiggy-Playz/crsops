import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StatusType round-trips through JSON', () {
    final json = {
      'id': 'present',
      'label': 'Present',
      'icon_name': 'check',
      'color_hex': '#4CAF50',
      'description': null,
    };

    final status = StatusTypeMapper.fromMap(json);

    expect(status.id, 'present');
    expect(status.label, 'Present');
    expect(status.iconName, 'check');
  });

  group('inDisplayOrder', () {
    StatusType type(String id, String label) =>
        StatusType(id: id, label: label);

    test('puts built-ins in their fixed order, then custom types A-Z', () {
      final ordered = inDisplayOrder([
        type('week_off', 'Week Off'),
        type('work_from_home', 'Work from home'),
        type('absent', 'Absent'),
        type('comp_off', 'Comp off'),
        type('present', 'Present'),
        type('holiday', 'Holiday'),
        type('leave', 'Leave'),
      ]);

      expect(ordered.map((t) => t.id), [
        'present',
        'absent',
        'leave',
        'holiday',
        'week_off',
        'comp_off',
        'work_from_home',
      ]);
    });
  });
}
