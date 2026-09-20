import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';

class EmployeeMarkingTile extends StatelessWidget {
  const EmployeeMarkingTile({super.key, required this.employee, required this.onQuickPresent});

  final Employee employee;
  final VoidCallback onQuickPresent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(employee.color)),
      title: Text(employee.name),
      trailing: FilledButton(
        key: Key('quick-present-${employee.id}'),
        onPressed: onQuickPresent,
        child: const Text('Present'),
      ),
    );
  }
}
