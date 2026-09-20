import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';

class StatusTypesManagerPage extends ConsumerWidget {
  const StatusTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(statusTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance status types')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(type.colorHex),
                child: Icon(iconFor(type.iconName), color: Colors.white),
              ),
              title: Text(type.label),
            );
          },
        ),
      ),
    );
  }
}
