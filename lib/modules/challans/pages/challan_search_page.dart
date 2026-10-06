import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clients/models/client.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/section_header.dart';
import '../challan_search.dart';
import '../models/challan_direction.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/challan_tile.dart';
import 'widgets/client_multi_picker.dart';

/// Search every financial year by text, clients, dates and direction.
/// Results are grouped by client. Opening one stacks the challan on top, so
/// back returns here with the search intact.
class ChallanSearchPage extends ConsumerStatefulWidget {
  const ChallanSearchPage({super.key});

  @override
  ConsumerState<ChallanSearchPage> createState() => _ChallanSearchPageState();
}

class _ChallanSearchPageState extends ConsumerState<ChallanSearchPage> {
  final _text = TextEditingController();
  List<Client> _clients = const [];
  DateTimeRange? _dates;
  ChallanDirection? _direction;

  /// The filters last searched for; null until the first search.
  ChallanSearchFilters? _applied;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _search() {
    final filters = ChallanSearchFilters(
      text: _text.text.trim(),
      clientIds: [for (final c in _clients) c.id],
      from: _dates?.start,
      to: _dates?.end,
      direction: _direction,
    );
    setState(() => _applied = filters.isEmpty ? null : filters);
  }

  Future<void> _pickClients() async {
    final picked = await showClientMultiPicker(context, selected: _clients);
    if (picked == null) return;
    setState(() => _clients = picked);
    _search();
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dates,
      firstDate: DateTime(2018),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() => _dates = picked);
    _search();
  }

  String get _clientsLabel {
    if (_clients.isEmpty) return 'All clients';
    if (_clients.length == 1) return _clients.single.name;
    return '${_clients.length} clients';
  }

  String get _datesLabel {
    final dates = _dates;
    if (dates == null) return 'Any date';
    return '${formatDisplayDate(dates.start)} – ${formatDisplayDate(dates.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PaneAppBar(
        title: 'Search challans',
        parentLocation: const ChallansRoute().location,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _text,
              autoFocus: true,
              hintText: 'Number, name, item, serial, vehicle, bill no.',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Search',
                  onPressed: _search,
                ),
              ],
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  avatar: const Icon(Icons.business_outlined),
                  label: Text(_clientsLabel),
                  selected: _clients.isNotEmpty,
                  onSelected: (_) => _pickClients(),
                ),
                FilterChip(
                  avatar: const Icon(Icons.date_range),
                  label: Text(_datesLabel),
                  selected: _dates != null,
                  onSelected: (_) => _pickDates(),
                  onDeleted: _dates == null
                      ? null
                      : () {
                          setState(() => _dates = null);
                          _search();
                        },
                ),
                for (final option in ChallanDirection.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: _direction == option,
                    onSelected: (selected) {
                      setState(() => _direction = selected ? option : null);
                      _search();
                    },
                  ),
              ],
            ),
          ),
          _Results(filters: _applied),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.filters});

  final ChallanSearchFilters? filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = filters;
    if (applied == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Type something, or pick clients or dates, to search every year.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final resultsAsync = ref.watch(challanSearchProvider(applied));
    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Padding(padding: const EdgeInsets.all(24), child: Text('$error')),
      data: (challans) {
        if (challans.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No challans match', textAlign: TextAlign.center),
          );
        }
        final groups = groupByClient(challans);
        final limitNote = challans.length >= 1000
            ? 'Showing the newest 1000. Narrow the search to see older ones.'
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (limitNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(limitNote),
              ),
            for (final group in groups) ...[
              SectionHeader('${group.clientName} · ${group.challans.length}'),
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
      },
    );
  }
}
