import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clients/models/client.dart';
import '../../../core/clients/providers/client_providers.dart';
import '../../../core/export/xlsx_writer.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/share_file.dart';
import '../../../core/widgets/guarded_save.dart';
import '../../../core/widgets/menu_chip.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/section_header.dart';
import '../challan_search.dart';
import '../export/challan_exports.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/challan_tile.dart';
import 'widgets/client_filter_chip.dart';

/// Search every financial year by text, clients, dates and direction, with
/// the results grouped by client and exportable as spreadsheets.
///
/// Wide windows ([inListPane]): the left pane, with the results staying put
/// while a result is open on the right ([selectedId] is highlighted). Phones:
/// a page of its own; a result opens on top, and back returns here.
/// What's being searched for lives in [challanSearchQueryProvider], so it
/// survives either.
class ChallanSearchPage extends ConsumerStatefulWidget {
  const ChallanSearchPage({
    super.key,
    this.inListPane = false,
    this.selectedId,
  });

  final bool inListPane;
  final String? selectedId;

  @override
  ConsumerState<ChallanSearchPage> createState() => _ChallanSearchPageState();
}

class _ChallanSearchPageState extends ConsumerState<ChallanSearchPage> {
  late final _textController = TextEditingController(
    text: ref.read(challanSearchQueryProvider).text,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  ChallanSearchQuery get _query =>
      ref.read(challanSearchQueryProvider.notifier);

  Future<void> _pickDates(ChallanSearchFilters query) async {
    final from = query.from;
    final to = query.to;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: from == null || to == null
          ? null
          : DateTimeRange(start: from, end: to),
      firstDate: DateTime(2018),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked == null) return;
    _query.set(
      ref
          .read(challanSearchQueryProvider)
          .copyWith(from: picked.start, to: picked.end),
    );
  }

  /// Back to the list (wide), clearing the search for next time.
  void _close() {
    _query.clear();
    ref.read(challanSearchOpenProvider.notifier).set(open: false);
    if (GoRouterState.of(context).matchedLocation ==
        const ChallanSearchRoute().location) {
      context.go(const ChallansRoute().location);
    }
  }

  Future<void> _export(List<Challan> results, {required bool detailed}) async {
    await runGuardedAction(() async {
      if (detailed) {
        final withItems = await ref
            .read(challanRepositoryProvider)
            .withItems(results);
        await shareGeneratedFile(
          bytes: buildDetailedExport(withItems),
          fileName: 'challans.xlsx',
          mimeType: xlsxMimeType,
        );
      } else {
        await shareGeneratedFile(
          bytes: buildIndexExport(results),
          fileName: 'challans_index.xlsx',
          mimeType: xlsxMimeType,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientListProvider).value ?? const <Client>[];
    final query = ref.watch(challanSearchQueryProvider);
    final resultsAsync = query.isEmpty
        ? null
        : ref.watch(challanSearchProvider(query));
    final results = resultsAsync?.value ?? const <Challan>[];
    final from = query.from;
    final to = query.to;

    final exportMenu = results.isEmpty
        ? null
        : OverflowMenu(
            icon: Icons.file_download_outlined,
            tooltip: 'Export',
            items: [
              OverflowMenuItem(
                icon: Icons.table_rows_outlined,
                label: 'Detailed spreadsheet',
                onPressed: () => _export(results, detailed: true),
              ),
              OverflowMenuItem(
                icon: Icons.format_list_numbered,
                label: 'Index spreadsheet',
                onPressed: () => _export(results, detailed: false),
              ),
            ],
          );

    final PreferredSizeWidget appBar;
    if (widget.inListPane) {
      appBar = AppBar(
        leading: BackButton(onPressed: _close),
        title: const Text('Search'),
        actions: [?exportMenu],
      );
    } else {
      appBar = PaneAppBar(
        title: 'Search challans',
        parentLocation: const ChallansRoute().location,
        actions: [?exportMenu],
      );
    }

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _textController,
              autoFocus: query.isEmpty,
              hintText: widget.inListPane
                  ? 'Number, name, address, item, …'
                  : 'Number, name, address, item, serial, vehicle, bill no.',
              leading: const Icon(Icons.search),
              onSubmitted: (value) => _query.set(
                ref
                    .read(challanSearchQueryProvider)
                    .copyWith(text: value.trim()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClientFilterChip(
                  clients: clients,
                  value: ClientFilter(
                    clientIds: query.clientIds.toSet(),
                    addressIds: query.addressIds.toSet(),
                  ),
                  onChanged: (filter) => _query.set(
                    ref
                        .read(challanSearchQueryProvider)
                        .copyWith(
                          clientIds: filter.clientIds.toList()..sort(),
                          addressIds: filter.addressIds.toList()..sort(),
                        ),
                  ),
                ),
                InputChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    from == null || to == null
                        ? 'Any date'
                        : '${formatDisplayDate(from)} – '
                              '${formatDisplayDate(to)}',
                  ),
                  onPressed: () => _pickDates(query),
                  onDeleted: from == null
                      ? null
                      : () => _query.set(
                          ref
                              .read(challanSearchQueryProvider)
                              .copyWith(from: null, to: null),
                        ),
                ),
                MenuChip<ChallanDirection?>(
                  icon: Icons.swap_vert,
                  label: query.direction?.label ?? 'Any direction',
                  selected: query.direction,
                  options: [
                    const MenuChipOption(null, 'Outward and inward'),
                    for (final option in ChallanDirection.values)
                      MenuChipOption(option, option.label),
                  ],
                  onSelected: (picked) => _query.set(
                    ref
                        .read(challanSearchQueryProvider)
                        .copyWith(direction: picked),
                  ),
                ),
              ],
            ),
          ),
          if (resultsAsync == null)
            const _Message(
              'Type and press Enter, or pick clients or dates, to search '
              'every year.',
            )
          else
            resultsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _Message('$error'),
              data: (challans) => _Results(
                challans: challans,
                selectedId: widget.selectedId,
                inListPane: widget.inListPane,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// "CLIENT · 3", or "CLIENT · Sector 5 · 3" when the client's results are
/// split by address.
String _groupHeading(ClientChallans group) {
  final count = group.challans.length;
  final label = group.addressLabel;
  if (label == null) return '${group.clientName} · $count';
  return '${group.clientName} · $label · $count';
}

/// The results grouped by client (and by address, for a client with
/// challans to several), newest first within each.
class _Results extends StatelessWidget {
  const _Results({
    required this.challans,
    required this.selectedId,
    required this.inListPane,
  });

  final List<Challan> challans;
  final String? selectedId;

  /// A result opens in the right pane (wide), or on top of this page.
  final bool inListPane;

  /// The search returns at most this many (see search_challans).
  static const _limit = 1000;

  @override
  Widget build(BuildContext context) {
    if (challans.isEmpty) return const _Message('No challans match');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (challans.length >= _limit)
          const _Message(
            'Showing the newest 1000. Narrow the search to see older ones.',
          ),
        for (final group in groupByClient(challans)) ...[
          SectionHeader(_groupHeading(group)),
          for (final challan in group.challans)
            ChallanTile(
              challan: challan,
              showDirection: true,
              selected: challan.id == selectedId,
              onTap: () {
                final location = ChallanDetailRoute(challan.id).location;
                if (inListPane) {
                  context.go(location);
                } else {
                  context.push(location);
                }
              },
            ),
        ],
      ],
    );
  }
}
