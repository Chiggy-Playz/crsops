import 'dart:io';

import 'package:crs_ops/core/errors/app_exception.dart';
import 'package:crs_ops/core/errors/exception_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('translateException', () {
    test('SocketException becomes NetworkException', () {
      final result = translateException(const SocketException('failed'));
      expect(result, isA<NetworkException>());
    });

    test('AuthException becomes AuthFailureException with the original message', () {
      final result = translateException(AuthException('invalid credentials'));
      expect(result, isA<AuthFailureException>());
      expect(result.message, 'invalid credentials');
    });

    test('PostgrestException becomes DataException with the original message', () {
      final result = translateException(
        PostgrestException(message: 'row-level security violation'),
      );
      expect(result, isA<DataException>());
      expect(result.message, 'row-level security violation');
    });

    test('an already-translated AppException passes through unchanged', () {
      const original = NetworkException();
      expect(translateException(original), same(original));
    });

    test('anything else becomes a generic UnknownException', () {
      final result = translateException(Exception('boom'));
      expect(result, isA<UnknownException>());
    });
  });
}
