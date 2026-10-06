import 'package:dart_mappable/dart_mappable.dart';

part 'indian_state.mapper.dart';

/// A state or union territory with its two-digit GST code ("07" = Delhi).
@MappableClass()
class IndianState with IndianStateMappable {
  const IndianState({required this.code, required this.name});

  @MappableField(key: 'code')
  final String code;
  @MappableField(key: 'name')
  final String name;
}
