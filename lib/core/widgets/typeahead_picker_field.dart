import 'package:flutter/material.dart';

import 'status_metadata.dart';

/// A "pick an existing value or type a new one" combobox — replaces the old
/// dropdown-plus-reveal-a-textfield "+ New type" pattern. Existing [options]
/// (stored ids/slugs) are shown filtered and title-cased via [displayLabel];
/// [onChanged] fires with whatever raw text is currently in the field, on
/// every keystroke and on selecting a suggestion, so the caller can just read
/// the latest value on save — an unmatched typed value is simply used as-is
/// (auto-creates a new one), with no separate "new" state to track.
class TypeaheadPickerField extends StatelessWidget {
  const TypeaheadPickerField({
    super.key,
    required this.options,
    required this.labelText,
    required this.onChanged,
    this.initialValue,
    this.fieldKey,
  });

  final List<String> options;
  final String labelText;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue == null ? '' : displayLabel(initialValue!)),
      optionsBuilder: (value) {
        if (value.text.isEmpty) return options;
        final query = value.text.toLowerCase();
        return options.where((o) => displayLabel(o).toLowerCase().contains(query));
      },
      displayStringForOption: displayLabel,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: labelText),
        onChanged: onChanged,
      ),
      onSelected: onChanged,
    );
  }
}
