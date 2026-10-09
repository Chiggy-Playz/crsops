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
/// the results grouped by client and exportable as spreadsheets. Opening a
/// result stacks it on top, so back returns here with the search intact.
class ChallanSearchPage extends ConsumerStatefulWidget {
  const ChallanSearchPage({super.key});

  @override
  ConsumerState<ChallanSearchPage> createState() => _ChallanSearchPageState();
}

class _ChallanSearchPageState extends ConsumerState<ChallanSearchPage> {
  String _text = '';
  ClientFilter _clientFilter = const ClientFilter();
  DateTimeRange? _dates;
  ChallanDirection? _direction;

  /// The filters searched for; null until there's something to search by.
  ChallanSearchFilters? get _filters {
    final filters = ChallanSearchFilters(
      text: _text,
      clientIds: _clientFilter.clientIds.toList()..sort(),
      addressIds: _clientFilter.addressIds.toList()..sort(),
      from: _dates?.start,
      to: _dates?.end,
      direction: _direction,
    );
    return filters.isEmpty ? null : filters;
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dates,
      firstDate: DateTime(2018),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked != null) setState(() => _dates = picked);
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
    final filters = _filters;
    final resultsAsync = filters == null
        ? null
        : ref.watch(challanSearchProvider(filters));
    final results = resultsAsync?.value ?? const <Challan>[];
    final dates = _dates;

    return Scaffold(
      appBar: PaneAppBar(
        title: 'Search challans',
        parentLocation: const ChallansRoute().location,
        actions: [
          if (results.isNotEmpty)
            OverflowMenu(
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
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              autoFocus: true,
              hintText:
                  'Number, name, address, item, serial, vehicle, bill no.',
              leading: const Icon(Icons.search),
              onSubmitted: (value) => setState(() => _text = value.trim()),
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
                  value: _clientFilter,
                  onChanged: (filter) => setState(() => _clientFilter = filter),
                ),
                InputChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    dates == null
                        ? 'Any date'
                        : '${formatDisplayDate(dates.start)} – '
                              '${formatDisplayDate(dates.end)}',
                  ),
                  onPressed: _pickDates,
                  onDeleted: dates == null
                      ? null
                      : () => setState(() => _dates = null),
                ),
                MenuChip<ChallanDirection?>(
                  icon: Icons.swap_vert,
                  label: _direction?.label ?? 'Outward and inward',
                  selected: _direction,
                  options: [
                    const MenuChipOption(null, 'Outward and inward'),
                    for (final option in ChallanDirection.values)
                      MenuChipOption(option, option.label),
                  ],
                  onSelected: (picked) => setState(() => _direction = picked),
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
              data: (challans) => _Results(challans: challans),
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
  const _Results({required this.challans});

  final List<Challan> challans;

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
              onTap: () =>
                  context.push(ChallanDetailRoute(challan.id).location),
            ),
        ],
      ],
    );
  }
}
