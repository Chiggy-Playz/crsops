import 'package:flutter/material.dart';

import '../../gstin.dart';
import '../../models/indian_state.dart';

/// The text a person types for one address. The form that shows
/// [AddressFormFields] owns this (and disposes it), so it can read the values
/// when saving.
class AddressFormValues {
  AddressFormValues({
    String label = '',
    String nameOnChallan = '',
    String address = '',
    this.stateCode,
    String gstin = '',
  }) : label = TextEditingController(text: label),
       nameOnChallan = TextEditingController(text: nameOnChallan),
       address = TextEditingController(text: address),
       gstin = TextEditingController(text: gstin);

  final TextEditingController label;
  final TextEditingController nameOnChallan;
  final TextEditingController address;
  final TextEditingController gstin;
  String? stateCode;

  void dispose() {
    label.dispose();
    nameOnChallan.dispose();
    address.dispose();
    gstin.dispose();
  }
}

/// Label, name on challan, address, state and GSTIN — shared by the new
/// client form (its first address) and the address form.
class AddressFormFields extends StatefulWidget {
  const AddressFormFields({
    super.key,
    required this.values,
    required this.states,
  });

  final AddressFormValues values;
  final List<IndianState> states;

  @override
  State<AddressFormFields> createState() => _AddressFormFieldsState();
}

class _AddressFormFieldsState extends State<AddressFormFields> {
  @override
  void initState() {
    super.initState();
    // The mismatch note under GSTIN depends on what's typed there.
    widget.values.gstin.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.values.gstin.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  String _stateName(String code) {
    for (final state in widget.states) {
      if (state.code == code) return state.name;
    }
    return code;
  }

  /// A heads-up, not an error: the GSTIN is registered in one state and the
  /// goods go to another. That's often right, sometimes a typo.
  String? _mismatchNote() {
    final registeredIn = gstinStateCode(widget.values.gstin.text);
    final chosen = widget.values.stateCode;
    if (registeredIn == null || chosen == null || registeredIn == chosen) {
      return null;
    }
    return 'This GSTIN is registered in ${_stateName(registeredIn)}, '
        'not ${_stateName(chosen)}. Fine if the goods go there.';
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final mismatch = _mismatchNote();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: values.label,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Label',
            helperText: 'Only for you, like "Head office" or "Sector 4"',
          ),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter a label' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: values.nameOnChallan,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Name on challan'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter the name to print' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: values.address,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Address'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter the address' : null,
        ),
        const SizedBox(height: 16),
        DropdownMenuFormField<String>(
          initialSelection: values.stateCode,
          dropdownMenuEntries: [
            for (final state in widget.states)
              DropdownMenuEntry(value: state.code, label: state.name),
          ],
          requestFocusOnTap: true,
          enableFilter: true,
          expandedInsets: EdgeInsets.zero,
          menuHeight: 320,
          label: const Text('State'),
          helperText: 'Where the goods go',
          onSelected: (code) => setState(() => values.stateCode = code),
          validator: (code) => code == null ? 'Pick a state' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: values.gstin,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'GSTIN (optional)',
            helperText: mismatch,
            helperMaxLines: 3,
          ),
          validator: validateGstin,
        ),
      ],
    );
  }
}
