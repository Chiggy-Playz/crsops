import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/employees/providers/employee_providers.dart';
import '../providers/attendance_providers.dart';
import 'widgets/employee_marking_tile.dart';

class AttendanceDayPage extends ConsumerWidget {
  const AttendanceDayPage({super.key, required this.date});

  final DateTime date;

  Future<void> _markAllPresent(BuildContext context, WidgetRef ref, List<String> employeeIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('mark-all-present-confirm-dialog'),
        title: const Text('Mark all present?'),
        content: const Text('This overwrites any existing marking for this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(attendanceRepositoryProvider).markAllPresent(date: date, employeeIds: employeeIds);
    }
  }

  Future<void> _markHoliday(BuildContext context, WidgetRef ref, List<String> employeeIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('mark-holiday-confirm-dialog'),
        title: const Text('Mark day as company holiday?'),
        content: const Text('This overwrites any existing marking for this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(attendanceRepositoryProvider).markHoliday(date: date, employeeIds: employeeIds);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(date.toIso8601String().split('T').first)),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employees) {
          final ids = employees.map((e) => e.id).toList();
          if (employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('mark-all-present-button'),
                        onPressed: () => _markAllPresent(context, ref, ids),
                        child: const Text('Mark all present'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('mark-holiday-button'),
                        onPressed: () => _markHoliday(context, ref, ids),
                        child: const Text('Mark day as company holiday'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return EmployeeMarkingTile(
                      employee: employee,
                      onQuickPresent: () => ref.read(attendanceRepositoryProvider).markDay(
                            employeeId: employee.id,
                            date: date,
                            firstHalfStatus: 'present',
                            secondHalfStatus: 'present',
                          ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
