import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../../../core/widgets/inset_list_tile.dart';
import '../../../core/widgets/list_action_row.dart';
import '../../../core/widgets/section_header.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/challan_tile.dart';

/// Full page on narrow windows; the left pane of the challans two-pane
/// layout on wide ones, where [selectedId] is highlighted. One direction's
/// recent challans (this financial year and last), under month headings;
/// anything older, or any search, is the search page's job.
class ChallanListPage extends ConsumerWidget {
  const ChallanListPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = ref.watch(selectedDirectionProvider);
    final challansAsync = ref.watch(recentChallansProvider(direction));
    final newLabel = 'New ${direction.label.toLowerCase()} challan';

    final Widget list;
    final challans = challansAsync.value;
    if (challansAsync.hasError) {
      list = Center(child: Text('${challansAsync.error}'));
    } else if (challans != null) {
      list = _ChallanList(
        challans: challans,
        direction: direction,
        newLabel: newLabel,
        selectedId: selectedId,
      );
    } else {
      list = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search challans',
            onPressed: () =>
                openInPane(context, const ChallanSearchRoute().location),
          ),
        ],
        bottom: PreferredSize(
          // 8 + 40 segmented button + 8.
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChallanDirection>(
                segments: [
                  for (final option in ChallanDirection.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {direction},
                onSelectionChanged: (picked) => ref
                    .read(selectedDirectionProvider.notifier)
                    .select(picked.single),
              ),
            ),
          ),
        ),
      ),
      body: list,
      floatingActionButton: context.isTwoPane
          ? null
          : FloatingActionButton(
              heroTag: 'add-challan',
              tooltip: newLabel,
              onPressed: () =>
                  ChallanNewRoute(direction: direction).push(context),
              child: const Icon(Icons.add),
            ),
    );
  }
}

final _monthHeading = DateFormat('MMMM y');

class _ChallanList extends StatelessWidget {
  const _ChallanList({
    required this.challans,
    required this.direction,
    required this.newLabel,
    required this.selectedId,
  });

  final List<Challan> challans;
  final ChallanDirection direction;
  final String newLabel;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    // Wide: "New …" as the first row, next to what it adds to. Phones: the
    // floating button.
    final rows = <Widget>[
      if (context.isTwoPane)
        ListActionRow(
          icon: Icons.add,
          label: newLabel,
          onTap: () => ChallanNewRoute(direction: direction).push(context),
        ),
      if (challans.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No ${direction.label.toLowerCase()} challans yet'),
        ),
    ];

    // A heading above the first challan of each month.
    String? month;
    for (final challan in challans) {
      final challanMonth = _monthHeading.format(challan.challanDate);
      if (challanMonth != month) {
        month = challanMonth;
        rows.add(SectionHeader(challanMonth, topPadding: 16));
      }
      rows.add(
        ChallanTile(
          challan: challan,
          selected: challan.id == selectedId,
          onTap: () =>
              openInPane(context, ChallanDetailRoute(challan.id).location),
        ),
      );
    }

    rows.add(
      InsetListTile(
        leading: const Icon(Icons.manage_search),
        title: const Text('Older challans'),
        subtitle: const Text('Search by date, client or item'),
        onTap: () => openInPane(context, const ChallanSearchRoute().location),
      ),
    );

    // A builder: two years can hold several hundred challans.
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
    );
  }
}
