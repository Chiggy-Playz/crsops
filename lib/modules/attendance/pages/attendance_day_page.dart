import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/employees/models/employee.dart';
import '../../../core/employees/providers/employee_providers.dart';
import '../providers/attendance_providers.dart';
import 'widgets/employee_marking_tile.dart';

final _titleFormat = DateFormat('d MMM yyyy');

class AttendanceDayPage extends ConsumerStatefulWidget {
  const AttendanceDayPage({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<AttendanceDayPage> createState() => _AttendanceDayPageState();
}

class _AttendanceDayPageState extends ConsumerState<AttendanceDayPage> {
  final Set<String> _busyEmployeeIds = {};

  // Invalidates every cached instance of this family, not just this page's
  // own single-day query — otherwise the Calendar page's separately-cached
  // month-range query stays stale until something else forces a refetch
  // (e.g. swiping months), so a freshly-marked day's color never shows up
  // on going back. recentGapsProvider is a completely separate query (the
  // Calendar's yellow gap-warning marker) — marking a day doesn't change
  // effective_range_status's cache staleness, it changes recent_gaps' too.
  void _refresh() {
    ref.invalidate(effectiveRangeStatusProvider);
    ref.invalidate(recentGapsProvider);
  }

  Future<void> _markAllPresent(List<String> employeeIds) async {
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
      await ref.read(attendanceRepositoryProvider).markAllPresent(date: widget.date, employeeIds: employeeIds);
      _refresh();
    }
  }

  Future<void> _markHoliday(List<String> employeeIds) async {
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
      await ref.read(attendanceRepositoryProvider).markHoliday(date: widget.date, employeeIds: employeeIds);
      _refresh();
    }
  }

  Future<void> _markStatus(String employeeId, StatusPick pick) async {
    setState(() => _busyEmployeeIds.add(employeeId));
    try {
      await ref.read(attendanceRepositoryProvider).markDay(
            employeeId: employeeId,
            date: widget.date,
            firstHalfStatus: pick.statusId,
            secondHalfStatus: pick.statusId,
            note: pick.note,
          );
      _refresh();
    } finally {
      if (mounted) setState(() => _busyEmployeeIds.remove(employeeId));
    }
  }

  Future<void> _unmark(String employeeId) async {
    setState(() => _busyEmployeeIds.add(employeeId));
    try {
      await ref.read(attendanceRepositoryProvider).unmarkDay(employeeId: employeeId, date: widget.date);
      _refresh();
    } finally {
      if (mounted) setState(() => _busyEmployeeIds.remove(employeeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final statusAsync = ref.watch(effectiveRangeStatusProvider(start: widget.date, end: widget.date));
    final statusTypesAsync = ref.watch(statusTypesProvider);

    // `effectiveRangeStatusProvider` already excludes employees who weren't
    // active on `widget.date` (per core.employee_status_as_of) — the row set
    // it returns, not the full employee list, is what decides who belongs on
    // this page. An employee joining next week must not show up as
    // "unmarked" on a day before they existed.
    final activeEmployeeIds = statusAsync.value?.map((s) => s.employeeId).toSet();
    final employeesById = {for (final e in employeesAsync.value ?? const []) e.id: e};
    final activeEmployees = activeEmployeeIds == null
        ? null
        : <Employee>[for (final id in activeEmployeeIds) if (employeesById[id] != null) employeesById[id]!];

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance on ${_titleFormat.format(widget.date)}'),
        actions: [
          IconButton(
            key: const Key('mark-holiday-button'),
            icon: const Icon(Icons.beach_access_outlined),
            tooltip: 'Mark day as company holiday',
            onPressed: activeEmployees == null || activeEmployees.isEmpty
                ? null
                : () => _markHoliday(activeEmployees.map((e) => e.id).toList()),
          ),
        ],
      ),
      body: employeesAsync.isLoading || statusAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : employeesAsync.hasError
              ? Center(child: Text('${employeesAsync.error}'))
              : statusAsync.hasError
                  ? Center(child: Text('${statusAsync.error}'))
                  : activeEmployees == null || activeEmployees.isEmpty
                      ? const Center(child: Text('No active employees for this date'))
                      : Builder(
                          builder: (context) {
                            final statusByEmployeeId = {for (final s in statusAsync.value!) s.employeeId: s};
                            return ListView.builder(
                              itemCount: activeEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = activeEmployees[index];
                                return EmployeeMarkingTile(
                                  employee: employee,
                                  status: statusByEmployeeId[employee.id],
                                  statusTypes: statusTypesAsync.value ?? const [],
                                  busy: _busyEmployeeIds.contains(employee.id),
                                  onMarkStatus: (pick) => _markStatus(employee.id, pick),
                                  onUnmark: () => _unmark(employee.id),
                                );
                              },
                            );
                          },
                        ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('mark-all-present-button'),
        onPressed: activeEmployees == null || activeEmployees.isEmpty
            ? null
            : () => _markAllPresent(activeEmployees.map((e) => e.id).toList()),
        icon: const Icon(Icons.done_all),
        label: const Text('Mark all present'),
      ),
    );
  }
}
