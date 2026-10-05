import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/employees/models/employee.dart';
import '../../../core/employees/pages/widgets/employee_multi_picker.dart';
import '../../../core/employees/providers/employee_providers.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/status_metadata.dart';
import '../attendance_calendar_colors.dart';
import '../routes.dart';
import '../models/derived_flags_row.dart';
import '../models/effective_status_row.dart';
import '../models/status_type.dart';
import '../providers/attendance_providers.dart';
import '../report_calculations.dart';
import 'widgets/day_cell.dart';
import 'widgets/month_calendar.dart';

final _dateFormat = DateFormat('d MMM yyyy');

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
    return [
      ('Today', DateTimeRange(start: today, end: today)),
      (
        'Last 7 days',
        DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today,
        ),
      ),
      (
        'Last 30 days',
        DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
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
    // Awaited, not read: the statuses may not be loaded yet if the Employees
    // tab was never opened, and every row would then count as active.
    final statuses = await ref.read(employeeCurrentStatusesProvider.future);
    if (!mounted) return;
    final result = await showEmployeeMultiPicker(
      context,
      employees: employees,
      statusById: statuses,
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
                            '${_dateFormat.format(_range.start)} – ${_dateFormat.format(_range.end)}',
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

    final summaryCards = GridView.extent(
      maxCrossAxisExtent: 160,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      mainAxisExtent: 124,
      children: [
        for (final type in statusTypes)
          _SummaryCard(
            label: type.label,
            count: summary[type.id] ?? 0,
            icon: iconFor(type.iconName),
            color: context.customColor(colorFor(type.colorHex)).color,
          ),
        _SummaryCard(
          label: 'Unmarked',
          count: summary['unmarked'] ?? 0,
          icon: Icons.help_outline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );

    final exceptionsSection = <Widget>[
      Text(
        'Late / early / overtime',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (exceptions.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('No exceptions in this range.'),
        )
      else
        for (final e in exceptions)
          ListTile(
            title: Text(nameByEmployeeId[e.employeeId] ?? 'Unknown employee'),
            subtitle: Text(
              '${_dateFormat.format(e.date)} · ${_exceptionParts(e).join(' · ')}',
            ),
          ),
    ];

    final calendarSection = <Widget>[
      Text('Calendar view', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      _ReportCalendar(range: range, rows: statusRows, statusTypes: statusTypes),
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

  List<String> _exceptionParts(DerivedFlagsRow e) => [
    if (e.isLate) 'Late',
    if (e.isEarly) 'Left early',
    if (e.overtimeMinutes > 0) '+${formatOvertime(e.overtimeMinutes)} overtime',
  ];
}

class _ReportCalendar extends StatefulWidget {
  const _ReportCalendar({
    required this.range,
    required this.rows,
    required this.statusTypes,
  });

  final DateTimeRange range;
  final List<EffectiveStatusRow> rows;
  final List<StatusType> statusTypes;

  @override
  State<_ReportCalendar> createState() => _ReportCalendarState();
}

class _ReportCalendarState extends State<_ReportCalendar> {
  late DateTime _month = widget.range.end;

  @override
  void didUpdateWidget(_ReportCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new range: show its last month (the most recent data).
    if (oldWidget.range != widget.range) _month = widget.range.end;
  }

  @override
  Widget build(BuildContext context) {
    final colorHexByStatusId = <String, String>{
      for (final t in widget.statusTypes)
        if (t.colorHex != null) t.id: t.colorHex!,
    };
    final labelByStatusId = <String, String>{
      for (final t in widget.statusTypes) t.id: t.label,
    };
    final rowsByDate = groupRowsByDate(widget.rows);

    return MonthCalendar(
      month: _month,
      firstDate: widget.range.start,
      lastDate: widget.range.end,
      onMonthChanged: (month) => setState(() => _month = month),
      // A quick look on top of Reports (see ReportDayRoute): back/✕ returns
      // here with the filters intact.
      onDateTap: (day) => ReportDayRoute(dateOnly(day)).push(context),
      dayBuilder: (context, day, {required isToday, required isSelected}) {
        final dayRows = rowsByDate[dateOnly(day)] ?? const [];
        return DayCell(
          day: day,
          isToday: isToday,
          // From the rows already loaded for the range — so it covers the
          // whole range, not just the last 7 days the main calendar checks.
          hasGap: hasUnmarkedPastDay(dayRows, day),
          statusDots: statusDotsFor(dayRows, colorHexByStatusId),
        );
      },
      semanticLabelFor: (day) {
        final dayRows = rowsByDate[dateOnly(day)] ?? const [];
        final summary = statusSummaryLabel(dayRows, labelByStatusId);
        final gap = hasUnmarkedPastDay(dayRows, day)
            ? 'attendance missing'
            : null;
        final parts = [?summary, ?gap];
        return parts.isEmpty ? null : parts.join(', ');
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
