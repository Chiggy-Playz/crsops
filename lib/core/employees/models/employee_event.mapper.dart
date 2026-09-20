// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'employee_event.dart';

class EmployeeEventMapper extends ClassMapperBase<EmployeeEvent> {
  EmployeeEventMapper._();

  static EmployeeEventMapper? _instance;
  static EmployeeEventMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmployeeEventMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EmployeeEvent';

  static String _$id(EmployeeEvent v) => v.id;
  static const Field<EmployeeEvent, String> _f$id = Field('id', _$id);
  static String _$employeeId(EmployeeEvent v) => v.employeeId;
  static const Field<EmployeeEvent, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static String _$eventType(EmployeeEvent v) => v.eventType;
  static const Field<EmployeeEvent, String> _f$eventType = Field(
    'eventType',
    _$eventType,
    key: r'event_type',
  );
  static DateTime _$eventDate(EmployeeEvent v) => v.eventDate;
  static const Field<EmployeeEvent, DateTime> _f$eventDate = Field(
    'eventDate',
    _$eventDate,
    key: r'event_date',
  );
  static String? _$note(EmployeeEvent v) => v.note;
  static const Field<EmployeeEvent, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static String? _$createdBy(EmployeeEvent v) => v.createdBy;
  static const Field<EmployeeEvent, String> _f$createdBy = Field(
    'createdBy',
    _$createdBy,
    key: r'created_by',
    opt: true,
  );
  static DateTime _$createdAt(EmployeeEvent v) => v.createdAt;
  static const Field<EmployeeEvent, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
  );

  @override
  final MappableFields<EmployeeEvent> fields = const {
    #id: _f$id,
    #employeeId: _f$employeeId,
    #eventType: _f$eventType,
    #eventDate: _f$eventDate,
    #note: _f$note,
    #createdBy: _f$createdBy,
    #createdAt: _f$createdAt,
  };

  static EmployeeEvent _instantiate(DecodingData data) {
    return EmployeeEvent(
      id: data.dec(_f$id),
      employeeId: data.dec(_f$employeeId),
      eventType: data.dec(_f$eventType),
      eventDate: data.dec(_f$eventDate),
      note: data.dec(_f$note),
      createdBy: data.dec(_f$createdBy),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EmployeeEvent fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EmployeeEvent>(map);
  }

  static EmployeeEvent fromJson(String json) {
    return ensureInitialized().decodeJson<EmployeeEvent>(json);
  }
}

mixin EmployeeEventMappable {
  String toJson() {
    return EmployeeEventMapper.ensureInitialized().encodeJson<EmployeeEvent>(
      this as EmployeeEvent,
    );
  }

  Map<String, dynamic> toMap() {
    return EmployeeEventMapper.ensureInitialized().encodeMap<EmployeeEvent>(
      this as EmployeeEvent,
    );
  }

  EmployeeEventCopyWith<EmployeeEvent, EmployeeEvent, EmployeeEvent>
  get copyWith => _EmployeeEventCopyWithImpl<EmployeeEvent, EmployeeEvent>(
    this as EmployeeEvent,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return EmployeeEventMapper.ensureInitialized().stringifyValue(
      this as EmployeeEvent,
    );
  }

  @override
  bool operator ==(Object other) {
    return EmployeeEventMapper.ensureInitialized().equalsValue(
      this as EmployeeEvent,
      other,
    );
  }

  @override
  int get hashCode {
    return EmployeeEventMapper.ensureInitialized().hashValue(
      this as EmployeeEvent,
    );
  }
}

extension EmployeeEventValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EmployeeEvent, $Out> {
  EmployeeEventCopyWith<$R, EmployeeEvent, $Out> get $asEmployeeEvent =>
      $base.as((v, t, t2) => _EmployeeEventCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EmployeeEventCopyWith<$R, $In extends EmployeeEvent, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? employeeId,
    String? eventType,
    DateTime? eventDate,
    String? note,
    String? createdBy,
    DateTime? createdAt,
  });
  EmployeeEventCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EmployeeEventCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EmployeeEvent, $Out>
    implements EmployeeEventCopyWith<$R, EmployeeEvent, $Out> {
  _EmployeeEventCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EmployeeEvent> $mapper =
      EmployeeEventMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? employeeId,
    String? eventType,
    DateTime? eventDate,
    Object? note = $none,
    Object? createdBy = $none,
    DateTime? createdAt,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (employeeId != null) #employeeId: employeeId,
      if (eventType != null) #eventType: eventType,
      if (eventDate != null) #eventDate: eventDate,
      if (note != $none) #note: note,
      if (createdBy != $none) #createdBy: createdBy,
      if (createdAt != null) #createdAt: createdAt,
    }),
  );
  @override
  EmployeeEvent $make(CopyWithData data) => EmployeeEvent(
    id: data.get(#id, or: $value.id),
    employeeId: data.get(#employeeId, or: $value.employeeId),
    eventType: data.get(#eventType, or: $value.eventType),
    eventDate: data.get(#eventDate, or: $value.eventDate),
    note: data.get(#note, or: $value.note),
    createdBy: data.get(#createdBy, or: $value.createdBy),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  EmployeeEventCopyWith<$R2, EmployeeEvent, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EmployeeEventCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

