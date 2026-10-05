// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'event_type.dart';

class EventTypeMapper extends ClassMapperBase<EventType> {
  EventTypeMapper._();

  static EventTypeMapper? _instance;
  static EventTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EventTypeMapper._());
      EmploymentStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'EventType';

  static String _$id(EventType v) => v.id;
  static const Field<EventType, String> _f$id = Field('id', _$id);
  static EmploymentStatus? _$statusEffect(EventType v) => v.statusEffect;
  static const Field<EventType, EmploymentStatus> _f$statusEffect = Field(
    'statusEffect',
    _$statusEffect,
    key: r'status_effect',
    opt: true,
  );
  static String? _$iconName(EventType v) => v.iconName;
  static const Field<EventType, String> _f$iconName = Field(
    'iconName',
    _$iconName,
    key: r'icon_name',
    opt: true,
  );
  static String? _$colorHex(EventType v) => v.colorHex;
  static const Field<EventType, String> _f$colorHex = Field(
    'colorHex',
    _$colorHex,
    key: r'color_hex',
    opt: true,
  );
  static String? _$description(EventType v) => v.description;
  static const Field<EventType, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );

  @override
  final MappableFields<EventType> fields = const {
    #id: _f$id,
    #statusEffect: _f$statusEffect,
    #iconName: _f$iconName,
    #colorHex: _f$colorHex,
    #description: _f$description,
  };

  static EventType _instantiate(DecodingData data) {
    return EventType(
      id: data.dec(_f$id),
      statusEffect: data.dec(_f$statusEffect),
      iconName: data.dec(_f$iconName),
      colorHex: data.dec(_f$colorHex),
      description: data.dec(_f$description),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EventType fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EventType>(map);
  }

  static EventType fromJson(String json) {
    return ensureInitialized().decodeJson<EventType>(json);
  }
}

mixin EventTypeMappable {
  String toJson() {
    return EventTypeMapper.ensureInitialized().encodeJson<EventType>(
      this as EventType,
    );
  }

  Map<String, dynamic> toMap() {
    return EventTypeMapper.ensureInitialized().encodeMap<EventType>(
      this as EventType,
    );
  }

  EventTypeCopyWith<EventType, EventType, EventType> get copyWith =>
      _EventTypeCopyWithImpl<EventType, EventType>(
        this as EventType,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EventTypeMapper.ensureInitialized().stringifyValue(
      this as EventType,
    );
  }

  @override
  bool operator ==(Object other) {
    return EventTypeMapper.ensureInitialized().equalsValue(
      this as EventType,
      other,
    );
  }

  @override
  int get hashCode {
    return EventTypeMapper.ensureInitialized().hashValue(this as EventType);
  }
}

extension EventTypeValueCopy<$R, $Out> on ObjectCopyWith<$R, EventType, $Out> {
  EventTypeCopyWith<$R, EventType, $Out> get $asEventType =>
      $base.as((v, t, t2) => _EventTypeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EventTypeCopyWith<$R, $In extends EventType, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    EmploymentStatus? statusEffect,
    String? iconName,
    String? colorHex,
    String? description,
  });
  EventTypeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EventTypeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EventType, $Out>
    implements EventTypeCopyWith<$R, EventType, $Out> {
  _EventTypeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EventType> $mapper =
      EventTypeMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? statusEffect = $none,
    Object? iconName = $none,
    Object? colorHex = $none,
    Object? description = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (statusEffect != $none) #statusEffect: statusEffect,
      if (iconName != $none) #iconName: iconName,
      if (colorHex != $none) #colorHex: colorHex,
      if (description != $none) #description: description,
    }),
  );
  @override
  EventType $make(CopyWithData data) => EventType(
    id: data.get(#id, or: $value.id),
    statusEffect: data.get(#statusEffect, or: $value.statusEffect),
    iconName: data.get(#iconName, or: $value.iconName),
    colorHex: data.get(#colorHex, or: $value.colorHex),
    description: data.get(#description, or: $value.description),
  );

  @override
  EventTypeCopyWith<$R2, EventType, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EventTypeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

