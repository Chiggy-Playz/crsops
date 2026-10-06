import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../history_text.dart';
import '../../models/challan.dart';
import '../../providers/challan_providers.dart';

final _time = DateFormat('h:mm a');

/// Everything that happened to a challan, newest first, with who did it.
class ChallanHistorySection extends ConsumerWidget {
  const ChallanHistorySection({super.key, required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(challanHistoryProvider(challan.id));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text('$error')),
      data: (events) => Column(
        children: [
          for (final event in events)
            Builder(
              builder: (context) {
                final text = describeChallanEvent(event, challan.direction);
                final local = event.createdAt.toLocal();
                final when =
                    '${formatDisplayDate(local)}, ${_time.format(local)}';
                final who = event.createdByEmail;
                return ListTile(
                  leading: Icon(_iconFor(event.eventType), color: muted),
                  title: Text(text.title),
                  subtitle: Text(
                    [
                      ...text.details,
                      who == null ? when : '$when · $who',
                    ].join('\n'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(String eventType) {
    switch (eventType) {
      case 'created':
        return Icons.add_circle_outline;
      case 'edited':
        return Icons.edit_outlined;
      case 'cancelled':
        return Icons.block;
      case 'received':
        return Icons.task_alt;
      case 'bill_number':
        return Icons.receipt_outlined;
      case 'digitally_signed':
        return Icons.draw_outlined;
      default:
        return Icons.history;
    }
  }
}
