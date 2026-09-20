import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isStructural is true only when statusEffect is set', () {
    const joined = EventType(id: 'joined', statusEffect: 'active', iconName: 'check', colorHex: '#4CAF50');
    const promotion = EventType(id: 'promotion', description: 'Promoted to senior role');

    expect(joined.isStructural, isTrue);
    expect(promotion.isStructural, isFalse);
  });

  test('round-trips through JSON with all fields null except id', () {
    final json = {
      'id': 'promotion',
      'status_effect': null,
      'icon_name': null,
      'color_hex': null,
      'description': null,
    };

    final eventType = EventTypeMapper.fromMap(json);

    expect(eventType.id, 'promotion');
    expect(eventType.statusEffect, isNull);
  });
}
