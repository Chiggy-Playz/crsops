import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/window_size.dart';

/// Opens a [FormDialog]-based form. Always use this (not bare showDialog):
/// `useSafeArea: false` lets the full-screen form paint under the status and
/// navigation bars — otherwise the dimmed scrim shows in those strips.
Future<T?> showFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, useSafeArea: false, builder: builder);

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
      context.windowSize == WindowSize.compact;

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
