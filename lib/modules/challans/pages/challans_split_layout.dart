import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../providers/challan_providers.dart';
import 'challan_list_page.dart';
import 'challan_search_page.dart';

/// Challans on wide windows: the list (or, while searching, the search and its
/// results) on the left, the selected challan (the routed [child]) on the
/// right. Narrow windows show [child] alone.
class ChallansSplitLayout extends ConsumerWidget {
  const ChallansSplitLayout({
    super.key,
    required this.selectedId,
    required this.onSearchRoute,
    required this.child,
  });

  final String? selectedId;

  /// Whether the location is the search page itself (a link, or a resize
  /// from a phone), which also shows the search on the left.
  final bool onSearchRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searching = ref.watch(challanSearchOpenProvider) || onSearchRoute;

    // The search has chips and longer rows, so it gets more room as the
    // window allows (40%, between 400 and 520); the list stays 400.
    final double paneWidth;
    if (searching) {
      paneWidth = (context.contentWidth * 0.4).clamp(400, 520);
    } else {
      paneWidth = 400;
    }

    return TwoPaneLayout(
      pane: searching
          ? ChallanSearchPage(inListPane: true, selectedId: selectedId)
          : ChallanListPage(selectedId: selectedId),
      paneWidth: paneWidth,
      child: child,
    );
  }
}
