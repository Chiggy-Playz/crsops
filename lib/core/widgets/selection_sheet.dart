import 'package:flutter/material.dart';

class SelectionOption<T> {
  const SelectionOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// "Pick one of a few" as a modal bottom sheet: a title, then the options as
/// one bordered group with the current one highlighted. Resolves to the picked
/// value, or null if dismissed (callers treat null as "no change").
Future<T?> showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectionOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _OptionGroup(options: options, selected: selected),
          ],
        ),
      ),
    ),
  );
}

class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({required this.options, required this.selected});

  final List<SelectionOption<T>> options;
  final T selected;

  static const _radius = Radius.circular(12);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // One rounded outline around the whole group, dividers between rows —
    // ClipRRect keeps the selected row's tint inside the rounded corners.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.all(_radius),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(_radius),
        // ListTile paints its tint/ripple on the nearest Material — give it
        // one inside the clip, or the sheet's Material paints square corners.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: colorScheme.outlineVariant),
                _OptionTile(
                  option: options[i],
                  isSelected: options[i].value == selected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({required this.option, required this.isSelected});

  final SelectionOption<T> option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The tint alone isn't announced by screen readers — `selected` is, and
    // the check mark covers users who can't rely on colour.
    return ListTile(
      selected: isSelected,
      selectedColor: colorScheme.onPrimaryContainer,
      selectedTileColor: colorScheme.primaryContainer,
      leading: option.icon == null ? null : Icon(option.icon),
      title: Text(option.label),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(option.value),
    );
  }
}
