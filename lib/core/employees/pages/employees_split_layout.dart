import 'package:flutter/material.dart';

import '../../layout/two_pane_layout.dart';
import 'employee_list_page.dart';

/// Employees on wide windows: the list on the left, the selected employee
/// (the routed [child]) on the right. Narrow windows show [child] alone.
class EmployeesSplitLayout extends StatelessWidget {
  const EmployeesSplitLayout({
    super.key,
    required this.selectedId,
    required this.child,
  });

  final String? selectedId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TwoPaneLayout(
      pane: EmployeeListPage(selectedId: selectedId),
      child: child,
    );
  }
}
