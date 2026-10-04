import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/employees/models/employee.dart';
import '../../../core/employees/providers/employee_providers.dart';
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
import 'widgets/employee_picker_dialog.dart';

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

  Future<void> _openRangeMenu() async {
    final now = DateTime.now();
    final choice = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: const [
        PopupMenuItem(value: 'today', child: Text('Today')),
        PopupMenuItem(value: '7d', child: Text('Last 7 days')),
        PopupMenuItem(value: '30d', child: Text('Last 30 days')),
        PopupMenuItem(value: 'month', child: Text('This month')),
        PopupMenuItem(value: 'custom', child: Text('Custom range…')),
      ],
    );
    if (choice == 'custom') {
      await _pickCustomRange();
      return;
    }
    // One hoisted `now` above. Single map (range plus label) so the two
    // can never drift apart.
    final presets = {
      'today': (DateTimeRange(start: now, end: now), 'Today'),
      '7d': (
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
        'Last 7 days',
      ),
      '30d': (
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
        'Last 30 days',
      ),
      'month': (
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
        'This month',
      ),
    };
    final preset = presets[choice];
    if (preset != null) {
      setState(() {
        _range = preset.$1;
        _rangeLabel = preset.$2;
      });
    }
  }

  Future<void> _openEmployeePicker(List<Employee> employees) async {
    final result = await showEmployeePicker(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InputChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _rangeLabel ??
                        '${_dateFormat.format(_range.start)} – ${_dateFormat.format(_range.end)}',
                  ),
                  onPressed: _openRangeMenu,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.extent(
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
                color: colorFor(type.colorHex),
              ),
            _SummaryCard(
              label: 'Unmarked',
              count: summary['unmarked'] ?? 0,
              icon: Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 24),
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
          ...exceptions.map((e) {
            final parts = [
              if (e.isLate) 'Late',
              if (e.isEarly) 'Left early',
              if (e.overtimeMinutes > 0)
                '+${formatOvertime(e.overtimeMinutes)} overtime',
            ];
            return ListTile(
              title: Text(nameByEmployeeId[e.employeeId] ?? 'Unknown employee'),
              subtitle: Text(
                '${_dateFormat.format(e.date)} · ${parts.join(' · ')}',
              ),
            );
          }),
        const SizedBox(height: 24),
        Text('Calendar view', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ReportCalendar(
          range: range,
          rows: statusRows,
          statusTypes: statusTypes,
        ),
      ],
    );
  }
}

class _ReportCalendar extends StatelessWidget {
  const _ReportCalendar({
    required this.range,
    required this.rows,
    required this.statusTypes,
  });

  final DateTimeRange range;
  final List<EffectiveStatusRow> rows;
  final List<StatusType> statusTypes;

  @override
  Widget build(BuildContext context) {
    final colorHexByStatusId = <String, String>{
      for (final t in statusTypes)
        if (t.colorHex != null) t.id: t.colorHex!,
    };
    final rowsByDate = groupRowsByDate(rows);

    return SizedBox(
      height: 400,
      child: TableCalendar(
        firstDay: range.start,
        lastDay: range.end,
        focusedDay: range.start,
        headerStyle: const HeaderStyle(formatButtonVisible: false),
        onDaySelected: (selectedDay, focusedDay) =>
            AttendanceDayRoute(dateOnly(selectedDay)).push(context),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final dateKey = dateOnly(day);
            return DayCell(
              day: day,
              hasGap: false,
              statusDots: statusDotsFor(
                rowsByDate[dateKey] ?? const [],
                colorHexByStatusId,
              ),
            );
          },
        ),
      ),
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
