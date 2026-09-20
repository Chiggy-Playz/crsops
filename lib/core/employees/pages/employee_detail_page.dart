import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../errors/app_exception.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/status_metadata.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../providers/employee_providers.dart';
import '../routes.dart';
import 'widgets/add_event_dialog.dart';
import 'widgets/add_payment_dialog.dart';

final _dateFormat = DateFormat('d MMM yyyy');
final _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String _tenureText(DateTime since) {
  final days = DateTime.now().difference(since).inDays;
  if (days < 30) return 'Joined $days day${days == 1 ? '' : 's'} ago';
  if (days < 365) {
    final months = (days / 30).floor();
    return 'Joined $months month${months == 1 ? '' : 's'} ago';
  }
  final years = (days / 365).floor();
  return 'Joined $years year${years == 1 ? '' : 's'} ago';
}

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employeeId));
    final timelineAsync = ref.watch(employeeTimelineProvider(employeeId));
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: employeeAsync.when(
          data: (e) => Text(e.name),
          loading: () => const Text(''),
          error: (_, _) => const Text('Employee'),
        ),
        actions: [
          IconButton(
            key: const Key('edit-employee-button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit employee',
            onPressed: employeeAsync.value == null
                ? null
                : () => EmployeeEditRoute(
                    employeeId,
                    $extra: employeeAsync.value,
                  ).push(context),
          ),
        ],
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employee) {
          final joinedSince = timelineAsync.value
              ?.where(
                (e) =>
                    e.kind == 'event' &&
                    (e.label == 'joined' || e.label == 'rehired'),
              )
              .map((e) => e.entryDate)
              .fold<DateTime?>(
                null,
                (earliest, date) => earliest == null || date.isBefore(earliest)
                    ? date
                    : earliest,
              );

          return Column(
            children: [
              _ProfileCard(
                employee: employee,
                status: statusAsync.value,
                joinedSince: joinedSince ?? employee.createdAt,
              ),
              Expanded(
                child: timelineAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('$error')),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(child: Text('No history yet'));
                    }
                    final eventTypesById = {
                      for (final t in eventTypesAsync.value ?? const [])
                        t.id: t,
                    };
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) => _TimelineRow(
                        entry: entries[index],
                        eventType: entries[index].kind == 'event'
                            ? eventTypesById[entries[index].label]
                            : null,
                        isFirst: index == 0,
                        isLast: index == entries.length - 1,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            key: const Key('add-payment-button'),
            heroTag: 'add-payment',
            mini: true,
            tooltip: 'Add payment',
            onPressed: () => showAddPaymentDialog(context, ref, employeeId),
            child: const Icon(Icons.payments),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            key: const Key('add-event-button'),
            heroTag: 'add-event',
            onPressed: () => showAddEventDialog(context, ref, employeeId),
            icon: const Icon(Icons.add),
            label: const Text('Add event'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.employee,
    required this.status,
    required this.joinedSince,
  });

  final Employee employee;
  final String? status;
  final DateTime joinedSince;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(employee.color);
    final isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Text(
                initialsFor(employee.name),
                style: TextStyle(
                  color: contrastingTextColor(color),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (status != null)
                        Chip(
                          avatar: Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 18,
                          ),
                          label: Text(displayLabel(status!)),
                          backgroundColor:
                              (isActive ? Colors.green : Colors.red).withValues(
                                alpha: 0.12,
                              ),
                        ),
                      Text(
                        _tenureText(joinedSince),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (employee.salary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Salary: ${_currencyFormat.format(employee.salary)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (employee.notes != null &&
                      employee.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(employee.notes!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
    required this.entry,
    required this.eventType,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineEntry entry;
  final EventType? eventType;
  final bool isFirst;
  final bool isLast;

  void _edit(BuildContext context, WidgetRef ref) {
    if (entry.kind == 'ledger') {
      showAddPaymentDialog(context, ref, entry.employeeId, existing: entry);
    } else {
      showAddEventDialog(context, ref, entry.employeeId, existing: entry);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: entry.kind == 'ledger' ? 'Delete payment?' : 'Delete event?',
      message:
          'This removes "${displayLabel(entry.label)}" on ${_dateFormat.format(entry.entryDate)} entirely.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      if (entry.kind == 'ledger') {
        await ref
            .read(employeeLedgerEntryRepositoryProvider)
            .deleteEntry(entry.id);
      } else {
        await ref.read(employeeEventRepositoryProvider).deleteEvent(entry.id);
      }
      ref.invalidate(employeeTimelineProvider(entry.employeeId));
      ref.invalidate(employeeCurrentStatusProvider(entry.employeeId));
    } on AppException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLedger = entry.kind == 'ledger';
    final dotColor = isLedger
        ? theme.colorScheme.tertiary
        : colorFor(eventType?.colorHex);
    final icon = isLedger ? Icons.payments : iconFor(eventType?.iconName);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateFormat.format(entry.entryDate),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: dotColor),
                      const SizedBox(width: 6),
                      Text(
                        displayLabel(entry.label),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (entry.amount != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _currencyFormat.format(entry.amount),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.note != null && entry.note!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.note!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') _edit(context, ref);
              if (value == 'delete') _delete(context, ref);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
