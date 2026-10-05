import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/two_pane_layout.dart';
import '../../layout/window_size.dart';
import '../../widgets/list_action_row.dart';
import '../../widgets/section_header.dart';
import '../models/employee.dart';
import '../providers/employee_providers.dart';
import '../routes.dart';
import 'widgets/employee_avatar.dart';

const employeeListRoutePath = '/employees';

/// Full page on narrow windows; the left pane of the employees two-pane
/// layout on wide ones, where [selectedId] is highlighted.
class EmployeeListPage extends ConsumerStatefulWidget {
  const EmployeeListPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends ConsumerState<EmployeeListPage> {
  String _query = '';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    final Widget body;
    final employees = employeesAsync.value;
    if (employeesAsync.hasError) {
      body = Center(child: Text('${employeesAsync.error}'));
    } else if (employees != null) {
      body = _buildList(employees);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    // Wide windows: "New employee" is the list's first row, right above the
    // names. Phones: the usual floating button.
    final isTwoPane = context.isTwoPane;

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
          // Must match what the child really takes (8 + 56 search bar + 8):
          // declaring less squeezes the toolbar above it, cramming the title
          // and actions against the top edge.
          preferredSize: const Size.fromHeight(72),
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
      floatingActionButton: !isTwoPane
          ? FloatingActionButton(
              heroTag: 'add-employee',
              tooltip: 'Add employee',
              onPressed: () => const EmployeeNewRoute().push(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildList(List<Employee> employees) {
    final addRow = context.isTwoPane
        ? ListActionRow(
            key: const Key('add-employee-row'),
            icon: Icons.person_add_outlined,
            label: 'New employee',
            onTap: () => const EmployeeNewRoute().push(context),
          )
        : null;

    final matching = employees
        .where((e) => e.name.toLowerCase().contains(_query))
        .toList();
    final active = matching.where((e) => !e.isInactive).toList();
    final inactive = _showInactive
        ? matching.where((e) => e.isInactive).toList()
        : const <Employee>[];

    final String? emptyMessage;
    if (employees.isEmpty) {
      emptyMessage = 'No employees yet';
    } else if (active.isEmpty && inactive.isEmpty) {
      emptyMessage = 'No employees match your search';
    } else {
      emptyMessage = null;
    }

    // Phones: a centred message (the floating button is there to add).
    if (emptyMessage != null && addRow == null) {
      return Center(child: Text(emptyMessage));
    }

    // Active first, then former employees under their own header —
    // each group keeps the repository's alphabetical order.
    return ListView(
      children: [
        ?addRow,
        if (emptyMessage != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(emptyMessage)),
        for (final e in active)
          _EmployeeTile(employee: e, selected: e.id == widget.selectedId),
        if (inactive.isNotEmpty) ...[
          const SectionHeader('Inactive'),
          for (final e in inactive)
            _EmployeeTile(
              employee: e,
              inactive: true,
              selected: e.id == widget.selectedId,
            ),
        ],
      ],
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.employee,
    this.inactive = false,
    this.selected = false,
  });

  final Employee employee;
  final bool inactive;
  final bool selected;

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
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      onTap: () =>
          openInPane(context, EmployeeDetailRoute(employee.id).location),
    );
  }
}
