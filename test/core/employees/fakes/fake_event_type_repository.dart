import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/repositories/event_type_repository.dart';

class FakeEventTypeRepository implements EventTypeRepository {
  FakeEventTypeRepository({List<EventType>? seed}) : _types = List.of(seed ?? const []);

  final List<EventType> _types;

  @override
  Future<List<EventType>> fetchAll() async => List.of(_types);

  @override
  Future<EventType> addDescriptiveType(String id, {String? description}) async {
    final type = EventType(id: id, description: description);
    _types.add(type);
    return type;
  }

  @override
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    final index = _types.indexWhere((t) => t.id == id);
    final updated = EventType(
      id: _types[index].id,
      statusEffect: _types[index].statusEffect,
      iconName: iconName,
      colorHex: colorHex,
      description: _types[index].description,
    );
    _types[index] = updated;
    return updated;
  }
}
