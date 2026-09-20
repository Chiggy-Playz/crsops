import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/attendance_providers.dart';

class ShiftDefaultsManagerPage extends ConsumerWidget {
  const ShiftDefaultsManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftDefaultsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift defaults')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (history) => ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            return ListTile(
              title: Text('${entry.defaultStart} – ${entry.defaultEnd}'),
              subtitle: Text(
                'Effective from ${entry.effectiveFrom.toIso8601String().split('T').first} · Week off: ${entry.weekOffDays}',
              ),
            );
          },
        ),
      ),
      // "Change from [date]" action (inserts a new effective-from row) is real
      // follow-on UI over the same addEffectiveFrom() repository call already
      // built — deferred to a later polish pass; the write path is already
      // fully implemented and independently usable once that form exists.
    );
  }
}
