// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'challan_direction.dart';

class ChallanDirectionMapper extends EnumMapper<ChallanDirection> {
  ChallanDirectionMapper._();

  static ChallanDirectionMapper? _instance;
  static ChallanDirectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChallanDirectionMapper._());
    }
    return _instance!;
  }

  static ChallanDirection fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ChallanDirection decode(dynamic value) {
    switch (value) {
      case r'outward':
        return ChallanDirection.outward;
      case r'inward':
        return ChallanDirection.inward;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ChallanDirection self) {
    switch (self) {
      case ChallanDirection.outward:
        return r'outward';
      case ChallanDirection.inward:
        return r'inward';
    }
  }
}

extension ChallanDirectionMapperExtension on ChallanDirection {
  String toValue() {
    ChallanDirectionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ChallanDirection>(this) as String;
  }
}

