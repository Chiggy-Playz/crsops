import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../providers/employee_providers.dart';
import 'widgets/employee_color_picker.dart';

final _dateFormat = DateFormat('d MMM yyyy');

class EmployeeEditPage extends ConsumerStatefulWidget {
  const EmployeeEditPage({super.key, required this.existing});

  final Employee? existing;

  @override
  ConsumerState<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends ConsumerState<EmployeeEditPage> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _salaryController =
      TextEditingController(text: widget.existing?.salary?.toString() ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  late int _color = widget.existing?.color ?? employeeColorPalette.first;
  DateTime _joinDate = DateTime.now();

  bool get _isEditing => widget.existing != null;

  Future<void> _save() async {
    final employeeRepo = ref.read(employeeRepositoryProvider);
    final salary = double.tryParse(_salaryController.text);

    if (_isEditing) {
      await employeeRepo.update(
        Employee(
          id: widget.existing!.id,
          userId: widget.existing!.userId,
          name: _nameController.text,
          color: _color,
          salary: salary,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: widget.existing!.createdAt,
        ),
      );
    } else {
      final created = await employeeRepo.create(
        name: _nameController.text,
        color: _color,
        salary: salary,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      await ref.read(employeeEventRepositoryProvider).addEvent(
            employeeId: created.id,
            eventType: 'joined',
            eventDate: _joinDate,
          );
    }

    ref.invalidate(employeeListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit employee' : 'New employee')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('employee-name-field'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          EmployeeColorPicker(selectedColor: _color, onChanged: (c) => setState(() => _color = c)),
          const SizedBox(height: 16),
          if (!_isEditing) ...[
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Join date', suffixIcon: Icon(Icons.calendar_month)),
              child: InkWell(
                key: const Key('employee-join-date-field'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joinDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _joinDate = picked);
                },
                child: Text(_dateFormat.format(_joinDate)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _salaryController,
            decoration: const InputDecoration(labelText: 'Salary (optional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('employee-save-button'),
            onPressed: _nameController.text.trim().isEmpty ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
