import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/guarded_save.dart';
import '../providers/attendance_providers.dart';

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
        onPressed: () => showFormDialog<void>(
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
  final _formKey = GlobalKey<FormState>();

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving) return;
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
    return FormDialog(
      title: 'New shift default',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        DateFormField(
          label: 'Effective from',
          value: _effectiveFrom,
          format: _dateFormat.format,
          onChanged: (d) => setState(() => _effectiveFrom = d),
        ),
        TimeFormField(
          label: 'Start time',
          value: _start,
          onChanged: (t) => setState(() => _start = t),
        ),
        TimeFormField(
          label: 'End time',
          value: _end,
          onChanged: (t) => setState(() => _end = t),
        ),
        LabelledFieldBox(
          label: 'Week off days',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
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
        ),
      ],
    );
  }
}
