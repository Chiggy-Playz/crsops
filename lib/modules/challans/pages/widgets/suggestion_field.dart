import 'package:flutter/material.dart';

/// A free-text field that offers [suggestions] matching what's typed (values
/// used before, like "Delivered by" names). Picking one fills the field;
/// anything else can still be typed.
class SuggestionField extends StatefulWidget {
  const SuggestionField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.label,
    this.helperText,
    this.validator,
    this.textCapitalization = TextCapitalization.characters,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String label;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<String> _matches(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.suggestions
        .where((s) => s.toLowerCase().contains(query))
        // Already typed in full: nothing to suggest.
        .where((s) => s.toLowerCase() != query)
        .take(8);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: _matches,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: widget.textCapitalization,
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: widget.helperText,
            ),
            validator: widget.validator,
            onFieldSubmitted: (_) => onSubmitted(),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
