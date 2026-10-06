import 'package:flutter/material.dart';

import '../../../widgets/form_dialog.dart';
import '../../../widgets/section_header.dart';
import '../../models/employee.dart';
import '../../../widgets/initials_avatar.dart';

/// Multi-select employee picker (e.g. the Reports filter): search, active
/// employees first, then a dimmed Inactive group — they still matter for past
/// date ranges. Full-screen on phones, a dialog on wide windows (FormDialog).
///
/// Resolves to the chosen ids (empty = everyone), or null if dismissed.
Future<Set<String>?> showEmployeeMultiPicker(
  BuildContext context, {
  required List<Employee> employees,
  required Set<String> initialSelection,
}) => showFormDialog<Set<String>>(
  context: context,
  builder: (_) => _EmployeeMultiPicker(
    employees: employees,
    initialSelection: initialSelection,
  ),
);

class _EmployeeMultiPicker extends StatefulWidget {
  const _EmployeeMultiPicker({
    required this.employees,
    required this.initialSelection,
  });

  final List<Employee> employees;
  final Set<String> initialSelection;

  @override
  State<_EmployeeMultiPicker> createState() => _EmployeeMultiPickerState();
}

class _EmployeeMultiPickerState extends State<_EmployeeMultiPicker> {
  final _formKey = GlobalKey<FormState>();
  late final Set<String> _selection = Set.of(widget.initialSelection);
  String _query = '';

  void _toggle(String id, bool selected) => setState(() {
    if (selected) {
      _selection.add(id);
    } else {
      _selection.remove(id);
    }
  });

  @override
  Widget build(BuildContext context) {
    final matching = widget.employees
        .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final active = matching.where((e) => !e.isInactive).toList();
    final inactive = matching.where((e) => e.isInactive).toList();

    final String description;
    if (_selection.isEmpty) {
      description = 'Showing everyone';
    } else {
      description = '${_selection.length} selected';
    }

    return FormDialog(
      title: 'Filter by employee',
      description: description,
      formKey: _formKey,
      saving: false,
      saveLabel: 'Apply',
      onSave: () => Navigator.of(context).pop(_selection),
      children: [
        TextField(
          autofocus: !FormDialog.isCompact(context),
          decoration: const InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        // One child, so the rows aren't spaced like separate form fields.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              title: const Text('All employees'),
              value: _selection.isEmpty,
              onChanged: (_) => setState(_selection.clear),
            ),
            const Divider(height: 1),
            for (final e in active) _row(e, inactive: false),
            if (inactive.isNotEmpty) ...[
              const SectionHeader('Inactive', topPadding: 16),
              for (final e in inactive) _row(e, inactive: true),
            ],
            if (matching.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No employees match your search'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _row(Employee e, {required bool inactive}) {
    final dimmedText = inactive
        ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
        : null;
    return CheckboxListTile(
      secondary: InitialsAvatar(name: e.name, dimmed: inactive),
      title: Text(e.name, style: dimmedText),
      value: _selection.contains(e.id),
      onChanged: (checked) => _toggle(e.id, checked ?? false),
    );
  }
}
