import 'package:flutter/material.dart';

import '../layout/window_size.dart';

/// A bottom sheet on phones, a centred dialog on wide windows — M3's guidance
/// is that bottom sheets are a compact-screen pattern; on desktop a sheet
/// sliding up mid-screen reads as broken. The content is the same either way
/// and resolves the same way (`Navigator.pop(value)`).
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (context.isTwoPane) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: builder,
  );
}
