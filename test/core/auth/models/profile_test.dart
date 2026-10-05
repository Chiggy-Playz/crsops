import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('decodes a realistic row', () {
      final profile = ProfileMapper.fromMap({
        'id': 'u1',
        'email': 'dad@example.com',
        'created_at': '2024-01-01T00:00:00.000',
      });

      expect(profile.id, 'u1');
      expect(profile.email, 'dad@example.com');
    });

    test('round-trips through a map', () {
      final profile = ProfileMapper.fromMap(
        Profile(
          id: 'u1',
          email: 'dad@example.com',
          createdAt: DateTime(2024, 1, 1),
        ).toMap(),
      );

      expect(profile.id, 'u1');
      expect(profile.email, 'dad@example.com');
    });
  });
}
