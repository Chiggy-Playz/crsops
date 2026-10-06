// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'indian_state.dart';

class IndianStateMapper extends ClassMapperBase<IndianState> {
  IndianStateMapper._();

  static IndianStateMapper? _instance;
  static IndianStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = IndianStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'IndianState';

  static String _$code(IndianState v) => v.code;
  static const Field<IndianState, String> _f$code = Field('code', _$code);
  static String _$name(IndianState v) => v.name;
  static const Field<IndianState, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<IndianState> fields = const {
    #code: _f$code,
    #name: _f$name,
  };

  static IndianState _instantiate(DecodingData data) {
    return IndianState(code: data.dec(_f$code), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static IndianState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<IndianState>(map);
  }

  static IndianState fromJson(String json) {
    return ensureInitialized().decodeJson<IndianState>(json);
  }
}

mixin IndianStateMappable {
  String toJson() {
    return IndianStateMapper.ensureInitialized().encodeJson<IndianState>(
      this as IndianState,
    );
  }

  Map<String, dynamic> toMap() {
    return IndianStateMapper.ensureInitialized().encodeMap<IndianState>(
      this as IndianState,
    );
  }

  IndianStateCopyWith<IndianState, IndianState, IndianState> get copyWith =>
      _IndianStateCopyWithImpl<IndianState, IndianState>(
        this as IndianState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return IndianStateMapper.ensureInitialized().stringifyValue(
      this as IndianState,
    );
  }

  @override
  bool operator ==(Object other) {
    return IndianStateMapper.ensureInitialized().equalsValue(
      this as IndianState,
      other,
    );
  }

  @override
  int get hashCode {
    return IndianStateMapper.ensureInitialized().hashValue(this as IndianState);
  }
}

extension IndianStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, IndianState, $Out> {
  IndianStateCopyWith<$R, IndianState, $Out> get $asIndianState =>
      $base.as((v, t, t2) => _IndianStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class IndianStateCopyWith<$R, $In extends IndianState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? code, String? name});
  IndianStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _IndianStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, IndianState, $Out>
    implements IndianStateCopyWith<$R, IndianState, $Out> {
  _IndianStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<IndianState> $mapper =
      IndianStateMapper.ensureInitialized();
  @override
  $R call({String? code, String? name}) => $apply(
    FieldCopyWithData({
      if (code != null) #code: code,
      if (name != null) #name: name,
    }),
  );
  @override
  IndianState $make(CopyWithData data) => IndianState(
    code: data.get(#code, or: $value.code),
    name: data.get(#name, or: $value.name),
  );

  @override
  IndianStateCopyWith<$R2, IndianState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _IndianStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

