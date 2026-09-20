import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';

/// Employee multi-select dialog for the reports filter. Returns the chosen
/// id set (empty means "all"), or null when dismissed via Cancel.
Future<Set<String>?> showEmployeePicker(
  BuildContext context, {
  required List<Employee> employees,
  required Set<String> initialSelection,
}) {
  var query = '';
  var selection = Set<String>.of(initialSelection);

  return showDialog<Set<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final filtered = employees
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return AlertDialog(
          title: const Text('Filter by employee'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setDialogState(() => query = value),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('All employees'),
                        value: selection.isEmpty,
                        onChanged: (_) => setDialogState(() => selection = {}),
                      ),
                      const Divider(height: 1),
                      for (final e in filtered)
                        CheckboxListTile(
                          title: Text(e.name),
                          value: selection.contains(e.id),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selection.add(e.id);
                            } else {
                              selection.remove(e.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selection),
              child: const Text('Done'),
            ),
          ],
        );
      },
    ),
  );
}
