import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clients/providers/client_providers.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/date_time_form_fields.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/guarded_save.dart';
import '../../../core/widgets/section_header.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../models/challan_item.dart';
import '../providers/challan_providers.dart';
import '../repositories/challan_repository.dart';
import '../routes.dart';
import 'widgets/client_address_picker.dart';
import 'widgets/item_card.dart';
import 'widgets/suggestion_field.dart';

/// New challan, or editing one. The number is given by the database on
/// save; direction and date can't change afterwards.
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
      stateName: challan.stateName,
    );
  }

  /// Rebuilds the address field when a client's address is filled in after
  /// the form first draws.
  Key _addressFieldKey = UniqueKey();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

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

  void _addItem() => setState(() => _items.add(ItemFormValues()));

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    // After this frame, once its card no longer uses the controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _moveItem(int from, int to) {
    setState(() => _items.insert(to, _items.removeAt(from)));
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
        Navigator.of(context).pop();
        final createdId = newId;
        if (createdId != null) ChallanDetailRoute(createdId).go(context);
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

    return FormDialog(
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
      children: [
        if (!_isEditing)
          DateFormField(
            label: 'Date',
            value: _date,
            lastDate: DateUtils.dateOnly(DateTime.now()),
            helperText: "Can't be changed after saving",
            onChanged: (date) => setState(() => _date = date),
          ),
        ClientAddressField(
          key: _addressFieldKey,
          initialValue: _address,
          onChanged: (choice) => setState(() {
            _address = choice;
            _useLatestAddress = false;
          }),
        ),
        if (canUseLatest)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _useLatestAddress,
            onChanged: (value) =>
                setState(() => _useLatestAddress = value ?? false),
            title: const Text("Use the client's latest details"),
            subtitle: const Text(
              "This address was edited after the challan was made. "
              'Leave unticked to keep printing the old details.',
            ),
          ),
        SuggestionField(
          controller: _handledBy,
          suggestions: names,
          label: _direction.handledByLabel,
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
        TextFormField(
          controller: _vehicle,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Vehicle number (optional)',
          ),
        ),
        TextFormField(
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
        TextFormField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            helperText: 'Only for you; not printed',
          ),
          minLines: 1,
          maxLines: 4,
        ),
        // Rebuilds as quantities are typed, so the total stays current.
        ListenableBuilder(
          listenable: Listenable.merge([
            for (final item in _items) item.quantity,
          ]),
          builder: (context, _) {
            final total = _items.fold<int>(
              0,
              (sum, item) =>
                  sum + (int.tryParse(item.quantity.text.trim()) ?? 0),
            );
            return SectionHeader('Items · total $total', topPadding: 8);
          },
        ),
        for (final (index, item) in _items.indexed)
          ItemCard(
            key: item.key,
            position: index + 1,
            values: item,
            units: units,
            onRemove: _items.length > 1 ? () => _removeItem(index) : null,
            onMoveUp: index > 0 ? () => _moveItem(index, index - 1) : null,
            onMoveDown: index < _items.length - 1
                ? () => _moveItem(index, index + 1)
                : null,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
      ],
    );
  }
}
