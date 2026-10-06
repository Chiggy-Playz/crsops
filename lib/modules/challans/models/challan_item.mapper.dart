// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'challan_item.dart';

class ChallanItemMapper extends ClassMapperBase<ChallanItem> {
  ChallanItemMapper._();

  static ChallanItemMapper? _instance;
  static ChallanItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChallanItemMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChallanItem';

  static String _$description(ChallanItem v) => v.description;
  static const Field<ChallanItem, String> _f$description = Field(
    'description',
    _$description,
  );
  static String? _$additionalDescription(ChallanItem v) =>
      v.additionalDescription;
  static const Field<ChallanItem, String> _f$additionalDescription = Field(
    'additionalDescription',
    _$additionalDescription,
    key: r'additional_description',
    opt: true,
  );
  static String? _$serial(ChallanItem v) => v.serial;
  static const Field<ChallanItem, String> _f$serial = Field(
    'serial',
    _$serial,
    opt: true,
  );
  static int _$quantity(ChallanItem v) => v.quantity;
  static const Field<ChallanItem, int> _f$quantity = Field(
    'quantity',
    _$quantity,
  );
  static String? _$unit(ChallanItem v) => v.unit;
  static const Field<ChallanItem, String> _f$unit = Field(
    'unit',
    _$unit,
    opt: true,
  );

  @override
  final MappableFields<ChallanItem> fields = const {
    #description: _f$description,
    #additionalDescription: _f$additionalDescription,
    #serial: _f$serial,
    #quantity: _f$quantity,
    #unit: _f$unit,
  };

  static ChallanItem _instantiate(DecodingData data) {
    return ChallanItem(
      description: data.dec(_f$description),
      additionalDescription: data.dec(_f$additionalDescription),
      serial: data.dec(_f$serial),
      quantity: data.dec(_f$quantity),
      unit: data.dec(_f$unit),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChallanItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChallanItem>(map);
  }

  static ChallanItem fromJson(String json) {
    return ensureInitialized().decodeJson<ChallanItem>(json);
  }
}

mixin ChallanItemMappable {
  String toJson() {
    return ChallanItemMapper.ensureInitialized().encodeJson<ChallanItem>(
      this as ChallanItem,
    );
  }

  Map<String, dynamic> toMap() {
    return ChallanItemMapper.ensureInitialized().encodeMap<ChallanItem>(
      this as ChallanItem,
    );
  }

  ChallanItemCopyWith<ChallanItem, ChallanItem, ChallanItem> get copyWith =>
      _ChallanItemCopyWithImpl<ChallanItem, ChallanItem>(
        this as ChallanItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChallanItemMapper.ensureInitialized().stringifyValue(
      this as ChallanItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChallanItemMapper.ensureInitialized().equalsValue(
      this as ChallanItem,
      other,
    );
  }

  @override
  int get hashCode {
    return ChallanItemMapper.ensureInitialized().hashValue(this as ChallanItem);
  }
}

extension ChallanItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChallanItem, $Out> {
  ChallanItemCopyWith<$R, ChallanItem, $Out> get $asChallanItem =>
      $base.as((v, t, t2) => _ChallanItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChallanItemCopyWith<$R, $In extends ChallanItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? description,
    String? additionalDescription,
    String? serial,
    int? quantity,
    String? unit,
  });
  ChallanItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChallanItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChallanItem, $Out>
    implements ChallanItemCopyWith<$R, ChallanItem, $Out> {
  _ChallanItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChallanItem> $mapper =
      ChallanItemMapper.ensureInitialized();
  @override
  $R call({
    String? description,
    Object? additionalDescription = $none,
    Object? serial = $none,
    int? quantity,
    Object? unit = $none,
  }) => $apply(
    FieldCopyWithData({
      if (description != null) #description: description,
      if (additionalDescription != $none)
        #additionalDescription: additionalDescription,
      if (serial != $none) #serial: serial,
      if (quantity != null) #quantity: quantity,
      if (unit != $none) #unit: unit,
    }),
  );
  @override
  ChallanItem $make(CopyWithData data) => ChallanItem(
    description: data.get(#description, or: $value.description),
    additionalDescription: data.get(
      #additionalDescription,
      or: $value.additionalDescription,
    ),
    serial: data.get(#serial, or: $value.serial),
    quantity: data.get(#quantity, or: $value.quantity),
    unit: data.get(#unit, or: $value.unit),
  );

  @override
  ChallanItemCopyWith<$R2, ChallanItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChallanItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

