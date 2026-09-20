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
}
