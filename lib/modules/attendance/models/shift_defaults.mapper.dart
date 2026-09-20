// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'shift_defaults.dart';

class ShiftDefaultsMapper extends ClassMapperBase<ShiftDefaults> {
  ShiftDefaultsMapper._();

  static ShiftDefaultsMapper? _instance;
  static ShiftDefaultsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShiftDefaultsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShiftDefaults';

  static String _$id(ShiftDefaults v) => v.id;
  static const Field<ShiftDefaults, String> _f$id = Field('id', _$id);
  static DateTime _$effectiveFrom(ShiftDefaults v) => v.effectiveFrom;
  static const Field<ShiftDefaults, DateTime> _f$effectiveFrom = Field(
    'effectiveFrom',
    _$effectiveFrom,
    key: r'effective_from',
  );
  static String _$defaultStart(ShiftDefaults v) => v.defaultStart;
  static const Field<ShiftDefaults, String> _f$defaultStart = Field(
    'defaultStart',
    _$defaultStart,
    key: r'default_start',
  );
  static String _$defaultEnd(ShiftDefaults v) => v.defaultEnd;
  static const Field<ShiftDefaults, String> _f$defaultEnd = Field(
    'defaultEnd',
    _$defaultEnd,
    key: r'default_end',
  );
  static List<int> _$weekOffDays(ShiftDefaults v) => v.weekOffDays;
  static const Field<ShiftDefaults, List<int>> _f$weekOffDays = Field(
    'weekOffDays',
    _$weekOffDays,
    key: r'week_off_days',
  );

  @override
  final MappableFields<ShiftDefaults> fields = const {
    #id: _f$id,
    #effectiveFrom: _f$effectiveFrom,
    #defaultStart: _f$defaultStart,
    #defaultEnd: _f$defaultEnd,
    #weekOffDays: _f$weekOffDays,
  };

  static ShiftDefaults _instantiate(DecodingData data) {
    return ShiftDefaults(
      id: data.dec(_f$id),
      effectiveFrom: data.dec(_f$effectiveFrom),
      defaultStart: data.dec(_f$defaultStart),
      defaultEnd: data.dec(_f$defaultEnd),
      weekOffDays: data.dec(_f$weekOffDays),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShiftDefaults fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShiftDefaults>(map);
  }

  static ShiftDefaults fromJson(String json) {
    return ensureInitialized().decodeJson<ShiftDefaults>(json);
  }
}

mixin ShiftDefaultsMappable {
  String toJson() {
    return ShiftDefaultsMapper.ensureInitialized().encodeJson<ShiftDefaults>(
      this as ShiftDefaults,
    );
  }

  Map<String, dynamic> toMap() {
    return ShiftDefaultsMapper.ensureInitialized().encodeMap<ShiftDefaults>(
      this as ShiftDefaults,
    );
  }

  ShiftDefaultsCopyWith<ShiftDefaults, ShiftDefaults, ShiftDefaults>
  get copyWith => _ShiftDefaultsCopyWithImpl<ShiftDefaults, ShiftDefaults>(
    this as ShiftDefaults,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ShiftDefaultsMapper.ensureInitialized().stringifyValue(
      this as ShiftDefaults,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShiftDefaultsMapper.ensureInitialized().equalsValue(
      this as ShiftDefaults,
      other,
    );
  }

  @override
  int get hashCode {
    return ShiftDefaultsMapper.ensureInitialized().hashValue(
      this as ShiftDefaults,
    );
  }
}

extension ShiftDefaultsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShiftDefaults, $Out> {
  ShiftDefaultsCopyWith<$R, ShiftDefaults, $Out> get $asShiftDefaults =>
      $base.as((v, t, t2) => _ShiftDefaultsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShiftDefaultsCopyWith<$R, $In extends ShiftDefaults, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get weekOffDays;
  $R call({
    String? id,
    DateTime? effectiveFrom,
    String? defaultStart,
    String? defaultEnd,
    List<int>? weekOffDays,
  });
  ShiftDefaultsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShiftDefaultsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShiftDefaults, $Out>
    implements ShiftDefaultsCopyWith<$R, ShiftDefaults, $Out> {
  _ShiftDefaultsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShiftDefaults> $mapper =
      ShiftDefaultsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get weekOffDays =>
      ListCopyWith(
        $value.weekOffDays,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(weekOffDays: v),
      );
  @override
  $R call({
    String? id,
    DateTime? effectiveFrom,
    String? defaultStart,
    String? defaultEnd,
    List<int>? weekOffDays,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (effectiveFrom != null) #effectiveFrom: effectiveFrom,
      if (defaultStart != null) #defaultStart: defaultStart,
      if (defaultEnd != null) #defaultEnd: defaultEnd,
      if (weekOffDays != null) #weekOffDays: weekOffDays,
    }),
  );
  @override
  ShiftDefaults $make(CopyWithData data) => ShiftDefaults(
    id: data.get(#id, or: $value.id),
    effectiveFrom: data.get(#effectiveFrom, or: $value.effectiveFrom),
    defaultStart: data.get(#defaultStart, or: $value.defaultStart),
    defaultEnd: data.get(#defaultEnd, or: $value.defaultEnd),
    weekOffDays: data.get(#weekOffDays, or: $value.weekOffDays),
  );

  @override
  ShiftDefaultsCopyWith<$R2, ShiftDefaults, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShiftDefaultsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

