import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/utils/status_metadata.dart';
import '../../models/derived_flags_row.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_ids.dart';
import '../../models/status_type.dart';
import '../../routes.dart';
import '../widgets/attendance_month_calendar.dart';
import 'report_calculations.dart';

/// One card per status with how many days had it, plus Unmarked.
class ReportSummaryGrid extends StatelessWidget {
  const ReportSummaryGrid({
    super.key,
    required this.statusTypes,
    required this.summary,
  });

  final List<StatusType> statusTypes;

  /// Day count by status id (see computeStatusSummary).
  final Map<String, int> summary;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
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
          count: summary[StatusIds.unmarked] ?? 0,
          icon: Icons.help_outline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// The late / left-early / overtime days in the range, one row each.
class ReportExceptionsList extends StatelessWidget {
  const ReportExceptionsList({
    super.key,
    required this.exceptions,
    required this.nameByEmployeeId,
  });

  final List<DerivedFlagsRow> exceptions;
  final Map<String, String> nameByEmployeeId;

  List<String> _parts(DerivedFlagsRow e) => [
    if (e.isLate) 'Late',
    if (e.isEarly) 'Left early',
    if (e.overtimeMinutes > 0) '+${formatOvertime(e.overtimeMinutes)} overtime',
  ];

  @override
  Widget build(BuildContext context) {
    if (exceptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('No exceptions in this range.'),
      );
    }
    return Column(
      children: [
        for (final e in exceptions)
          ListTile(
            title: Text(nameByEmployeeId[e.employeeId] ?? 'Unknown employee'),
            subtitle: Text(
              '${formatDisplayDate(e.date)} · ${_parts(e).join(' · ')}',
            ),
          ),
      ],
    );
  }
}

/// The range's attendance on a month calendar, opening on its last month.
class ReportCalendar extends StatefulWidget {
  const ReportCalendar({
    super.key,
    required this.range,
    required this.rows,
    required this.statusTypes,
  });

  final DateTimeRange range;
  final List<EffectiveStatusRow> rows;
  final List<StatusType> statusTypes;

  @override
  State<ReportCalendar> createState() => ReportCalendarState();
}

class ReportCalendarState extends State<ReportCalendar> {
  late DateTime _month = widget.range.end;

  @override
  void didUpdateWidget(ReportCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new range: show its last month (the most recent data).
    if (oldWidget.range != widget.range) _month = widget.range.end;
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceMonthCalendar(
      month: _month,
      rows: widget.rows,
      statusTypes: widget.statusTypes,
      firstDate: widget.range.start,
      lastDate: widget.range.end,
      onMonthChanged: (month) => setState(() => _month = month),
      // A quick look on top of Reports (see ReportDayRoute): back/✕ returns
      // here with the filters intact.
      onDateTap: (day) => ReportDayRoute(dateOnly(day)).push(context),
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
