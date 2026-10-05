import 'package:flutter/material.dart';

import '../utils/date_time_format.dart';

/// A date field that looks like the other text fields: read-only text plus a
/// calendar button. The button is focusable, so keyboard users can open the
/// picker too (a tap-only field can't be reached with Tab + Enter).
class DateFormField extends StatefulWidget {
  const DateFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fieldKey,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final Key? fieldKey;

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  late final _controller = TextEditingController(
    text: formatDisplayDate(widget.value),
  );

  @override
  void didUpdateWidget(DateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = formatDisplayDate(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      readOnly: true,
      onTap: _pick,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Pick date',
          onPressed: _pick,
        ),
      ),
    );
  }
}

/// Time counterpart of [DateFormField]: same look, keyboard-reachable picker.
class TimeFormField extends StatefulWidget {
  const TimeFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<TimeFormField> createState() => _TimeFormFieldState();
}

class _TimeFormFieldState extends State<TimeFormField> {
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.text = widget.value.format(context);
  }

  @override
  void didUpdateWidget(TimeFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = widget.value.format(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.value,
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _pick,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          tooltip: 'Pick time',
          onPressed: _pick,
        ),
      ),
    );
  }
}
