import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/attendance_providers.dart';
import '../../../core/widgets/guarded_save.dart';

const _kWeekdayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

String _weekOffLabel(List<int> days) {
  if (days.isEmpty) return 'None';
  return days.map((d) => _kWeekdayNames[d] ?? '?').join(', ');
}

final _dateFormat = DateFormat('d MMM yyyy');

class ShiftDefaultsManagerPage extends ConsumerWidget {
  const ShiftDefaultsManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftDefaultsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift defaults')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (history) => ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            return ListTile(
              isThreeLine: true,
              title: Text('${entry.defaultStart} – ${entry.defaultEnd}'),
              subtitle: Text(
                'Effective from ${_dateFormat.format(entry.effectiveFrom)}\n'
                'Week off: ${_weekOffLabel(entry.weekOffDays)}',
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const _AddShiftDefaultDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddShiftDefaultDialog extends ConsumerStatefulWidget {
  const _AddShiftDefaultDialog();

  @override
  ConsumerState<_AddShiftDefaultDialog> createState() =>
      _AddShiftDefaultDialogState();
}

class _AddShiftDefaultDialogState
    extends ConsumerState<_AddShiftDefaultDialog> {
  DateTime _effectiveFrom = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 30);
  final Set<int> _weekOffDays = {7};
  bool _saving = false;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(shiftDefaultsRepositoryProvider)
          .addEffectiveFrom(
            effectiveFrom: _effectiveFrom,
            defaultStart: _fmt(_start),
            defaultEnd: _fmt(_end),
            weekOffDays: _weekOffDays.toList()..sort(),
          ),
      onSuccess: () {
        ref.invalidate(shiftDefaultsHistoryProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New shift default'),
      content: SizedBox(
        width: 300,
        // Scrollable: the date/time/chips stack overflows short screens
        // (and the test window) otherwise.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Effective from',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _effectiveFrom,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _effectiveFrom = picked);
                  },
                  child: Text(_dateFormat.format(_effectiveFrom)),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _start,
                    );
                    if (picked != null) setState(() => _start = picked);
                  },
                  child: Text(_start.format(context)),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _end,
                    );
                    if (picked != null) setState(() => _end = picked);
                  },
                  child: Text(_end.format(context)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Week off days'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in _kWeekdayNames.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _weekOffDays.contains(entry.key),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _weekOffDays.add(entry.key);
                        } else {
                          _weekOffDays.remove(entry.key);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
