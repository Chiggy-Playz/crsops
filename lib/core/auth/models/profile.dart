import 'package:dart_mappable/dart_mappable.dart';

part 'profile.mapper.dart';

@MappableClass()
class Profile with ProfileMappable {
  const Profile({required this.id, required this.email, required this.createdAt});

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'email')
  final String email;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
