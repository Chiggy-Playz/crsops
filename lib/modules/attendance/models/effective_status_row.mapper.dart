// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'effective_status_row.dart';

class EffectiveStatusRowMapper extends ClassMapperBase<EffectiveStatusRow> {
  EffectiveStatusRowMapper._();

  static EffectiveStatusRowMapper? _instance;
  static EffectiveStatusRowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EffectiveStatusRowMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EffectiveStatusRow';

  static String _$employeeId(EffectiveStatusRow v) => v.employeeId;
  static const Field<EffectiveStatusRow, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$date(EffectiveStatusRow v) => v.date;
  static const Field<EffectiveStatusRow, DateTime> _f$date = Field(
    'date',
    _$date,
  );
  static String? _$firstHalfStatus(EffectiveStatusRow v) => v.firstHalfStatus;
  static const Field<EffectiveStatusRow, String> _f$firstHalfStatus = Field(
    'firstHalfStatus',
    _$firstHalfStatus,
    key: r'first_half_status',
    opt: true,
  );
  static String? _$secondHalfStatus(EffectiveStatusRow v) => v.secondHalfStatus;
  static const Field<EffectiveStatusRow, String> _f$secondHalfStatus = Field(
    'secondHalfStatus',
    _$secondHalfStatus,
    key: r'second_half_status',
    opt: true,
  );
  static bool _$isExplicit(EffectiveStatusRow v) => v.isExplicit;
  static const Field<EffectiveStatusRow, bool> _f$isExplicit = Field(
    'isExplicit',
    _$isExplicit,
    key: r'is_explicit',
  );
  static bool _$isWeekOff(EffectiveStatusRow v) => v.isWeekOff;
  static const Field<EffectiveStatusRow, bool> _f$isWeekOff = Field(
    'isWeekOff',
    _$isWeekOff,
    key: r'is_week_off',
  );
  static String? _$timeIn(EffectiveStatusRow v) => v.timeIn;
  static const Field<EffectiveStatusRow, String> _f$timeIn = Field(
    'timeIn',
    _$timeIn,
    key: r'time_in',
    opt: true,
  );
  static String? _$timeOut(EffectiveStatusRow v) => v.timeOut;
  static const Field<EffectiveStatusRow, String> _f$timeOut = Field(
    'timeOut',
    _$timeOut,
    key: r'time_out',
    opt: true,
  );
  static String? _$note(EffectiveStatusRow v) => v.note;
  static const Field<EffectiveStatusRow, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );

  @override
  final MappableFields<EffectiveStatusRow> fields = const {
    #employeeId: _f$employeeId,
    #date: _f$date,
    #firstHalfStatus: _f$firstHalfStatus,
    #secondHalfStatus: _f$secondHalfStatus,
    #isExplicit: _f$isExplicit,
    #isWeekOff: _f$isWeekOff,
    #timeIn: _f$timeIn,
    #timeOut: _f$timeOut,
    #note: _f$note,
  };

  static EffectiveStatusRow _instantiate(DecodingData data) {
    return EffectiveStatusRow(
      employeeId: data.dec(_f$employeeId),
      date: data.dec(_f$date),
      firstHalfStatus: data.dec(_f$firstHalfStatus),
      secondHalfStatus: data.dec(_f$secondHalfStatus),
      isExplicit: data.dec(_f$isExplicit),
      isWeekOff: data.dec(_f$isWeekOff),
      timeIn: data.dec(_f$timeIn),
      timeOut: data.dec(_f$timeOut),
      note: data.dec(_f$note),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EffectiveStatusRow fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EffectiveStatusRow>(map);
  }

  static EffectiveStatusRow fromJson(String json) {
    return ensureInitialized().decodeJson<EffectiveStatusRow>(json);
  }
}

mixin EffectiveStatusRowMappable {
  String toJson() {
    return EffectiveStatusRowMapper.ensureInitialized()
        .encodeJson<EffectiveStatusRow>(this as EffectiveStatusRow);
  }

  Map<String, dynamic> toMap() {
    return EffectiveStatusRowMapper.ensureInitialized()
        .encodeMap<EffectiveStatusRow>(this as EffectiveStatusRow);
  }

  EffectiveStatusRowCopyWith<
    EffectiveStatusRow,
    EffectiveStatusRow,
    EffectiveStatusRow
  >
  get copyWith =>
      _EffectiveStatusRowCopyWithImpl<EffectiveStatusRow, EffectiveStatusRow>(
        this as EffectiveStatusRow,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EffectiveStatusRowMapper.ensureInitialized().stringifyValue(
      this as EffectiveStatusRow,
    );
  }

  @override
  bool operator ==(Object other) {
    return EffectiveStatusRowMapper.ensureInitialized().equalsValue(
      this as EffectiveStatusRow,
      other,
    );
  }

  @override
  int get hashCode {
    return EffectiveStatusRowMapper.ensureInitialized().hashValue(
      this as EffectiveStatusRow,
    );
  }
}

extension EffectiveStatusRowValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EffectiveStatusRow, $Out> {
  EffectiveStatusRowCopyWith<$R, EffectiveStatusRow, $Out>
  get $asEffectiveStatusRow => $base.as(
    (v, t, t2) => _EffectiveStatusRowCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class EffectiveStatusRowCopyWith<
  $R,
  $In extends EffectiveStatusRow,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? employeeId,
    DateTime? date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    bool? isExplicit,
    bool? isWeekOff,
    String? timeIn,
    String? timeOut,
    String? note,
  });
  EffectiveStatusRowCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _EffectiveStatusRowCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EffectiveStatusRow, $Out>
    implements EffectiveStatusRowCopyWith<$R, EffectiveStatusRow, $Out> {
  _EffectiveStatusRowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EffectiveStatusRow> $mapper =
      EffectiveStatusRowMapper.ensureInitialized();
  @override
  $R call({
    String? employeeId,
    DateTime? date,
    Object? firstHalfStatus = $none,
    Object? secondHalfStatus = $none,
    bool? isExplicit,
    bool? isWeekOff,
    Object? timeIn = $none,
    Object? timeOut = $none,
    Object? note = $none,
  }) => $apply(
    FieldCopyWithData({
      if (employeeId != null) #employeeId: employeeId,
      if (date != null) #date: date,
      if (firstHalfStatus != $none) #firstHalfStatus: firstHalfStatus,
      if (secondHalfStatus != $none) #secondHalfStatus: secondHalfStatus,
      if (isExplicit != null) #isExplicit: isExplicit,
      if (isWeekOff != null) #isWeekOff: isWeekOff,
      if (timeIn != $none) #timeIn: timeIn,
      if (timeOut != $none) #timeOut: timeOut,
      if (note != $none) #note: note,
    }),
  );
  @override
  EffectiveStatusRow $make(CopyWithData data) => EffectiveStatusRow(
    employeeId: data.get(#employeeId, or: $value.employeeId),
    date: data.get(#date, or: $value.date),
    firstHalfStatus: data.get(#firstHalfStatus, or: $value.firstHalfStatus),
    secondHalfStatus: data.get(#secondHalfStatus, or: $value.secondHalfStatus),
    isExplicit: data.get(#isExplicit, or: $value.isExplicit),
    isWeekOff: data.get(#isWeekOff, or: $value.isWeekOff),
    timeIn: data.get(#timeIn, or: $value.timeIn),
    timeOut: data.get(#timeOut, or: $value.timeOut),
    note: data.get(#note, or: $value.note),
  );

  @override
  EffectiveStatusRowCopyWith<$R2, EffectiveStatusRow, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EffectiveStatusRowCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

