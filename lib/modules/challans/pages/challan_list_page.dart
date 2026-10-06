import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/layout/window_size.dart';
import '../../../core/widgets/list_action_row.dart';
import '../../../core/widgets/menu_chip.dart';
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
/// layout on wide ones, where [selectedId] is highlighted. One financial
/// year of one direction at a time; "Search all years" goes further.
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
    final newLabel = 'New ${direction.label.toLowerCase()} challan';

    final Widget list;
    final challans = challansAsync.value;
    if (challansAsync.hasError) {
      list = Center(child: Text('${challansAsync.error}'));
    } else if (challans != null) {
      list = _buildList(challans, direction, newLabel);
    } else {
      list = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Search all years',
            onPressed: () =>
                openInPane(context, const ChallanSearchRoute().location),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MenuChip<int>(
                  icon: Icons.calendar_month_outlined,
                  label: financialYearLabel(year),
                  selected: year,
                  options: [
                    for (final option in years)
                      MenuChipOption(option, financialYearLabel(option)),
                  ],
                  onSelected: (picked) => ref
                      .read(selectedFinancialYearProvider.notifier)
                      .select(picked),
                ),
                if (direction == ChallanDirection.outward)
                  FilterChip(
                    label: const Text('Not received'),
                    selected: _onlyNotReceived,
                    onSelected: (selected) =>
                        setState(() => _onlyNotReceived = selected),
                  ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
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

  Widget _buildList(
    List<Challan> challans,
    ChallanDirection direction,
    String newLabel,
  ) {
    final addRow = context.isTwoPane
        ? ListActionRow(
            icon: Icons.add,
            label: newLabel,
            onTap: () => ChallanNewRoute(direction: direction).push(context),
          )
        : null;

    final notReceivedOnly =
        _onlyNotReceived && direction == ChallanDirection.outward;
    final matching = challans.where((c) {
      if (notReceivedOnly && (c.receivedOn != null || c.isCancelled)) {
        return false;
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

    final leadingRows = [
      ?addRow,
      if (emptyMessage != null)
        Padding(padding: const EdgeInsets.all(16), child: Text(emptyMessage)),
    ];

    // A builder: a year can hold a few hundred challans.
    return ListView.builder(
      itemCount: leadingRows.length + matching.length,
      itemBuilder: (context, index) {
        if (index < leadingRows.length) return leadingRows[index];
        final challan = matching[index - leadingRows.length];
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
