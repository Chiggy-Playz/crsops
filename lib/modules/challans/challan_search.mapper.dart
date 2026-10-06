// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'challan_search.dart';

class ChallanSearchFiltersMapper extends ClassMapperBase<ChallanSearchFilters> {
  ChallanSearchFiltersMapper._();

  static ChallanSearchFiltersMapper? _instance;
  static ChallanSearchFiltersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChallanSearchFiltersMapper._());
      ChallanDirectionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChallanSearchFilters';

  static String _$text(ChallanSearchFilters v) => v.text;
  static const Field<ChallanSearchFilters, String> _f$text = Field(
    'text',
    _$text,
    opt: true,
    def: '',
  );
  static List<String> _$clientIds(ChallanSearchFilters v) => v.clientIds;
  static const Field<ChallanSearchFilters, List<String>> _f$clientIds = Field(
    'clientIds',
    _$clientIds,
    opt: true,
    def: const [],
  );
  static DateTime? _$from(ChallanSearchFilters v) => v.from;
  static const Field<ChallanSearchFilters, DateTime> _f$from = Field(
    'from',
    _$from,
    opt: true,
  );
  static DateTime? _$to(ChallanSearchFilters v) => v.to;
  static const Field<ChallanSearchFilters, DateTime> _f$to = Field(
    'to',
    _$to,
    opt: true,
  );
  static ChallanDirection? _$direction(ChallanSearchFilters v) => v.direction;
  static const Field<ChallanSearchFilters, ChallanDirection> _f$direction =
      Field('direction', _$direction, opt: true);

  @override
  final MappableFields<ChallanSearchFilters> fields = const {
    #text: _f$text,
    #clientIds: _f$clientIds,
    #from: _f$from,
    #to: _f$to,
    #direction: _f$direction,
  };

  static ChallanSearchFilters _instantiate(DecodingData data) {
    return ChallanSearchFilters(
      text: data.dec(_f$text),
      clientIds: data.dec(_f$clientIds),
      from: data.dec(_f$from),
      to: data.dec(_f$to),
      direction: data.dec(_f$direction),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChallanSearchFilters fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChallanSearchFilters>(map);
  }

  static ChallanSearchFilters fromJson(String json) {
    return ensureInitialized().decodeJson<ChallanSearchFilters>(json);
  }
}

mixin ChallanSearchFiltersMappable {
  String toJson() {
    return ChallanSearchFiltersMapper.ensureInitialized()
        .encodeJson<ChallanSearchFilters>(this as ChallanSearchFilters);
  }

  Map<String, dynamic> toMap() {
    return ChallanSearchFiltersMapper.ensureInitialized()
        .encodeMap<ChallanSearchFilters>(this as ChallanSearchFilters);
  }

  ChallanSearchFiltersCopyWith<
    ChallanSearchFilters,
    ChallanSearchFilters,
    ChallanSearchFilters
  >
  get copyWith =>
      _ChallanSearchFiltersCopyWithImpl<
        ChallanSearchFilters,
        ChallanSearchFilters
      >(this as ChallanSearchFilters, $identity, $identity);
  @override
  String toString() {
    return ChallanSearchFiltersMapper.ensureInitialized().stringifyValue(
      this as ChallanSearchFilters,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChallanSearchFiltersMapper.ensureInitialized().equalsValue(
      this as ChallanSearchFilters,
      other,
    );
  }

  @override
  int get hashCode {
    return ChallanSearchFiltersMapper.ensureInitialized().hashValue(
      this as ChallanSearchFilters,
    );
  }
}

extension ChallanSearchFiltersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChallanSearchFilters, $Out> {
  ChallanSearchFiltersCopyWith<$R, ChallanSearchFilters, $Out>
  get $asChallanSearchFilters => $base.as(
    (v, t, t2) => _ChallanSearchFiltersCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ChallanSearchFiltersCopyWith<
  $R,
  $In extends ChallanSearchFilters,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get clientIds;
  $R call({
    String? text,
    List<String>? clientIds,
    DateTime? from,
    DateTime? to,
    ChallanDirection? direction,
  });
  ChallanSearchFiltersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ChallanSearchFiltersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChallanSearchFilters, $Out>
    implements ChallanSearchFiltersCopyWith<$R, ChallanSearchFilters, $Out> {
  _ChallanSearchFiltersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChallanSearchFilters> $mapper =
      ChallanSearchFiltersMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get clientIds =>
      ListCopyWith(
        $value.clientIds,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(clientIds: v),
      );
  @override
  $R call({
    String? text,
    List<String>? clientIds,
    Object? from = $none,
    Object? to = $none,
    Object? direction = $none,
  }) => $apply(
    FieldCopyWithData({
      if (text != null) #text: text,
      if (clientIds != null) #clientIds: clientIds,
      if (from != $none) #from: from,
      if (to != $none) #to: to,
      if (direction != $none) #direction: direction,
    }),
  );
  @override
  ChallanSearchFilters $make(CopyWithData data) => ChallanSearchFilters(
    text: data.get(#text, or: $value.text),
    clientIds: data.get(#clientIds, or: $value.clientIds),
    from: data.get(#from, or: $value.from),
    to: data.get(#to, or: $value.to),
    direction: data.get(#direction, or: $value.direction),
  );

  @override
  ChallanSearchFiltersCopyWith<$R2, ChallanSearchFilters, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ChallanSearchFiltersCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

