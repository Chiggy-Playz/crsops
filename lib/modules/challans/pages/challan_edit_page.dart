import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clients/providers/client_providers.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/date_time_form_fields.dart';
import '../../../core/widgets/form_pane.dart';
import '../../../core/widgets/guarded_save.dart';
import '../../../core/widgets/section_header.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../models/challan_item.dart';
import '../providers/challan_providers.dart';
import '../repositories/challan_repository.dart';
import '../routes.dart';
import 'widgets/client_address_picker.dart';
import 'widgets/items_editor.dart';
import 'widgets/suggestion_field.dart';

/// New challan, or editing one: the right pane on wide windows, a page on
/// phones. The number is given by the database on save; direction and date
/// can't change afterwards.
class ChallanEditPage extends ConsumerStatefulWidget {
  const ChallanEditPage({
    super.key,
    required this.existing,
    this.direction = ChallanDirection.outward,
    this.clientId,
  });

  final Challan? existing;

  /// For a new challan.
  final ChallanDirection direction;

  /// For a new challan started from a client's page: that client's address
  /// is picked already when it has just one.
  final String? clientId;

  @override
  ConsumerState<ChallanEditPage> createState() => _ChallanEditPageState();
}

class _ChallanEditPageState extends ConsumerState<ChallanEditPage> {
  Challan? get _existing => widget.existing;
  late final ChallanDirection _direction =
      widget.existing?.direction ?? widget.direction;
  late DateTime _date =
      widget.existing?.challanDate ?? DateUtils.dateOnly(DateTime.now());
  late AddressChoice? _address = _choiceOf(widget.existing);
  bool _useLatestAddress = false;
  late final _handledBy = TextEditingController(
    text: widget.existing?.handledByName ?? '',
  );
  late final _vehicle = TextEditingController(
    text: widget.existing?.vehicleNumber ?? '',
  );
  late final _declaredValue = TextEditingController(
    text: widget.existing?.declaredValue?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late final List<ItemFormValues> _items = [
    for (final item in widget.existing?.items ?? const <ChallanItem>[])
      ItemFormValues(item),
    if (widget.existing == null) ItemFormValues(),
  ];

  static AddressChoice? _choiceOf(Challan? challan) {
    if (challan == null) return null;
    return AddressChoice(
      addressId: challan.addressId,
      clientName: challan.clientName,
      addressLabel: challan.addressLabel,
      nameOnChallan: challan.nameOnChallan,
      address: challan.address,
      stateName: challan.stateName,
      gstin: challan.gstin,
    );
  }

  /// Rebuilds the address field when a client's address is filled in after
  /// the form first draws.
  Key _addressFieldKey = UniqueKey();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  /// Anything entered since the form opened, so leaving asks first.
  bool _changed = false;

  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    final clientId = widget.clientId;
    if (!_isEditing && clientId != null) _preselectAddress(clientId);
  }

  Future<void> _preselectAddress(String clientId) async {
    final client = await ref.read(clientProvider(clientId).future);
    final active = client.addresses.where((a) => !a.isArchived).toList();
    if (active.length != 1 || !mounted || _address != null) return;
    setState(() {
      _address = AddressChoice.of(client, active.single);
      _addressFieldKey = UniqueKey();
    });
  }

  @override
  void dispose() {
    _handledBy.dispose();
    _vehicle.dispose();
    _declaredValue.dispose();
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() {
    _items.add(ItemFormValues());
    _changed = true;
  });

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() {
      _items.removeAt(index);
      _changed = true;
    });
    // After this frame, once its card no longer uses the controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _moveItem(int from, int to) {
    setState(() {
      _items.insert(to, _items.removeAt(from));
      _changed = true;
    });
  }

  static String? _nullIfBlank(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final repo = ref.read(challanRepositoryProvider);
    final declaredText = _declaredValue.text.trim();
    final draft = ChallanDraft(
      direction: _direction,
      challanDate: _date,
      addressId: _address!.addressId,
      useLatestAddress: _useLatestAddress,
      handledByName: _handledBy.text.trim(),
      vehicleNumber: _nullIfBlank(_vehicle.text),
      declaredValue: declaredText.isEmpty ? null : int.parse(declaredText),
      notes: _nullIfBlank(_notes.text),
      items: [for (final item in _items) item.toItem()],
    );
    String? newId;

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        if (_isEditing) {
          await repo.update(widget.existing!.id, draft);
        } else {
          newId = await repo.create(draft);
        }
      },
      onSuccess: () {
        ref.read(challansRevisionProvider.notifier).bump();
        // Using an address locks it, which changes what the client page allows.
        ref.read(clientsRevisionProvider.notifier).bump();
        // Saved: nothing to ask about on the way out.
        _changed = false;
        final createdId = newId;
        if (createdId == null) {
          Navigator.of(context).pop();
        } else {
          ChallanDetailRoute(createdId).go(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(handledByNamesProvider).value ?? const <String>[];
    final units = ref.watch(itemUnitsProvider).value ?? const <String>[];
    final existing = _existing;

    // Offered only while the challan keeps its original address.
    final canUseLatest =
        existing != null &&
        existing.hasNewerAddress &&
        _address?.addressId == existing.addressId;

    final dateField = DateFormField(
      label: 'Date',
      value: _date,
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helperText: "Can't be changed after saving",
      onChanged: (date) => setState(() {
        _date = date;
        _changed = true;
      }),
    );
    final addressField = ClientAddressField(
      key: _addressFieldKey,
      initialValue: _address,
      onChanged: (choice) => setState(() {
        _address = choice;
        _useLatestAddress = false;
      }),
    );

    return FormPane(
      title: _isEditing
          ? 'Edit challan'
          : 'New ${_direction.label.toLowerCase()} challan',
      description: existing == null
          ? 'The number is given when you save.'
          : '${existing.direction.label} ${existing.numberLabel} · '
                '${formatDisplayDate(existing.challanDate)}',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onChanged: () => _changed = true,
      hasUnsavedChanges: () => _changed,
      closeLocation: existing == null
          ? const ChallansRoute().location
          : ChallanDetailRoute(existing.id).location,
      children: [
        if (_isEditing)
          addressField
        else
          FieldPair(first: dateField, second: addressField, secondFlex: 2),
        if (canUseLatest)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _useLatestAddress,
            onChanged: (value) => setState(() {
              _useLatestAddress = value ?? false;
              _changed = true;
            }),
            title: const Text("Use the client's latest details"),
            subtitle: const Text(
              "This address was edited after the challan was made. "
              'Leave unticked to keep printing the old details.',
            ),
          ),
        FieldPair(
          first: SuggestionField(
            controller: _handledBy,
            suggestions: names,
            label: _direction.handledByLabel,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter a name' : null,
          ),
          second: TextFormField(
            controller: _vehicle,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Vehicle number (optional)',
            ),
          ),
        ),
        FieldPair(
          first: TextFormField(
            controller: _declaredValue,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Value of goods (optional)',
              prefixText: '₹ ',
              helperText: 'Printed as "does not exceed ₹…"',
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return null;
              final amount = int.tryParse(text);
              if (amount == null || amount < 1) {
                return 'Leave empty, or enter more than zero';
              }
              return null;
            },
          ),
          second: TextFormField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              helperText: 'Only for you; not printed',
            ),
            minLines: 1,
            maxLines: 4,
          ),
        ),
        const SectionHeader('Items', topPadding: 8),
        ItemsEditor(
          items: _items,
          units: units,
          onAdd: _addItem,
          onRemove: _removeItem,
          onMove: _moveItem,
          onEdited: () => _changed = true,
        ),
      ],
    );
  }
}
