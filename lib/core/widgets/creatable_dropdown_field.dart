import 'package:flutter/material.dart';

import '../utils/status_metadata.dart';

/// "Pick an existing value or create a new one", as an M3 editable dropdown
/// menu (DropdownMenuFormField): typing filters the menu, arrows + Enter pick,
/// Esc closes. When the typed text matches nothing, the menu's last row is
/// "+ Add 'whatever was typed'", so creating a new value is a visible choice
/// rather than a silent side effect of a typo.
///
/// [options] are stored values (ids/slugs), shown via [displayLabel].
/// [onChanged] reports the current value on every change: the stored option
/// when the text matches one, otherwise the typed text (a new value).
class CreatableDropdownField extends StatefulWidget {
  const CreatableDropdownField({
    super.key,
    required this.options,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.fieldKey,
    this.helperText,
    this.validator,
    this.autofocus = false,
  });

  final List<String> options;
  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final Key? fieldKey;
  final String? helperText;

  /// Gets the current value (as reported by [onChanged]), not the selection.
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  @override
  State<CreatableDropdownField> createState() => _CreatableDropdownFieldState();
}

class _CreatableDropdownFieldState extends State<CreatableDropdownField> {
  late final _controller = TextEditingController(
    text: widget.initialValue == null ? '' : displayLabel(widget.initialValue!),
  );
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  /// The stored option the text names, if any (case-insensitive).
  String? get _matchingOption {
    final query = _text.toLowerCase();
    for (final option in widget.options) {
      if (displayLabel(option).toLowerCase() == query) return option;
    }
    return null;
  }

  String get _value => _matchingOption ?? _text;

  void _onTextChanged() {
    widget.onChanged(_value);
    setState(() {}); // re-filter the entries
  }

  // Filtered here rather than with enableFilter: the "Add" row depends on the
  // text, so the entry list changes as you type anyway.
  List<DropdownMenuEntry<String>> get _entries {
    final query = _text.toLowerCase();
    final matches = [
      for (final option in widget.options)
        if (query.isEmpty || displayLabel(option).toLowerCase().contains(query))
          DropdownMenuEntry(value: option, label: displayLabel(option)),
    ];
    if (_text.isNotEmpty && _matchingOption == null) {
      matches.add(
        DropdownMenuEntry(
          value: _text,
          // label fills the field when picked; labelWidget is what's shown.
          label: _text,
          labelWidget: Text("Add '$_text'"),
          leadingIcon: const Icon(Icons.add),
        ),
      );
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenuFormField<String>(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      dropdownMenuEntries: _entries,
      requestFocusOnTap: true,
      enableSearch: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      label: Text(widget.label),
      helperText: widget.helperText,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(_value),
    );
  }
}
