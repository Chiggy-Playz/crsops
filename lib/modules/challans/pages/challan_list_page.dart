import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../../../core/widgets/list_action_row.dart';
import '../financial_year.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/challan_tile.dart';

/// Whether [challan] matches a lower-cased search [query]: its number, the
/// client, the printed name, the address label, who handled it, the first
/// item, vehicle, bill number or notes.
bool challanMatches(Challan challan, String query) {
  if (query.isEmpty) return true;
  if ('${challan.number}' == query) return true;
  final fields = [
    challan.clientName,
    challan.nameOnChallan,
    challan.addressLabel,
    challan.handledByName,
    challan.firstItem ?? '',
    challan.vehicleNumber ?? '',
    challan.billNumber ?? '',
    challan.notes ?? '',
  ];
  return fields.any((field) => field.toLowerCase().contains(query));
}

/// Full page on narrow windows; the left pane of the challans two-pane
/// layout on wide ones, where [selectedId] is highlighted.
class ChallanListPage extends ConsumerStatefulWidget {
  const ChallanListPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<ChallanListPage> createState() => _ChallanListPageState();
}

class _ChallanListPageState extends ConsumerState<ChallanListPage> {
  String _query = '';
  bool _onlyNotReceived = false;

  @override
  Widget build(BuildContext context) {
    final direction = ref.watch(selectedDirectionProvider);
    final year = ref.watch(selectedFinancialYearProvider);
    final years = ref.watch(financialYearsProvider(direction)).value ?? [year];
    final challansAsync = ref.watch(challanListProvider(direction, year));

    final Widget body;
    final challans = challansAsync.value;
    if (challansAsync.hasError) {
      body = Center(child: Text('${challansAsync.error}'));
    } else if (challans != null) {
      body = _buildList(challans, direction);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    final newRoute = ChallanNewRoute(direction: direction);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challans'),
        actions: [
          if (direction == ChallanDirection.outward)
            IconButton(
              isSelected: _onlyNotReceived,
              icon: const Icon(Icons.pending_actions_outlined),
              selectedIcon: const Icon(Icons.pending_actions),
              tooltip: _onlyNotReceived
                  ? 'Show all'
                  : 'Show only ones not received back',
              onPressed: () =>
                  setState(() => _onlyNotReceived = !_onlyNotReceived),
            ),
          PopupMenuButton<int>(
            tooltip: 'Financial year',
            initialValue: year,
            onSelected: (picked) =>
                ref.read(selectedFinancialYearProvider.notifier).select(picked),
            itemBuilder: (context) => [
              for (final option in years)
                PopupMenuItem(
                  value: option,
                  child: Text(financialYearLabel(option)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(financialYearLabel(year)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          // 8 + 40 segmented button + 8 + 56 search bar + 8.
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              spacing: 8,
              children: [
                SizedBox(
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
                SearchBar(
                  hintText: 'Search number, client, item',
                  leading: const Icon(Icons.search),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ],
            ),
          ),
        ),
      ),
      body: body,
      floatingActionButton: context.isTwoPane
          ? null
          : FloatingActionButton(
              heroTag: 'add-challan',
              tooltip: 'New ${direction.label.toLowerCase()} challan',
              onPressed: () => newRoute.push(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildList(List<Challan> challans, ChallanDirection direction) {
    final addRow = context.isTwoPane
        ? ListActionRow(
            icon: Icons.add,
            label: 'New ${direction.label.toLowerCase()} challan',
            onTap: () => ChallanNewRoute(direction: direction).push(context),
          )
        : null;

    final matching = challans.where((c) {
      if (_onlyNotReceived && direction == ChallanDirection.outward) {
        if (c.receivedOn != null || c.isCancelled) return false;
      }
      return challanMatches(c, _query);
    }).toList();

    final String? emptyMessage;
    if (challans.isEmpty) {
      emptyMessage = 'No ${direction.label.toLowerCase()} challans this year';
    } else if (matching.isEmpty) {
      emptyMessage = 'No challans match';
    } else {
      emptyMessage = null;
    }

    if (emptyMessage != null && addRow == null) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: matching.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return addRow ?? const SizedBox.shrink();
        if (index == 1) {
          if (emptyMessage == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(emptyMessage),
          );
        }
        final challan = matching[index - 2];
        return ChallanTile(
          challan: challan,
          selected: challan.id == widget.selectedId,
          onTap: () =>
              openInPane(context, ChallanDetailRoute(challan.id).location),
        );
      },
    );
  }
}
