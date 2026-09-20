import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/employees/providers/employee_providers.dart';
import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';
import '../report_calculations.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  DateTimeRange? _range;
  String? _selectedEmployeeId;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) setState(() => _range = picked);
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _range == null
                          ? 'Select date range'
                          : '${_range!.start.toIso8601String().split('T').first} – ${_range!.end.toIso8601String().split('T').first}',
                    ),
                    onPressed: _pickRange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedEmployeeId,
                      hint: const Text('All employees'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All employees')),
                        ...employees.map((e) => DropdownMenuItem<String?>(value: e.id, child: Text(e.name))),
                      ],
                      onChanged: (value) => setState(() => _selectedEmployeeId = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final range = _range;
    if (range == null) {
      return const Center(child: Text('Select a date range to see a report'));
    }

    final statusTypesAsync = ref.watch(statusTypesProvider);
    final summaryAsync = ref.watch(effectiveRangeStatusProvider(
      start: range.start,
      end: range.end,
      employeeId: _selectedEmployeeId,
    ));
    final exceptionsAsync = ref.watch(derivedFlagsProvider(
      start: range.start,
      end: range.end,
      employeeId: _selectedEmployeeId,
    ));

    if (statusTypesAsync.isLoading || summaryAsync.isLoading || exceptionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (statusTypesAsync.hasError) return Center(child: Text('${statusTypesAsync.error}'));
    if (summaryAsync.hasError) return Center(child: Text('${summaryAsync.error}'));
    if (exceptionsAsync.hasError) return Center(child: Text('${exceptionsAsync.error}'));

    final statusTypes = statusTypesAsync.value!;
    final summary = computeStatusSummary(summaryAsync.value!, statusTypes);
    final exceptions = filterExceptions(exceptionsAsync.value!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in statusTypes)
              _SummaryCard(label: type.label, count: summary[type.id] ?? 0, icon: iconFor(type.iconName), color: colorFor(type.colorHex)),
            _SummaryCard(
              label: 'Unmarked',
              count: summary['unmarked'] ?? 0,
              icon: Icons.help_outline,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Late / early / overtime', style: Theme.of(context).textTheme.titleMedium),
        if (exceptions.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No exceptions in this range.'))
        else
          ...exceptions.map((e) => ListTile(
                title: Text(e.date.toIso8601String().split('T').first),
                subtitle: Text([
                  if (e.isLate) 'Late',
                  if (e.isEarly) 'Left early',
                  if (e.overtimeMinutes > 0) '+${e.overtimeMinutes}m overtime',
                ].join(' · ')),
              )),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.count, required this.icon, required this.color});

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    );
  }
}
