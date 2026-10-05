import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/date_time_form_fields.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../models/employee.dart';
import '../providers/employee_providers.dart';

class EmployeeEditPage extends ConsumerStatefulWidget {
  const EmployeeEditPage({super.key, required this.existing});

  final Employee? existing;

  @override
  ConsumerState<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends ConsumerState<EmployeeEditPage> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _salaryController = TextEditingController(
    text: widget.existing?.salary?.toString() ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes ?? '',
  );
  // Colour is no longer shown or chosen anywhere; the column is NOT NULL, so
  // new employees get a fixed value and existing ones keep theirs.
  late final int _color = widget.existing?.color ?? 0xFF3F51B5;
  DateTime _joinDate = DateTime.now();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final employeeRepo = ref.read(employeeRepositoryProvider);
    final name = _nameController.text.trim();
    final salary = int.tryParse(_salaryController.text.trim());
    final notes = _notesController.text.trim();

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        if (_isEditing) {
          await employeeRepo.update(
            Employee(
              id: widget.existing!.id,
              userId: widget.existing!.userId,
              name: name,
              color: _color,
              salary: salary,
              notes: notes.isEmpty ? null : notes,
              createdAt: widget.existing!.createdAt,
              status: widget.existing!.status,
            ),
          );
        } else {
          await employeeRepo.create(
            name: name,
            color: _color,
            salary: salary,
            notes: notes.isEmpty ? null : notes,
            joinedOn: _joinDate,
          );
        }
      },
      onSuccess: () {
        if (_isEditing) {
          ref.invalidate(employeeListProvider);
          ref.invalidate(employeeProvider(widget.existing!.id));
        } else {
          // A new hire also changes who's on the attendance sheet.
          ref.read(employeeHistoryRevisionProvider.notifier).bump();
        }
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEditing ? 'Edit employee' : 'New employee',
      formKey: _formKey,
      saving: _saving,
      saveButtonKey: const Key('employee-save-button'),
      onSave: _save,
      children: [
        TextFormField(
          key: const Key('employee-name-field'),
          controller: _nameController,
          autofocus: !FormDialog.isCompact(context),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
        if (!_isEditing)
          DateFormField(
            fieldKey: const Key('employee-join-date-field'),
            label: 'Join date',
            value: _joinDate,
            onChanged: (d) => setState(() => _joinDate = d),
          ),
        TextFormField(
          controller: _salaryController,
          decoration: const InputDecoration(
            labelText: 'Salary (optional)',
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isNotEmpty && int.tryParse(text) == null) {
              return 'Enter whole rupees, like 25000';
            }
            return null;
          },
        ),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          minLines: 1,
          maxLines: 4,
        ),
      ],
    );
  }
}
