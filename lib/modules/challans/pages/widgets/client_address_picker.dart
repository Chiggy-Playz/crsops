import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/models/client_address.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/clients/providers/client_providers.dart';
import '../../../../core/layout/window_size.dart';
import '../../../../core/widgets/adaptive_sheet.dart';

/// The client address a challan goes to, as shown in the form.
class AddressChoice {
  const AddressChoice({
    required this.addressId,
    required this.clientName,
    required this.addressLabel,
    required this.nameOnChallan,
    required this.stateName,
  });

  AddressChoice.of(Client client, ClientAddress address)
    : addressId = address.addressId,
      clientName = client.name,
      addressLabel = address.label,
      nameOnChallan = address.nameOnChallan,
      stateName = address.stateName;

  final String addressId;
  final String clientName;
  final String addressLabel;
  final String nameOnChallan;
  final String stateName;
}

/// Form field for the client and address: shows the pick, and opens a
/// searchable list of every active client address when tapped.
class ClientAddressField extends FormField<AddressChoice> {
  ClientAddressField({
    super.key,
    super.initialValue,
    required ValueChanged<AddressChoice> onChanged,
  }) : super(
         validator: (value) => value == null ? 'Pick the client' : null,
         builder: (field) {
           final value = field.value;
           Future<void> pick() async {
             final picked = await showAdaptiveSheet<AddressChoice>(
               context: field.context,
               builder: (_) => const _AddressPickerSheet(),
             );
             if (picked == null) return;
             field.didChange(picked);
             onChanged(picked);
           }

           return InkWell(
             onTap: pick,
             borderRadius: BorderRadius.circular(4),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: 'Client',
                 errorText: field.errorText,
                 suffixIcon: const Icon(Icons.arrow_drop_down),
               ),
               isEmpty: value == null,
               child: value == null
                   ? null
                   : Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(value.clientName),
                         Text(
                           '${value.addressLabel} · ${value.stateName}',
                           style: Theme.of(field.context).textTheme.bodySmall,
                         ),
                       ],
                     ),
             ),
           );
         },
       );
}

/// Every active address of every active client, one row each, with search.
class _AddressPickerSheet extends ConsumerStatefulWidget {
  const _AddressPickerSheet();

  @override
  ConsumerState<_AddressPickerSheet> createState() =>
      _AddressPickerSheetState();
}

class _AddressPickerSheetState extends ConsumerState<_AddressPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final height = MediaQuery.sizeOf(context).height * 0.7;

    final choices = <AddressChoice>[];
    for (final client in clientsAsync.value ?? const <Client>[]) {
      if (client.isArchived || !clientMatches(client, _query)) continue;
      for (final address in client.addresses) {
        if (address.isArchived) continue;
        choices.add(AddressChoice.of(client, address));
      }
    }

    final Widget list;
    if (clientsAsync.hasError) {
      list = Center(child: Text('${clientsAsync.error}'));
    } else if (clientsAsync.value == null) {
      list = const Center(child: CircularProgressIndicator());
    } else if (choices.isEmpty) {
      list = const Center(child: Text('No clients match your search'));
    } else {
      list = ListView.builder(
        itemCount: choices.length,
        itemBuilder: (context, index) {
          final choice = choices[index];
          return ListTile(
            title: Text(choice.clientName),
            subtitle: Text('${choice.addressLabel} · ${choice.stateName}'),
            onTap: () => Navigator.of(context).pop(choice),
          );
        },
      );
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, context.isTwoPane ? 24 : 0, 16, 8),
            child: SearchBar(
              autoFocus: context.isTwoPane,
              hintText: 'Search clients, addresses, GSTIN',
              leading: const Icon(Icons.search),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}
