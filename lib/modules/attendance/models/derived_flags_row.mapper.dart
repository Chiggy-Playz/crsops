// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'derived_flags_row.dart';

class DerivedFlagsRowMapper extends ClassMapperBase<DerivedFlagsRow> {
  DerivedFlagsRowMapper._();

  static DerivedFlagsRowMapper? _instance;
  static DerivedFlagsRowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DerivedFlagsRowMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DerivedFlagsRow';

  static String _$employeeId(DerivedFlagsRow v) => v.employeeId;
  static const Field<DerivedFlagsRow, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$date(DerivedFlagsRow v) => v.date;
  static const Field<DerivedFlagsRow, DateTime> _f$date = Field('date', _$date);
  static String? _$timeIn(DerivedFlagsRow v) => v.timeIn;
  static const Field<DerivedFlagsRow, String> _f$timeIn = Field(
    'timeIn',
    _$timeIn,
    key: r'time_in',
    opt: true,
  );
  static String? _$timeOut(DerivedFlagsRow v) => v.timeOut;
  static const Field<DerivedFlagsRow, String> _f$timeOut = Field(
    'timeOut',
    _$timeOut,
    key: r'time_out',
    opt: true,
  );
  static int _$workedMinutes(DerivedFlagsRow v) => v.workedMinutes;
  static const Field<DerivedFlagsRow, int> _f$workedMinutes = Field(
    'workedMinutes',
    _$workedMinutes,
    key: r'worked_minutes',
  );
  static bool _$isLate(DerivedFlagsRow v) => v.isLate;
  static const Field<DerivedFlagsRow, bool> _f$isLate = Field(
    'isLate',
    _$isLate,
    key: r'is_late',
  );
  static bool _$isEarly(DerivedFlagsRow v) => v.isEarly;
  static const Field<DerivedFlagsRow, bool> _f$isEarly = Field(
    'isEarly',
    _$isEarly,
    key: r'is_early',
  );
  static int _$overtimeMinutes(DerivedFlagsRow v) => v.overtimeMinutes;
  static const Field<DerivedFlagsRow, int> _f$overtimeMinutes = Field(
    'overtimeMinutes',
    _$overtimeMinutes,
    key: r'overtime_minutes',
  );

  @override
  final MappableFields<DerivedFlagsRow> fields = const {
    #employeeId: _f$employeeId,
    #date: _f$date,
    #timeIn: _f$timeIn,
    #timeOut: _f$timeOut,
    #workedMinutes: _f$workedMinutes,
    #isLate: _f$isLate,
    #isEarly: _f$isEarly,
    #overtimeMinutes: _f$overtimeMinutes,
  };

  static DerivedFlagsRow _instantiate(DecodingData data) {
    return DerivedFlagsRow(
      employeeId: data.dec(_f$employeeId),
      date: data.dec(_f$date),
      timeIn: data.dec(_f$timeIn),
      timeOut: data.dec(_f$timeOut),
      workedMinutes: data.dec(_f$workedMinutes),
      isLate: data.dec(_f$isLate),
      isEarly: data.dec(_f$isEarly),
      overtimeMinutes: data.dec(_f$overtimeMinutes),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DerivedFlagsRow fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DerivedFlagsRow>(map);
  }

  static DerivedFlagsRow fromJson(String json) {
    return ensureInitialized().decodeJson<DerivedFlagsRow>(json);
  }
}

mixin DerivedFlagsRowMappable {
  String toJson() {
    return DerivedFlagsRowMapper.ensureInitialized()
        .encodeJson<DerivedFlagsRow>(this as DerivedFlagsRow);
  }

  Map<String, dynamic> toMap() {
    return DerivedFlagsRowMapper.ensureInitialized().encodeMap<DerivedFlagsRow>(
      this as DerivedFlagsRow,
    );
  }

  DerivedFlagsRowCopyWith<DerivedFlagsRow, DerivedFlagsRow, DerivedFlagsRow>
  get copyWith =>
      _DerivedFlagsRowCopyWithImpl<DerivedFlagsRow, DerivedFlagsRow>(
        this as DerivedFlagsRow,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DerivedFlagsRowMapper.ensureInitialized().stringifyValue(
      this as DerivedFlagsRow,
    );
  }

  @override
  bool operator ==(Object other) {
    return DerivedFlagsRowMapper.ensureInitialized().equalsValue(
      this as DerivedFlagsRow,
      other,
    );
  }

  @override
  int get hashCode {
    return DerivedFlagsRowMapper.ensureInitialized().hashValue(
      this as DerivedFlagsRow,
    );
  }
}

extension DerivedFlagsRowValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DerivedFlagsRow, $Out> {
  DerivedFlagsRowCopyWith<$R, DerivedFlagsRow, $Out> get $asDerivedFlagsRow =>
      $base.as((v, t, t2) => _DerivedFlagsRowCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DerivedFlagsRowCopyWith<$R, $In extends DerivedFlagsRow, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? employeeId,
    DateTime? date,
    String? timeIn,
    String? timeOut,
    int? workedMinutes,
    bool? isLate,
    bool? isEarly,
    int? overtimeMinutes,
  });
  DerivedFlagsRowCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DerivedFlagsRowCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DerivedFlagsRow, $Out>
    implements DerivedFlagsRowCopyWith<$R, DerivedFlagsRow, $Out> {
  _DerivedFlagsRowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DerivedFlagsRow> $mapper =
      DerivedFlagsRowMapper.ensureInitialized();
  @override
  $R call({
    String? employeeId,
    DateTime? date,
    Object? timeIn = $none,
    Object? timeOut = $none,
    int? workedMinutes,
    bool? isLate,
    bool? isEarly,
    int? overtimeMinutes,
  }) => $apply(
    FieldCopyWithData({
      if (employeeId != null) #employeeId: employeeId,
      if (date != null) #date: date,
      if (timeIn != $none) #timeIn: timeIn,
      if (timeOut != $none) #timeOut: timeOut,
      if (workedMinutes != null) #workedMinutes: workedMinutes,
      if (isLate != null) #isLate: isLate,
      if (isEarly != null) #isEarly: isEarly,
      if (overtimeMinutes != null) #overtimeMinutes: overtimeMinutes,
    }),
  );
  @override
  DerivedFlagsRow $make(CopyWithData data) => DerivedFlagsRow(
    employeeId: data.get(#employeeId, or: $value.employeeId),
    date: data.get(#date, or: $value.date),
    timeIn: data.get(#timeIn, or: $value.timeIn),
    timeOut: data.get(#timeOut, or: $value.timeOut),
    workedMinutes: data.get(#workedMinutes, or: $value.workedMinutes),
    isLate: data.get(#isLate, or: $value.isLate),
    isEarly: data.get(#isEarly, or: $value.isEarly),
    overtimeMinutes: data.get(#overtimeMinutes, or: $value.overtimeMinutes),
  );

  @override
  DerivedFlagsRowCopyWith<$R2, DerivedFlagsRow, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DerivedFlagsRowCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

