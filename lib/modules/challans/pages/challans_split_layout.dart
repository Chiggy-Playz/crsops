import 'package:flutter/material.dart';

import '../../../core/layout/two_pane_layout.dart';
import 'challan_list_page.dart';

/// Challans on wide windows: the list on the left, the selected challan (the
/// routed [child]) on the right. Narrow windows show [child] alone.
class ChallansSplitLayout extends StatelessWidget {
  const ChallansSplitLayout({
    super.key,
    required this.selectedId,
    required this.child,
  });

  final String? selectedId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TwoPaneLayout(
      pane: ChallanListPage(selectedId: selectedId),
      paneWidth: 400,
      child: child,
    );
  }
}
