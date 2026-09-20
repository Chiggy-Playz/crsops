import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_names.dart';
import '../providers/employee_providers.dart';
import 'widgets/add_event_dialog.dart';
import 'widgets/add_payment_dialog.dart';

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employeeId));
    final timelineAsync = ref.watch(employeeTimelineProvider(employeeId));

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
                : () => context.pushNamed(
                      RouteNames.employeeEdit,
                      pathParameters: {'id': employeeId},
                      extra: employeeAsync.value,
                    ),
          ),
          IconButton(
            key: const Key('add-payment-button'),
            icon: const Icon(Icons.payments),
            tooltip: 'Add payment',
            onPressed: () => showAddPaymentDialog(context, ref, employeeId),
          ),
        ],
      ),
      body: Column(
        children: [
          statusAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (status) => status == null ? const SizedBox.shrink() : Chip(label: Text(status)),
          ),
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text('No history yet'));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      leading: Icon(entry.kind == 'ledger' ? Icons.payments : Icons.event_note),
                      title: Text(entry.label),
                      subtitle: entry.note == null ? null : Text(entry.note!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-event-button'),
        onPressed: () => showAddEventDialog(context, ref, employeeId),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
    );
  }
}
