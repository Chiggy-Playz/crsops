import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/employees/models/employee.dart';
import '../../../core/employees/providers/employee_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../providers/attendance_providers.dart';
import 'widgets/employee_marking_tile.dart';
import 'widgets/status_picker_sheet.dart';

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

  void _showError(AppException e) {
    if (!mounted) return;
    showErrorSnackBar(context, e);
  }

  Future<void> _markAllPresent(List<String> employeeIds) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark all present?',
      message: 'This overwrites any existing marking for this day.',
      dialogKey: const Key('mark-all-present-confirm-dialog'),
    );
    if (confirmed) {
      try {
        await ref
            .read(attendanceRepositoryProvider)
            .markAllPresent(date: widget.date, employeeIds: employeeIds);
        _refresh();
      } on AppException catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _markHoliday(List<String> employeeIds) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark day as company holiday?',
      message: 'This overwrites any existing marking for this day.',
      dialogKey: const Key('mark-holiday-confirm-dialog'),
    );
    if (confirmed) {
      try {
        await ref
            .read(attendanceRepositoryProvider)
            .markHoliday(date: widget.date, employeeIds: employeeIds);
        _refresh();
      } on AppException catch (e) {
        _showError(e);
      }
    }
  }

  /// Busy-flag wrapper shared by the per-employee mutations: same
  /// set-busy/try/refresh-or-error/clear shape, only the repository call
  /// differs.
  Future<void> _runFor(
    String employeeId,
    Future<void> Function() action,
  ) async {
    setState(() => _busyEmployeeIds.add(employeeId));
    try {
      await action();
      _refresh();
    } on AppException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyEmployeeIds.remove(employeeId));
    }
  }

  Future<void> _markStatus(String employeeId, StatusPick pick) => _runFor(
    employeeId,
    () => ref
        .read(attendanceRepositoryProvider)
        .markDay(
          employeeId: employeeId,
          date: widget.date,
          firstHalfStatus: pick.firstHalfStatus,
          secondHalfStatus: pick.secondHalfStatus,
          timeIn: pick.timeIn,
          timeOut: pick.timeOut,
          note: pick.note,
        ),
  );

  Future<void> _unmark(String employeeId) => _runFor(
    employeeId,
    () => ref
        .read(attendanceRepositoryProvider)
        .unmarkDay(employeeId: employeeId, date: widget.date),
  );

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final statusAsync = ref.watch(
      effectiveRangeStatusProvider(start: widget.date, end: widget.date),
    );
    final statusTypesAsync = ref.watch(statusTypesProvider);

    // `effectiveRangeStatusProvider` already excludes employees who weren't
    // active on `widget.date` (per core.employee_status_as_of) — the row set
    // it returns, not the full employee list, is what decides who belongs on
    // this page. An employee joining next week must not show up as
    // "unmarked" on a day before they existed.
    final activeEmployeeIds = statusAsync.value
        ?.map((s) => s.employeeId)
        .toSet();
    final employeesById = {
      for (final e in employeesAsync.value ?? const []) e.id: e,
    };
    final activeEmployees = activeEmployeeIds == null
        ? null
        : <Employee>[
            for (final id in activeEmployeeIds)
              if (employeesById[id] != null) employeesById[id]!,
          ];

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
                final statusByEmployeeId = {
                  for (final s in statusAsync.value!) s.employeeId: s,
                };
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
      // A FAB with nothing to act on shouldn't be shown at all — it's not a
      // form control to grey out, it's the screen's primary action.
      floatingActionButton: activeEmployees == null || activeEmployees.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('mark-all-present-button'),
              onPressed: () =>
                  _markAllPresent(activeEmployees.map((e) => e.id).toList()),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all present'),
            ),
    );
  }
}
