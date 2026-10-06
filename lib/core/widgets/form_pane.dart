import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../layout/two_pane_layout.dart';
import '../layout/window_size.dart';
import 'confirm_dialog.dart';

/// Shell for a long form (a challan, a client) that is a page of its own
/// rather than a dialog: the right pane on wide windows, with the list still
/// beside it, and a full page on phones. Short forms keep [FormDialog].
///
/// ✕ and the title on the left, Save on the right of the top bar, so both
/// stay in reach however far the form scrolls. Keyboard: Esc closes,
/// Ctrl/⌘+Enter saves. Save stays enabled; [onSave] validates and the fields
/// show what's missing.
///
/// Leaving with unsaved changes asks first: the form's route calls
/// [confirmLeavingForm] from its `onExit`, which asks [hasUnsavedChanges].
class FormPane extends StatefulWidget {
  const FormPane({
    super.key,
    required this.title,
    required this.formKey,
    required this.saving,
    required this.onSave,
    required this.hasUnsavedChanges,
    required this.closeLocation,
    required this.children,
    this.description,
    this.onChanged,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final VoidCallback onSave;

  /// Whether leaving now would lose something typed.
  final bool Function() hasUnsavedChanges;

  /// Where ✕ goes when there's no page underneath to go back to (opened
  /// from a link).
  final String closeLocation;

  /// Called whenever a field of the form changes.
  final VoidCallback? onChanged;

  /// One line of context under the title.
  final String? description;
  final List<Widget> children;

  @override
  State<FormPane> createState() => _FormPaneState();
}

/// The forms on screen, by the page they're on, so a route's `onExit` can
/// ask the right one. (Every visited section stays alive, so a challan form
/// and a client form can both be open, each in its own section.)
final _openForms = <LocalKey, bool Function()>{};

/// For a form route's `onExit`: lets it go, or asks first if the form on it
/// has unsaved changes.
Future<bool> confirmLeavingForm(
  BuildContext context,
  GoRouterState state,
) async {
  final hasUnsavedChanges = _openForms[state.pageKey];
  if (hasUnsavedChanges == null || !hasUnsavedChanges()) return true;
  return showConfirmDialog(
    context,
    title: 'Discard changes?',
    message: "What you've entered here hasn't been saved.",
    confirmLabel: 'Discard',
    isDestructive: true,
  );
}

class _FormPaneState extends State<FormPane> {
  LocalKey? _pageKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pageKey = GoRouterState.of(context).pageKey;
    if (pageKey != _pageKey) {
      _unregister();
      _pageKey = pageKey;
      _openForms[pageKey] = () => widget.hasUnsavedChanges();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _unregister() {
    final pageKey = _pageKey;
    if (pageKey != null) _openForms.remove(pageKey);
  }

  void _save() {
    if (!widget.saving) widget.onSave();
  }

  /// Back to the page underneath (the route's `onExit` asks first if
  /// anything is unsaved).
  void _close() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(widget.closeLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = context.windowSize == WindowSize.compact;
    final isMac = theme.platform == TargetPlatform.macOS;

    final saveIndicator = widget.saving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Save');
    final saveButton = Tooltip(
      message: 'Save (${isMac ? '⌘' : 'Ctrl'}+Enter)',
      child: isCompact
          ? TextButton(
              onPressed: widget.saving ? null : _save,
              child: saveIndicator,
            )
          : FilledButton(
              onPressed: widget.saving ? null : _save,
              child: saveIndicator,
            ),
    );

    final description = widget.description;
    final double sidePadding;
    if (isCompact) {
      sidePadding = 16;
    } else {
      sidePadding = 24;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: _close),
          title: Text(widget.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: saveButton,
            ),
          ],
        ),
        body: Form(
          key: widget.formKey,
          onChanged: widget.onChanged,
          child: ListView(
            padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 32),
            children: [
              MaxWidthBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (description != null) ...[
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final (i, child) in widget.children.indexed) ...[
                      if (i > 0) const SizedBox(height: 16),
                      child,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two fields side by side when there's room, one above the other when
/// there isn't.
class FieldPair extends StatelessWidget {
  const FieldPair({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });

  final Widget first;
  final Widget second;

  /// How the width is shared, side by side.
  final int firstFlex;
  final int secondFlex;

  /// Narrower than this, the fields stack.
  static const double sideBySideWidth = 560;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < sideBySideWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [first, second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Expanded(flex: firstFlex, child: first),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}
