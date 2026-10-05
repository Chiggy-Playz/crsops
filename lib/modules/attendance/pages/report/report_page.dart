import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/employees/models/employee.dart';
import '../../../../core/employees/pages/widgets/employee_multi_picker.dart';
import '../../../../core/employees/providers/employee_providers.dart';
import '../../../../core/layout/two_pane_layout.dart';
import '../../../../core/layout/window_size.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../models/derived_flags_row.dart';
import '../../models/effective_status_row.dart';
import '../../providers/attendance_providers.dart';
import 'report_calculations.dart';
import 'report_sections.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  String? _rangeLabel = 'This month';

  /// Empty means "all employees". `effective_range_status`/`derived_flags`
  /// only take one employee id or none (see attendance_repository.dart) —
  /// there's no server-side "subset of employees" filter, so a multi-select
  /// fetches everyone and filters client-side (see _buildBody).
  Set<String> _selectedEmployeeIds = {};

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _rangeLabel = null;
      });
    }
  }

  /// Range presets, label → range. One place, so a label can never drift
  /// from its range. Built on demand so "today" is always current.
  List<(String, DateTimeRange)> _presets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // "Last N days" means the N full days before today, so today's
    // half-marked attendance doesn't skew it.
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      ('Today', DateTimeRange(start: today, end: today)),
      (
        'Last 7 days',
        DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: yesterday,
        ),
      ),
      (
        'Last 30 days',
        DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: yesterday,
        ),
      ),
      (
        'This month',
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
      ),
      ('Previous month', previousMonthRange(now)),
    ];
  }

  void _applyPreset(String label, DateTimeRange range) => setState(() {
    _range = range;
    _rangeLabel = label;
  });

  Future<void> _openEmployeePicker(List<Employee> employees) async {
    final result = await showEmployeeMultiPicker(
      context,
      employees: employees,
      initialSelection: _selectedEmployeeIds,
    );
    if (result != null) setState(() => _selectedEmployeeIds = result);
  }

  String _employeeChipLabel(List<Employee> employees) {
    if (_selectedEmployeeIds.isEmpty) return 'All employees';
    if (_selectedEmployeeIds.length == 1) {
      final id = _selectedEmployeeIds.first;
      for (final e in employees) {
        if (e.id == id) return e.name;
      }
      return '1 employee';
    }
    return '${_selectedEmployeeIds.length} employees';
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      // Below large, filters and content share one centred, capped column so
      // they line up; large windows use the full width (two columns).
      body: MaxWidthBox(
        maxWidth: context.windowSize == WindowSize.large
            ? double.infinity
            : 840,
        child: Column(
          // Filters start at the left edge like the content below them.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Anchored under the chip (it used to open at a hardcoded
                  // screen position).
                  MenuAnchor(
                    animated: true,
                    menuChildren: [
                      for (final (label, range) in _presets())
                        MenuItemButton(
                          onPressed: () => _applyPreset(label, range),
                          child: Text(label),
                        ),
                      const Divider(height: 1),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: _pickCustomRange,
                        child: const Text('Custom range…'),
                      ),
                    ],
                    builder: (context, controller, _) => InputChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _rangeLabel ??
                            '${formatDisplayDate(_range.start)} – ${formatDisplayDate(_range.end)}',
                      ),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                  ),
                  employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => InputChip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text(_employeeChipLabel(employees)),
                      onPressed: () => _openEmployeePicker(employees),
                      onDeleted: _selectedEmployeeIds.isEmpty
                          ? null
                          : () => setState(() => _selectedEmployeeIds = {}),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(employeesAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Employee>> employeesAsync) {
    final range = _range;
    // Exactly one employee selected: use the server-side filter directly.
    // Zero (all) or several selected: fetch everyone and filter client-side,
    // since the RPCs don't support an arbitrary subset.
    final singleEmployeeId = _selectedEmployeeIds.length == 1
        ? _selectedEmployeeIds.first
        : null;

    final statusTypesAsync = ref.watch(statusTypesProvider);
    final summaryAsync = ref.watch(
      effectiveRangeStatusProvider(
        start: range.start,
        end: range.end,
        employeeId: singleEmployeeId,
      ),
    );
    final exceptionsAsync = ref.watch(
      derivedFlagsProvider(
        start: range.start,
        end: range.end,
        employeeId: singleEmployeeId,
      ),
    );

    if (statusTypesAsync.isLoading ||
        employeesAsync.isLoading ||
        summaryAsync.isLoading ||
        exceptionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // One shape for every async failure: the errors are translated
    // AppExceptions (user-safe by construction), so showing the first is
    // enough — no per-source branch needed.
    for (final AsyncValue<dynamic> async in <AsyncValue<dynamic>>[
      statusTypesAsync,
      employeesAsync,
      summaryAsync,
      exceptionsAsync,
    ]) {
      if (async.hasError) return Center(child: Text('${async.error}'));
    }

    final statusTypes = statusTypesAsync.value!;
    final nameByEmployeeId = {
      for (final e in employeesAsync.value!) e.id: e.name,
    };
    final needsClientFilter =
        singleEmployeeId == null && _selectedEmployeeIds.isNotEmpty;
    final List<EffectiveStatusRow> statusRows = needsClientFilter
        ? summaryAsync.value!
              .where((r) => _selectedEmployeeIds.contains(r.employeeId))
              .toList()
        : summaryAsync.value!;
    final List<DerivedFlagsRow> exceptionRows = needsClientFilter
        ? exceptionsAsync.value!
              .where((r) => _selectedEmployeeIds.contains(r.employeeId))
              .toList()
        : exceptionsAsync.value!;

    final summary = computeStatusSummary(statusRows, statusTypes);
    final exceptions = filterExceptions(exceptionRows);

    final summaryCards = ReportSummaryGrid(
      statusTypes: statusTypes,
      summary: summary,
    );

    final exceptionsSection = <Widget>[
      Text(
        'Late / early / overtime',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      ReportExceptionsList(
        exceptions: exceptions,
        nameByEmployeeId: nameByEmployeeId,
      ),
    ];

    final calendarSection = <Widget>[
      Text('Calendar view', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ReportCalendar(range: range, rows: statusRows, statusTypes: statusTypes),
    ];

    // Large windows: numbers on the left, calendar on the right, all in view.
    if (context.windowSize == WindowSize.large) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                summaryCards,
                const SizedBox(height: 24),
                ...exceptionsSection,
              ],
            ),
          ),
          SizedBox(
            width: 560,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: calendarSection,
            ),
          ),
        ],
      );
    }

    // Otherwise one column (capped by the page's MaxWidthBox).
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        summaryCards,
        const SizedBox(height: 24),
        ...exceptionsSection,
        const SizedBox(height: 24),
        ...calendarSection,
      ],
    );
  }
}
