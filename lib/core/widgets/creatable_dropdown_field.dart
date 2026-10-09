import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/status_metadata.dart';

/// "Pick an existing value or create a new one", as an M3 editable dropdown
/// menu (DropdownMenuFormField): typing filters the menu, arrows + Enter pick,
/// Esc closes. When the typed text matches nothing, the menu's last row is
/// "+ Add 'whatever was typed'", so creating a new value is a visible choice
/// rather than a silent side effect of a typo.
///
/// [options] are stored values, shown via [labelFor]: by default
/// [displayLabel], for ids/slugs like "paid_leave"; [plainText] for values
/// that are already what people typed (names, units). [onChanged] reports the
/// current value on every change: the stored option when the text matches
/// one, otherwise the typed text (a new value).
class CreatableDropdownField extends StatefulWidget {
  const CreatableDropdownField({
    super.key,
    required this.options,
    this.label,
    this.onChanged,
    this.controller,
    this.labelFor = displayLabel,
    this.dense = false,
    this.onEnter,
    this.initialValue,
    this.fieldKey,
    this.helperText,
    this.validator,
    this.autofocus = false,
  });

  /// For [labelFor]: show values exactly as stored.
  static String plainText(String value) => value;

  final List<String> options;

  /// Null in a table cell, where the column heading names the field.
  final String? label;
  final ValueChanged<String>? onChanged;

  /// The text, when the form keeps its own controller (then [initialValue]
  /// is ignored, and the controller is the form's to dispose).
  final TextEditingController? controller;
  final String Function(String value) labelFor;

  /// Compact, for a row of a table.
  final bool dense;

  /// Enter pressed in the field (after the menu's own handling of it).
  final VoidCallback? onEnter;
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
  late final TextEditingController _controller =
      widget.controller ??
      TextEditingController(
        text: widget.initialValue == null
            ? ''
            : widget.labelFor(widget.initialValue!),
      );
  late final _focusNode = FocusNode(onKeyEvent: _onKeyEvent);
  final _menuController = MenuController();

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // Esc with the menu closed is for whatever holds this field (a form
    // closing): the dropdown's own dismiss is off then, but would still stop
    // it on the way up.
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        !_menuController.isOpen) {
      Actions.maybeInvoke(context, const DismissIntent());
      return KeyEventResult.handled;
    }

    final onEnter = widget.onEnter;
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (onEnter != null && event is KeyDownEvent && isEnter) {
      // After the menu has taken the highlighted entry.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onEnter();
      });
    }
    return KeyEventResult.ignored;
  }

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
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  /// The stored option the text names, if any (case-insensitive).
  String? get _matchingOption {
    final query = _text.toLowerCase();
    for (final option in widget.options) {
      if (widget.labelFor(option).toLowerCase() == query) return option;
    }
    return null;
  }

  String get _value => _matchingOption ?? _text;

  void _onTextChanged() {
    widget.onChanged?.call(_value);
    setState(() {}); // re-filter the entries
  }

  // Filtered here rather than with enableFilter: the "Add" row depends on the
  // text, so the entry list changes as you type anyway.
  List<DropdownMenuEntry<String>> get _entries {
    final query = _text.toLowerCase();
    final matches = [
      for (final option in widget.options)
        if (query.isEmpty ||
            widget.labelFor(option).toLowerCase().contains(query))
          DropdownMenuEntry(value: option, label: widget.labelFor(option)),
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
    final label = widget.label;
    final theme = Theme.of(context);
    return DropdownMenuFormField<String>(
      inputDecorationTheme: widget.dense
          ? theme.inputDecorationTheme.copyWith(isDense: true)
          : null,
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      menuController: _menuController,
      dropdownMenuEntries: _entries,
      requestFocusOnTap: true,
      enableSearch: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      label: label == null ? null : Text(label),
      helperText: widget.helperText,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(_value),
    );
  }
}
