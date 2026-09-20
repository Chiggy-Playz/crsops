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
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final statusesAsync = ref.watch(employeeCurrentStatusesProvider);
    final statuses = statusesAsync.value ?? const <String, String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Hide inactive employees' : 'Show inactive employees',
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: 'Search employees',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }

          final filtered = employees
              .where((e) => e.name.toLowerCase().contains(_query))
              .where((e) => _showInactive || statuses[e.id] != 'inactive')
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No employees match your search'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => _EmployeeTile(employee: filtered[index], status: statuses[filtered[index].id]),
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

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, required this.status});

  final Employee employee;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = Color(employee.color);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          initialsFor(employee.name),
          style: TextStyle(color: contrastingTextColor(color), fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(employee.name),
      trailing: status == null
          ? null
          : Chip(
              label: Text(displayLabel(status!)),
              backgroundColor: colorFor(status == 'active' ? '#4CAF50' : '#F44336').withValues(alpha: 0.2),
            ),
      onTap: () => context.pushNamed(RouteNames.employeeDetail, pathParameters: {'id': employee.id}),
    );
  }
}
