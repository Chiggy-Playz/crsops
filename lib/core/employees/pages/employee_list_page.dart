import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_names.dart';
import '../../widgets/status_metadata.dart';
import '../models/employee.dart';
import '../providers/employee_providers.dart';

const employeeListRoutePath = '/employees';

class EmployeeListPage extends ConsumerStatefulWidget {
  const EmployeeListPage({super.key});

  @override
  ConsumerState<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends ConsumerState<EmployeeListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employees',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employees) {
          final filtered = employees.where((e) => e.name.toLowerCase().contains(_query)).toList();

          if (employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('No employees match your search'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => _EmployeeTile(employee: filtered[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.employeeNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  const _EmployeeTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employee.id));

    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(employee.color)),
      title: Text(employee.name),
      trailing: statusAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (status) => status == null
            ? const SizedBox.shrink()
            : Chip(
                label: Text(status),
                backgroundColor: colorFor(status == 'active' ? '#4CAF50' : '#F44336').withValues(alpha: 0.2),
              ),
      ),
      onTap: () => context.pushNamed(RouteNames.employeeDetail, pathParameters: {'id': employee.id}),
    );
  }
}
