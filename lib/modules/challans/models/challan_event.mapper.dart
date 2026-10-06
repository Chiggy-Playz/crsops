// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'challan_event.dart';

class ChallanEventMapper extends ClassMapperBase<ChallanEvent> {
  ChallanEventMapper._();

  static ChallanEventMapper? _instance;
  static ChallanEventMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChallanEventMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChallanEvent';

  static int _$id(ChallanEvent v) => v.id;
  static const Field<ChallanEvent, int> _f$id = Field('id', _$id);
  static String _$challanId(ChallanEvent v) => v.challanId;
  static const Field<ChallanEvent, String> _f$challanId = Field(
    'challanId',
    _$challanId,
    key: r'challan_id',
  );
  static String _$eventType(ChallanEvent v) => v.eventType;
  static const Field<ChallanEvent, String> _f$eventType = Field(
    'eventType',
    _$eventType,
    key: r'event_type',
  );
  static Map<String, dynamic> _$changes(ChallanEvent v) => v.changes;
  static const Field<ChallanEvent, Map<String, dynamic>> _f$changes = Field(
    'changes',
    _$changes,
    opt: true,
    def: const {},
  );
  static String? _$note(ChallanEvent v) => v.note;
  static const Field<ChallanEvent, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static DateTime _$createdAt(ChallanEvent v) => v.createdAt;
  static const Field<ChallanEvent, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
  );
  static String? _$createdByEmail(ChallanEvent v) => v.createdByEmail;
  static const Field<ChallanEvent, String> _f$createdByEmail = Field(
    'createdByEmail',
    _$createdByEmail,
    key: r'created_by_email',
    opt: true,
  );

  @override
  final MappableFields<ChallanEvent> fields = const {
    #id: _f$id,
    #challanId: _f$challanId,
    #eventType: _f$eventType,
    #changes: _f$changes,
    #note: _f$note,
    #createdAt: _f$createdAt,
    #createdByEmail: _f$createdByEmail,
  };

  static ChallanEvent _instantiate(DecodingData data) {
    return ChallanEvent(
      id: data.dec(_f$id),
      challanId: data.dec(_f$challanId),
      eventType: data.dec(_f$eventType),
      changes: data.dec(_f$changes),
      note: data.dec(_f$note),
      createdAt: data.dec(_f$createdAt),
      createdByEmail: data.dec(_f$createdByEmail),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChallanEvent fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChallanEvent>(map);
  }

  static ChallanEvent fromJson(String json) {
    return ensureInitialized().decodeJson<ChallanEvent>(json);
  }
}

mixin ChallanEventMappable {
  String toJson() {
    return ChallanEventMapper.ensureInitialized().encodeJson<ChallanEvent>(
      this as ChallanEvent,
    );
  }

  Map<String, dynamic> toMap() {
    return ChallanEventMapper.ensureInitialized().encodeMap<ChallanEvent>(
      this as ChallanEvent,
    );
  }

  ChallanEventCopyWith<ChallanEvent, ChallanEvent, ChallanEvent> get copyWith =>
      _ChallanEventCopyWithImpl<ChallanEvent, ChallanEvent>(
        this as ChallanEvent,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChallanEventMapper.ensureInitialized().stringifyValue(
      this as ChallanEvent,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChallanEventMapper.ensureInitialized().equalsValue(
      this as ChallanEvent,
      other,
    );
  }

  @override
  int get hashCode {
    return ChallanEventMapper.ensureInitialized().hashValue(
      this as ChallanEvent,
    );
  }
}

extension ChallanEventValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChallanEvent, $Out> {
  ChallanEventCopyWith<$R, ChallanEvent, $Out> get $asChallanEvent =>
      $base.as((v, t, t2) => _ChallanEventCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChallanEventCopyWith<$R, $In extends ChallanEvent, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get changes;
  $R call({
    int? id,
    String? challanId,
    String? eventType,
    Map<String, dynamic>? changes,
    String? note,
    DateTime? createdAt,
    String? createdByEmail,
  });
  ChallanEventCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChallanEventCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChallanEvent, $Out>
    implements ChallanEventCopyWith<$R, ChallanEvent, $Out> {
  _ChallanEventCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChallanEvent> $mapper =
      ChallanEventMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get changes => MapCopyWith(
    $value.changes,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(changes: v),
  );
  @override
  $R call({
    int? id,
    String? challanId,
    String? eventType,
    Map<String, dynamic>? changes,
    Object? note = $none,
    DateTime? createdAt,
    Object? createdByEmail = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (challanId != null) #challanId: challanId,
      if (eventType != null) #eventType: eventType,
      if (changes != null) #changes: changes,
      if (note != $none) #note: note,
      if (createdAt != null) #createdAt: createdAt,
      if (createdByEmail != $none) #createdByEmail: createdByEmail,
    }),
  );
  @override
  ChallanEvent $make(CopyWithData data) => ChallanEvent(
    id: data.get(#id, or: $value.id),
    challanId: data.get(#challanId, or: $value.challanId),
    eventType: data.get(#eventType, or: $value.eventType),
    changes: data.get(#changes, or: $value.changes),
    note: data.get(#note, or: $value.note),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    createdByEmail: data.get(#createdByEmail, or: $value.createdByEmail),
  );

  @override
  ChallanEventCopyWith<$R2, ChallanEvent, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChallanEventCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

