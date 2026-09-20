// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'attendance_day.dart';

class AttendanceDayMapper extends ClassMapperBase<AttendanceDay> {
  AttendanceDayMapper._();

  static AttendanceDayMapper? _instance;
  static AttendanceDayMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AttendanceDayMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AttendanceDay';

  static String? _$id(AttendanceDay v) => v.id;
  static const Field<AttendanceDay, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
  );
  static String _$employeeId(AttendanceDay v) => v.employeeId;
  static const Field<AttendanceDay, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$date(AttendanceDay v) => v.date;
  static const Field<AttendanceDay, DateTime> _f$date = Field('date', _$date);
  static String? _$firstHalfStatus(AttendanceDay v) => v.firstHalfStatus;
  static const Field<AttendanceDay, String> _f$firstHalfStatus = Field(
    'firstHalfStatus',
    _$firstHalfStatus,
    key: r'first_half_status',
    opt: true,
  );
  static String? _$secondHalfStatus(AttendanceDay v) => v.secondHalfStatus;
  static const Field<AttendanceDay, String> _f$secondHalfStatus = Field(
    'secondHalfStatus',
    _$secondHalfStatus,
    key: r'second_half_status',
    opt: true,
  );
  static String? _$timeIn(AttendanceDay v) => v.timeIn;
  static const Field<AttendanceDay, String> _f$timeIn = Field(
    'timeIn',
    _$timeIn,
    key: r'time_in',
    opt: true,
  );
  static String? _$timeOut(AttendanceDay v) => v.timeOut;
  static const Field<AttendanceDay, String> _f$timeOut = Field(
    'timeOut',
    _$timeOut,
    key: r'time_out',
    opt: true,
  );
  static String? _$note(AttendanceDay v) => v.note;
  static const Field<AttendanceDay, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );

  @override
  final MappableFields<AttendanceDay> fields = const {
    #id: _f$id,
    #employeeId: _f$employeeId,
    #date: _f$date,
    #firstHalfStatus: _f$firstHalfStatus,
    #secondHalfStatus: _f$secondHalfStatus,
    #timeIn: _f$timeIn,
    #timeOut: _f$timeOut,
    #note: _f$note,
  };

  static AttendanceDay _instantiate(DecodingData data) {
    return AttendanceDay(
      id: data.dec(_f$id),
      employeeId: data.dec(_f$employeeId),
      date: data.dec(_f$date),
      firstHalfStatus: data.dec(_f$firstHalfStatus),
      secondHalfStatus: data.dec(_f$secondHalfStatus),
      timeIn: data.dec(_f$timeIn),
      timeOut: data.dec(_f$timeOut),
      note: data.dec(_f$note),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AttendanceDay fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AttendanceDay>(map);
  }

  static AttendanceDay fromJson(String json) {
    return ensureInitialized().decodeJson<AttendanceDay>(json);
  }
}

mixin AttendanceDayMappable {
  String toJson() {
    return AttendanceDayMapper.ensureInitialized().encodeJson<AttendanceDay>(
      this as AttendanceDay,
    );
  }

  Map<String, dynamic> toMap() {
    return AttendanceDayMapper.ensureInitialized().encodeMap<AttendanceDay>(
      this as AttendanceDay,
    );
  }

  AttendanceDayCopyWith<AttendanceDay, AttendanceDay, AttendanceDay>
  get copyWith => _AttendanceDayCopyWithImpl<AttendanceDay, AttendanceDay>(
    this as AttendanceDay,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return AttendanceDayMapper.ensureInitialized().stringifyValue(
      this as AttendanceDay,
    );
  }

  @override
  bool operator ==(Object other) {
    return AttendanceDayMapper.ensureInitialized().equalsValue(
      this as AttendanceDay,
      other,
    );
  }

  @override
  int get hashCode {
    return AttendanceDayMapper.ensureInitialized().hashValue(
      this as AttendanceDay,
    );
  }
}

extension AttendanceDayValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AttendanceDay, $Out> {
  AttendanceDayCopyWith<$R, AttendanceDay, $Out> get $asAttendanceDay =>
      $base.as((v, t, t2) => _AttendanceDayCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AttendanceDayCopyWith<$R, $In extends AttendanceDay, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? employeeId,
    DateTime? date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  });
  AttendanceDayCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AttendanceDayCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AttendanceDay, $Out>
    implements AttendanceDayCopyWith<$R, AttendanceDay, $Out> {
  _AttendanceDayCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AttendanceDay> $mapper =
      AttendanceDayMapper.ensureInitialized();
  @override
  $R call({
    Object? id = $none,
    String? employeeId,
    DateTime? date,
    Object? firstHalfStatus = $none,
    Object? secondHalfStatus = $none,
    Object? timeIn = $none,
    Object? timeOut = $none,
    Object? note = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != $none) #id: id,
      if (employeeId != null) #employeeId: employeeId,
      if (date != null) #date: date,
      if (firstHalfStatus != $none) #firstHalfStatus: firstHalfStatus,
      if (secondHalfStatus != $none) #secondHalfStatus: secondHalfStatus,
      if (timeIn != $none) #timeIn: timeIn,
      if (timeOut != $none) #timeOut: timeOut,
      if (note != $none) #note: note,
    }),
  );
  @override
  AttendanceDay $make(CopyWithData data) => AttendanceDay(
    id: data.get(#id, or: $value.id),
    employeeId: data.get(#employeeId, or: $value.employeeId),
    date: data.get(#date, or: $value.date),
    firstHalfStatus: data.get(#firstHalfStatus, or: $value.firstHalfStatus),
    secondHalfStatus: data.get(#secondHalfStatus, or: $value.secondHalfStatus),
    timeIn: data.get(#timeIn, or: $value.timeIn),
    timeOut: data.get(#timeOut, or: $value.timeOut),
    note: data.get(#note, or: $value.note),
  );

  @override
  AttendanceDayCopyWith<$R2, AttendanceDay, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AttendanceDayCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

