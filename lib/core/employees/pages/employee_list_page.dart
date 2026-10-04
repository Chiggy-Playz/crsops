import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../providers/employee_providers.dart';
import '../routes.dart';
import 'widgets/employee_avatar.dart';

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

    // Wait for statuses too: rendering with an empty status map treats
    // everyone as active, so inactive employees flashed in for a moment.
    final error = employeesAsync.error ?? statusesAsync.error;
    final employees = employeesAsync.value;
    final statuses = statusesAsync.value;
    final isLoaded = employees != null && statuses != null;

    final Widget body;
    if (error != null) {
      body = Center(child: Text('$error'));
    } else if (isLoaded) {
      body = _buildList(employees, statuses);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive
                ? 'Hide inactive employees'
                : 'Show inactive employees',
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
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => const EmployeeNewRoute().push(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Employee> employees, Map<String, String> statuses) {
    if (employees.isEmpty) {
      return const Center(child: Text('No employees yet'));
    }

    bool isInactive(Employee e) => statuses[e.id] == 'inactive';
    final matching = employees
        .where((e) => e.name.toLowerCase().contains(_query))
        .toList();
    final active = matching.where((e) => !isInactive(e)).toList();
    final inactive = _showInactive
        ? matching.where(isInactive).toList()
        : const <Employee>[];

    if (active.isEmpty && inactive.isEmpty) {
      return const Center(child: Text('No employees match your search'));
    }

    // Active first, then former employees under their own header —
    // each group keeps the repository's alphabetical order.
    return ListView(
      children: [
        for (final e in active) _EmployeeTile(employee: e),
        if (inactive.isNotEmpty) ...[
          const _SectionHeader('Inactive'),
          for (final e in inactive) _EmployeeTile(employee: e, inactive: true),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, this.inactive = false});

  final Employee employee;
  final bool inactive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: EmployeeAvatar(name: employee.name, dimmed: inactive),
      title: Text(
        employee.name,
        style: inactive
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
      ),
      onTap: () => EmployeeDetailRoute(employee.id).push(context),
    );
  }
}
