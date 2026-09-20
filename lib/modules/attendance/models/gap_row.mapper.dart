// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'gap_row.dart';

class GapRowMapper extends ClassMapperBase<GapRow> {
  GapRowMapper._();

  static GapRowMapper? _instance;
  static GapRowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GapRowMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GapRow';

  static String _$employeeId(GapRow v) => v.employeeId;
  static const Field<GapRow, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$date(GapRow v) => v.date;
  static const Field<GapRow, DateTime> _f$date = Field('date', _$date);

  @override
  final MappableFields<GapRow> fields = const {
    #employeeId: _f$employeeId,
    #date: _f$date,
  };

  static GapRow _instantiate(DecodingData data) {
    return GapRow(employeeId: data.dec(_f$employeeId), date: data.dec(_f$date));
  }

  @override
  final Function instantiate = _instantiate;

  static GapRow fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GapRow>(map);
  }

  static GapRow fromJson(String json) {
    return ensureInitialized().decodeJson<GapRow>(json);
  }
}

mixin GapRowMappable {
  String toJson() {
    return GapRowMapper.ensureInitialized().encodeJson<GapRow>(this as GapRow);
  }

  Map<String, dynamic> toMap() {
    return GapRowMapper.ensureInitialized().encodeMap<GapRow>(this as GapRow);
  }

  GapRowCopyWith<GapRow, GapRow, GapRow> get copyWith =>
      _GapRowCopyWithImpl<GapRow, GapRow>(this as GapRow, $identity, $identity);
  @override
  String toString() {
    return GapRowMapper.ensureInitialized().stringifyValue(this as GapRow);
  }

  @override
  bool operator ==(Object other) {
    return GapRowMapper.ensureInitialized().equalsValue(this as GapRow, other);
  }

  @override
  int get hashCode {
    return GapRowMapper.ensureInitialized().hashValue(this as GapRow);
  }
}

extension GapRowValueCopy<$R, $Out> on ObjectCopyWith<$R, GapRow, $Out> {
  GapRowCopyWith<$R, GapRow, $Out> get $asGapRow =>
      $base.as((v, t, t2) => _GapRowCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GapRowCopyWith<$R, $In extends GapRow, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? employeeId, DateTime? date});
  GapRowCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GapRowCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, GapRow, $Out>
    implements GapRowCopyWith<$R, GapRow, $Out> {
  _GapRowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GapRow> $mapper = GapRowMapper.ensureInitialized();
  @override
  $R call({String? employeeId, DateTime? date}) => $apply(
    FieldCopyWithData({
      if (employeeId != null) #employeeId: employeeId,
      if (date != null) #date: date,
    }),
  );
  @override
  GapRow $make(CopyWithData data) => GapRow(
    employeeId: data.get(#employeeId, or: $value.employeeId),
    date: data.get(#date, or: $value.date),
  );

  @override
  GapRowCopyWith<$R2, GapRow, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GapRowCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

