import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/repositories/status_type_repository.dart';

class FakeStatusTypeRepository implements StatusTypeRepository {
  FakeStatusTypeRepository({List<StatusType>? seed}) : _types = List.of(seed ?? const []);

  final List<StatusType> _types;

  @override
  Future<List<StatusType>> fetchAll() async => List.of(_types);

  @override
  Future<StatusType> add({
    required String id,
    required String label,
    String? iconName,
    String? colorHex,
  }) async {
    final type = StatusType(id: id, label: label, iconName: iconName, colorHex: colorHex);
    _types.add(type);
    return type;
  }

  @override
  Future<StatusType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    final index = _types.indexWhere((t) => t.id == id);
    final updated = StatusType(
      id: _types[index].id,
      label: _types[index].label,
      iconName: iconName,
      colorHex: colorHex,
      description: _types[index].description,
    );
    _types[index] = updated;
    return updated;
  }
}
