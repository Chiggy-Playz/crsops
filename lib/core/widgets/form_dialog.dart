import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shell for a multi-field form, following M3's adaptive dialog guidance:
/// - compact width (phones): a full-screen dialog — ✕ and title on the left,
///   Save in the top app bar — so fields get the full width and the form
///   scrolls above the keyboard;
/// - wider (desktop, web, tablets): a centred dialog, at most 560 px wide,
///   with Cancel / Save at the bottom.
///
/// Keyboard: Esc closes (dialog default), Ctrl/⌘+Enter saves, Tab walks the
/// fields. Save stays enabled; [onSave] validates and the fields show what's
/// missing, rather than a greyed-out button that can't say why.
/// Opens a [FormDialog]-based form. Always use this (not bare showDialog):
/// `useSafeArea: false` lets the full-screen form paint under the status and
/// navigation bars — otherwise the dimmed scrim shows in those strips.
Future<T?> showFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, useSafeArea: false, builder: builder);

class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.saving,
    required this.onSave,
    required this.children,
    this.description,
    this.saveButtonKey,
    this.saveLabel = 'Save',
  });

  static const double compactBreakpoint = 600;
  static const double maxWidth = 560;

  final String title;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> children;

  /// One line of context under the title — who or what the form is about
  /// (e.g. "For dad@example.com · currently Admin").
  final String? description;
  final Key? saveButtonKey;

  /// The confirm button's text — "Save" for forms, e.g. "Apply" for pickers.
  final String saveLabel;

  /// Whether forms open full-screen at this size — callers use it to skip
  /// autofocus on phones, where it would pop the keyboard over the form.
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  void _save() {
    if (!saving) onSave();
  }

  @override
  Widget build(BuildContext context) {
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    final saveTooltip = '$saveLabel (${isMac ? '⌘' : 'Ctrl'}+Enter)';

    final form = Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        shrinkWrap: true,
        children: [
          if (description != null) ...[
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );

    final saveIndicator = saving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(saveLabel);

    final Widget dialog;
    if (isCompact(context)) {
      dialog = Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: saveTooltip,
                  child: TextButton(
                    key: saveButtonKey,
                    onPressed: saving ? null : _save,
                    child: saveIndicator,
                  ),
                ),
              ),
            ],
          ),
          // The app bar already pads for the status bar; this keeps the
          // last field clear of the gesture/navigation bar.
          body: SafeArea(top: false, child: form),
        ),
      );
    } else {
      dialog = Dialog(
        insetPadding:
            MediaQuery.paddingOf(context) +
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Flexible(child: form),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: saveTooltip,
                      child: FilledButton(
                        key: saveButtonKey,
                        onPressed: saving ? null : _save,
                        child: saveIndicator,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
      },
      child: dialog,
    );
  }
}

/// A date field that looks like the other text fields: read-only text plus a
/// calendar button. The button is focusable, so keyboard users can open the
/// picker too (a tap-only field can't be reached with Tab + Enter).
class DateFormField extends StatefulWidget {
  const DateFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.format,
    this.fieldKey,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String Function(DateTime) format;
  final Key? fieldKey;

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  late final _controller = TextEditingController(
    text: widget.format(widget.value),
  );

  @override
  void didUpdateWidget(DateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = widget.format(widget.value);
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

/// An outlined, labelled box for non-text inputs (swatches, chips) so they
/// line up with the text fields around them instead of floating under a
/// plain Text label.
class LabelledFieldBox extends StatelessWidget {
  const LabelledFieldBox({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      ),
      child: child,
    );
  }
}
