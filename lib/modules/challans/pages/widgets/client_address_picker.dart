import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/models/client_address.dart';
import '../../../../core/clients/providers/client_providers.dart';
import '../../../../core/clients/routes.dart';
import '../../../../core/layout/window_size.dart';

/// The client address a challan goes to, as shown in the form.
class AddressChoice {
  const AddressChoice({
    required this.addressId,
    required this.clientName,
    required this.addressLabel,
    required this.nameOnChallan,
    required this.address,
    required this.stateName,
    required this.gstin,
  });

  AddressChoice.of(Client client, ClientAddress address)
    : addressId = address.addressId,
      clientName = client.name,
      addressLabel = address.label,
      nameOnChallan = address.nameOnChallan,
      address = address.address,
      stateName = address.stateName,
      gstin = address.gstin;

  final String addressId;
  final String clientName;
  final String addressLabel;
  final String nameOnChallan;
  final String address;
  final String stateName;
  final String? gstin;

  /// "Main · Delhi": which of the client's addresses.
  String get title => '$addressLabel · $stateName';

  /// What prints, in one line: name on challan, the address's first line and
  /// the GSTIN.
  String get printedSummary {
    final firstLine = address.split('\n').first.trim();
    return [
      nameOnChallan,
      firstLine,
      gstin ?? '',
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}

/// Form field for the client and address. On wide windows it's a type-ahead:
/// focus it (click or Tab) and type, and the client addresses that match
/// drop down under it, grouped by client; ↑/↓ and Enter pick one. On phones
/// a tap opens the same list as a full-screen search.
class ClientAddressField extends FormField<AddressChoice> {
  ClientAddressField({
    super.key,
    super.initialValue,
    required ValueChanged<AddressChoice> onChanged,
  }) : super(
         validator: (value) => value == null ? 'Pick the client' : null,
         builder: (field) {
           void pick(AddressChoice choice) {
             field.didChange(choice);
             onChanged(choice);
           }

           if (field.context.windowSize == WindowSize.compact) {
             return _TapToSearchField(
               value: field.value,
               errorText: field.errorText,
               onPicked: pick,
             );
           }
           return _TypeAheadField(
             value: field.value,
             errorText: field.errorText,
             onPicked: pick,
           );
         },
       );
}

/// One row of the list: a client address, or, when the search matches
/// none, the row that says so.
class _PickerOption {
  const _PickerOption.address(AddressChoice this.choice);
  const _PickerOption.noMatch() : choice = null;

  /// Null for the "no clients match" row.
  final AddressChoice? choice;
}

bool _matches(Client client, ClientAddress address, String query) {
  if (query.isEmpty) return true;
  final fields = [
    client.name,
    client.notes ?? '',
    address.label,
    address.nameOnChallan,
    address.address,
    address.stateName,
    address.gstin ?? '',
  ];
  return fields.any((field) => field.toLowerCase().contains(query));
}

/// Every active address of every active client that matches [query], in
/// client order (so each client's addresses sit together). "New client" isn't
/// one of them: it's a footer under the list, so ↑/↓ and Enter only ever
/// land on an address.
List<_PickerOption> _optionsFor(List<Client> clients, String query) {
  final normalized = query.trim().toLowerCase();
  final options = [
    for (final client in clients)
      if (!client.isArchived)
        for (final address in client.addresses)
          if (!address.isArchived && _matches(client, address, normalized))
            _PickerOption.address(AddressChoice.of(client, address)),
  ];
  // Keeps the list open, so "New client" stays in reach.
  if (options.isEmpty) return const [_PickerOption.noMatch()];
  return options;
}

/// The new client form is in the Clients section; the challan form waits
/// in Challans, as typed, until you come back to pick the client.
void _openNewClient(BuildContext context) => const ClientNewRoute().go(context);

/// Under the field once a client is picked: which address, and what prints.
Widget? _pickedDetails(BuildContext context, AddressChoice? value) {
  if (value == null) return null;
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value.title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      Text(
        value.printedSummary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _TypeAheadField extends ConsumerStatefulWidget {
  const _TypeAheadField({
    required this.value,
    required this.errorText,
    required this.onPicked,
  });

  final AddressChoice? value;
  final String? errorText;
  final ValueChanged<AddressChoice> onPicked;

  @override
  ConsumerState<_TypeAheadField> createState() => _TypeAheadFieldState();
}

class _TypeAheadFieldState extends ConsumerState<_TypeAheadField> {
  late final _controller = TextEditingController(
    text: widget.value?.clientName ?? '',
  );
  final _focusNode = FocusNode();

  /// The pick, kept here as well: focus moves on straight after a pick,
  /// before the form passes the new [widget.value] down.
  late AddressChoice? _picked = widget.value;

  @override
  void didUpdateWidget(_TypeAheadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _picked = widget.value;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// In: select the name, so typing searches afresh. Out without picking:
  /// put the picked client's name back.
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _controller.text = _picked?.clientName ?? '';
    }
  }

  /// The picked client's name still in the field means nothing has been
  /// typed yet: show everyone.
  String get _query {
    final text = _controller.text;
    if (text == _picked?.clientName) return '';
    return text;
  }

  void _onSelected(_PickerOption option) {
    // Enter on "no clients match": nothing to pick.
    final choice = option.choice;
    if (choice == null) return;
    _picked = choice;
    widget.onPicked(choice);
    // On to the next field, which also closes the list.
    _focusNode.nextFocus();
  }

  void _newClient() {
    _focusNode.unfocus();
    _openNewClient(context);
  }

  /// Typing changes the matches; the highlight goes back to the first, as
  /// Flutter's autocomplete would otherwise keep its old position.
  void _highlightFirstMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = _focusNode.context;
      if (fieldContext == null) return;
      Actions.maybeInvoke(fieldContext, const AutocompleteFirstOptionIntent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientListProvider).value;

    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<_PickerOption>(
        textEditingController: _controller,
        focusNode: _focusNode,
        optionsBuilder: (_) {
          if (clients == null) return const [];
          return _optionsFor(clients, _query);
        },
        displayStringForOption: (option) =>
            option.choice?.clientName ?? _controller.text,
        onSelected: _onSelected,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Client',
                hintText: 'Type to search clients',
                errorText: widget.errorText,
                helper: _pickedDetails(context, widget.value),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              onChanged: (_) => _highlightFirstMatch(),
              onSubmitted: (_) => onSubmitted(),
              // Enter picks the highlighted address, and the pick moves on
              // to the next field; the keyboard's own Enter handling would
              // drop focus first.
              textInputAction: TextInputAction.next,
              onEditingComplete: () {},
            ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          // A menu's container tone and a thin outline, so it stands apart
          // from the form behind it.
          child: Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: constraints.maxWidth,
              ),
              child: _OptionList(
                options: options.toList(),
                onSelected: onSelected,
                onNewClient: _newClient,
                highlightedIndex: AutocompleteHighlightedOption.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phones: the field shows the pick; a tap opens a full-screen search.
class _TapToSearchField extends StatelessWidget {
  const _TapToSearchField({
    required this.value,
    required this.errorText,
    required this.onPicked,
  });

  final AddressChoice? value;
  final String? errorText;
  final ValueChanged<AddressChoice> onPicked;

  Future<void> _search(BuildContext context) async {
    final result = await showDialog<_SearchResult>(
      context: context,
      useSafeArea: false,
      builder: (_) => const Dialog.fullscreen(child: _FullScreenSearch()),
    );
    if (result == null || !context.mounted) return;
    final choice = result.choice;
    if (choice == null) {
      _openNewClient(context);
    } else {
      onPicked(choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = value;
    return InkWell(
      onTap: () => _search(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Client',
          errorText: errorText,
          helper: _pickedDetails(context, picked),
          suffixIcon: const Icon(Icons.search),
        ),
        isEmpty: picked == null,
        child: picked == null ? null : Text(picked.clientName),
      ),
    );
  }
}

/// What the full-screen search closes with: an address, or (null) "New
/// client".
class _SearchResult {
  const _SearchResult(this.choice);

  final AddressChoice? choice;
}

class _FullScreenSearch extends ConsumerStatefulWidget {
  const _FullScreenSearch();

  @override
  ConsumerState<_FullScreenSearch> createState() => _FullScreenSearchState();
}

class _FullScreenSearchState extends ConsumerState<_FullScreenSearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final clients = clientsAsync.value;

    final Widget body;
    if (clientsAsync.hasError) {
      body = Center(child: Text('${clientsAsync.error}'));
    } else if (clients == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _OptionList(
        options: _optionsFor(clients, _query),
        onSelected: (option) {
          final choice = option.choice;
          if (choice != null) Navigator.of(context).pop(_SearchResult(choice));
        },
        onNewClient: () => Navigator.of(context).pop(const _SearchResult(null)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Search clients, addresses, GSTIN',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

/// The addresses grouped by client (the client's name above its first
/// address), then "New client".
class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.options,
    required this.onSelected,
    required this.onNewClient,
    this.highlightedIndex,
  });

  final List<_PickerOption> options;
  final ValueChanged<_PickerOption> onSelected;
  final VoidCallback onNewClient;

  /// The row ↑/↓ are on (type-ahead only).
  final int? highlightedIndex;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      // The rows, then the "New client" footer.
      itemCount: options.length + 1,
      itemBuilder: (context, index) {
        if (index == options.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              _OptionRow(
                highlighted: false,
                onTap: onNewClient,
                child: const Row(
                  spacing: 12,
                  children: [Icon(Icons.add), Text('New client')],
                ),
              ),
            ],
          );
        }

        final choice = options[index].choice;
        if (choice == null) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('No clients match'),
          );
        }

        final previous = index > 0 ? options[index - 1].choice : null;
        final startsClient = previous?.clientName != choice.clientName;
        return _AddressOption(
          choice: choice,
          showClientName: startsClient,
          highlighted: index == highlightedIndex,
          onTap: () => onSelected(options[index]),
        );
      },
    );
  }
}

class _AddressOption extends StatelessWidget {
  const _AddressOption({
    required this.choice,
    required this.showClientName,
    required this.highlighted,
    required this.onTap,
  });

  final AddressChoice choice;

  /// On the first of a client's addresses.
  final bool showClientName;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showClientName)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              choice.clientName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        _OptionRow(
          highlighted: highlighted,
          onTap: onTap,
          indent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(choice.title, style: theme.textTheme.bodyLarge),
              Text(
                choice.printedSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable row, tinted while ↑/↓ are on it and scrolled into view.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.highlighted,
    required this.onTap,
    required this.child,
    this.indent = false,
  });

  final bool highlighted;
  final VoidCallback onTap;
  final Widget child;

  /// Addresses sit under their client's name.
  final bool indent;

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(context, alignment: 0.5);
        }
      });
    }

    final colors = Theme.of(context).colorScheme;
    return Material(
      color: highlighted ? colors.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 8, 16, 8),
          child: child,
        ),
      ),
    );
  }
}
