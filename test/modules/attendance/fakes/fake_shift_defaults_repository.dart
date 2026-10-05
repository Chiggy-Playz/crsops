import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:crs_ops/modules/attendance/repositories/shift_defaults_repository.dart';

class FakeShiftDefaultsRepository implements ShiftDefaultsRepository {
  FakeShiftDefaultsRepository({List<ShiftDefaults>? seed})
    : _history = List.of(
        seed ??
            [
              ShiftDefaults(
                id: 'seed-1',
                effectiveFrom: DateTime(2000, 1, 1),
                defaultStart: '10:30:00',
                defaultEnd: '18:30:00',
                weekOffDays: const [7],
              ),
            ],
      );

  final List<ShiftDefaults> _history;

  @override
  Future<List<ShiftDefaults>> fetchHistory() async => List.of(_history);

  @override
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  }) async {
    final entry = ShiftDefaults(
      id: 'fake-${_history.length + 1}',
      effectiveFrom: effectiveFrom,
      defaultStart: defaultStart,
      defaultEnd: defaultEnd,
      weekOffDays: weekOffDays,
    );
    _history.insert(0, entry);
    return entry;
  }
}
