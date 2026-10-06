import 'package:flutter/material.dart';

import '../../layout/two_pane_layout.dart';
import 'client_list_page.dart';

/// Clients on wide windows: the list on the left, the selected client (the
/// routed [child]) on the right. Narrow windows show [child] alone.
class ClientsSplitLayout extends StatelessWidget {
  const ClientsSplitLayout({
    super.key,
    required this.selectedId,
    required this.child,
  });

  final String? selectedId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TwoPaneLayout(
      pane: ClientListPage(selectedId: selectedId),
      child: child,
    );
  }
}
