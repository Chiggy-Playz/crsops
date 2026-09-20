// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'status_type.dart';

class StatusTypeMapper extends ClassMapperBase<StatusType> {
  StatusTypeMapper._();

  static StatusTypeMapper? _instance;
  static StatusTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StatusTypeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'StatusType';

  static String _$id(StatusType v) => v.id;
  static const Field<StatusType, String> _f$id = Field('id', _$id);
  static String _$label(StatusType v) => v.label;
  static const Field<StatusType, String> _f$label = Field('label', _$label);
  static String? _$iconName(StatusType v) => v.iconName;
  static const Field<StatusType, String> _f$iconName = Field(
    'iconName',
    _$iconName,
    key: r'icon_name',
    opt: true,
  );
  static String? _$colorHex(StatusType v) => v.colorHex;
  static const Field<StatusType, String> _f$colorHex = Field(
    'colorHex',
    _$colorHex,
    key: r'color_hex',
    opt: true,
  );
  static String? _$description(StatusType v) => v.description;
  static const Field<StatusType, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );

  @override
  final MappableFields<StatusType> fields = const {
    #id: _f$id,
    #label: _f$label,
    #iconName: _f$iconName,
    #colorHex: _f$colorHex,
    #description: _f$description,
  };

  static StatusType _instantiate(DecodingData data) {
    return StatusType(
      id: data.dec(_f$id),
      label: data.dec(_f$label),
      iconName: data.dec(_f$iconName),
      colorHex: data.dec(_f$colorHex),
      description: data.dec(_f$description),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static StatusType fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StatusType>(map);
  }

  static StatusType fromJson(String json) {
    return ensureInitialized().decodeJson<StatusType>(json);
  }
}

mixin StatusTypeMappable {
  String toJson() {
    return StatusTypeMapper.ensureInitialized().encodeJson<StatusType>(
      this as StatusType,
    );
  }

  Map<String, dynamic> toMap() {
    return StatusTypeMapper.ensureInitialized().encodeMap<StatusType>(
      this as StatusType,
    );
  }

  StatusTypeCopyWith<StatusType, StatusType, StatusType> get copyWith =>
      _StatusTypeCopyWithImpl<StatusType, StatusType>(
        this as StatusType,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return StatusTypeMapper.ensureInitialized().stringifyValue(
      this as StatusType,
    );
  }

  @override
  bool operator ==(Object other) {
    return StatusTypeMapper.ensureInitialized().equalsValue(
      this as StatusType,
      other,
    );
  }

  @override
  int get hashCode {
    return StatusTypeMapper.ensureInitialized().hashValue(this as StatusType);
  }
}

extension StatusTypeValueCopy<$R, $Out>
    on ObjectCopyWith<$R, StatusType, $Out> {
  StatusTypeCopyWith<$R, StatusType, $Out> get $asStatusType =>
      $base.as((v, t, t2) => _StatusTypeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class StatusTypeCopyWith<$R, $In extends StatusType, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? label,
    String? iconName,
    String? colorHex,
    String? description,
  });
  StatusTypeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _StatusTypeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StatusType, $Out>
    implements StatusTypeCopyWith<$R, StatusType, $Out> {
  _StatusTypeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StatusType> $mapper =
      StatusTypeMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? label,
    Object? iconName = $none,
    Object? colorHex = $none,
    Object? description = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (label != null) #label: label,
      if (iconName != $none) #iconName: iconName,
      if (colorHex != $none) #colorHex: colorHex,
      if (description != $none) #description: description,
    }),
  );
  @override
  StatusType $make(CopyWithData data) => StatusType(
    id: data.get(#id, or: $value.id),
    label: data.get(#label, or: $value.label),
    iconName: data.get(#iconName, or: $value.iconName),
    colorHex: data.get(#colorHex, or: $value.colorHex),
    description: data.get(#description, or: $value.description),
  );

  @override
  StatusTypeCopyWith<$R2, StatusType, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _StatusTypeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

