import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/employees/models/employee.dart';
import '../../../core/employees/providers/employee_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/list_action_row.dart';
import '../models/effective_status_row.dart';
import '../models/status_type.dart';
import '../providers/attendance_providers.dart';
import '../routes.dart';
import 'widgets/employee_marking_tile.dart';
import 'widgets/status_picker_sheet.dart';

class AttendanceDayPage extends ConsumerStatefulWidget {
  const AttendanceDayPage({
    super.key,
    required this.date,
    this.openedFromReports = false,
  });

  final DateTime date;

  /// A quick look from Reports (a dialog on wide windows, a page on phones)
  /// rather than the attendance day pane: closing returns to Reports.
  final bool openedFromReports;

  @override
  ConsumerState<AttendanceDayPage> createState() => _AttendanceDayPageState();
}

class _AttendanceDayPageState extends ConsumerState<AttendanceDayPage> {
  final Set<String> _busyEmployeeIds = {};

  // Invalidates every cached instance of this family, not just this page's
  // own single-day query — otherwise the Calendar's separately-cached
  // month-range query stays stale until something else forces a refetch
  // (e.g. swiping months), so a freshly-marked day's color and gap marker
  // never update on going back.
  void _refresh() => ref.invalidate(effectiveRangeStatusProvider);

  void _showError(AppException e) {
    if (!mounted) return;
    showErrorSnackBar(e);
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

    final hasEmployees = activeEmployees != null && activeEmployees.isNotEmpty;
    void markAllPresent() =>
        _markAllPresent(activeEmployees!.map((e) => e.id).toList());
    final isTwoPane = context.isTwoPane;
    final ({Widget? leading, bool implyLeading}) leading;
    if (widget.openedFromReports) {
      // Over Reports: ✕ in the wide-window dialog, the usual back arrow on
      // phones — both return to Reports with its filters intact.
      if (isTwoPane) {
        leading = (leading: const CloseButton(), implyLeading: false);
      } else {
        leading = (leading: null, implyLeading: true);
      }
    } else {
      leading = paneLeading(
        context,
        parentLocation: const CalendarRoute().location,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: leading.leading,
        automaticallyImplyLeading: leading.implyLeading,
        title: Text('Attendance on ${formatDisplayDate(widget.date)}'),
        actions: [
          IconButton(
            key: const Key('mark-holiday-button'),
            icon: const Icon(Icons.beach_access_outlined),
            tooltip: 'Mark day as company holiday',
            onPressed: hasEmployees
                ? () => _markHoliday(activeEmployees.map((e) => e.id).toList())
                : null,
          ),
        ],
      ),
      body: _buildBody(
        employeesAsync: employeesAsync,
        statusAsync: statusAsync,
        statusTypes: statusTypesAsync.value ?? const [],
        activeEmployees: activeEmployees,
        onMarkAllPresent: markAllPresent,
      ),
      // A FAB with nothing to act on shouldn't be shown at all — it's not a
      // form control to grey out, it's the screen's primary action.
      floatingActionButton: isTwoPane || !hasEmployees
          ? null
          : FloatingActionButton.extended(
              key: const Key('mark-all-present-button'),
              heroTag: 'mark-all-present',
              onPressed: markAllPresent,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all present'),
            ),
    );
  }

  Widget _buildBody({
    required AsyncValue<List<Employee>> employeesAsync,
    required AsyncValue<List<EffectiveStatusRow>> statusAsync,
    required List<StatusType> statusTypes,
    required List<Employee>? activeEmployees,
    required VoidCallback onMarkAllPresent,
  }) {
    if (employeesAsync.isLoading || statusAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (employeesAsync.hasError) {
      return Center(child: Text('${employeesAsync.error}'));
    }
    if (statusAsync.hasError) {
      return Center(child: Text('${statusAsync.error}'));
    }
    if (activeEmployees == null || activeEmployees.isEmpty) {
      return const Center(child: Text('No active employees for this date'));
    }

    final statusByEmployeeId = {
      for (final s in statusAsync.value!) s.employeeId: s,
    };
    // Wide: "Mark all present" is the list's first row, right above the
    // people it marks. Phones: the floating button.
    final hasActionRow = context.isTwoPane;
    final rowOffset = hasActionRow ? 1 : 0;
    return ListView.builder(
      itemCount: activeEmployees.length + rowOffset,
      itemBuilder: (context, index) {
        if (hasActionRow && index == 0) {
          return ListActionRow(
            key: const Key('mark-all-present-button'),
            icon: Icons.done_all,
            label: 'Mark all present',
            onTap: onMarkAllPresent,
          );
        }
        final employee = activeEmployees[index - rowOffset];
        return EmployeeMarkingTile(
          employee: employee,
          status: statusByEmployeeId[employee.id],
          statusTypes: statusTypes,
          busy: _busyEmployeeIds.contains(employee.id),
          onMarkStatus: (pick) => _markStatus(employee.id, pick),
          onUnmark: () => _unmark(employee.id),
        );
      },
    );
  }
}
