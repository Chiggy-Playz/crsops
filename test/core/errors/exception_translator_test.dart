import 'dart:io';

import 'package:crs_ops/core/errors/app_exception.dart';
import 'package:crs_ops/core/errors/exception_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('translateException', () {
    test('SocketException becomes NetworkException', () {
      final result = translateException(const SocketException('failed'));
      expect(result, isA<NetworkException>());
    });

    test(
      'AuthException becomes AuthFailureException with the original message',
      () {
        final result = translateException(AuthException('invalid credentials'));
        expect(result, isA<AuthFailureException>());
        expect(result.message, 'invalid credentials');
      },
    );

    test(
      'PostgrestException becomes DataException with a friendly message',
      () {
        final result = translateException(
          PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        );
        expect(result, isA<DataException>());
        expect(result.message, "You don't have permission to do that.");
      },
    );

    test('an unrecognised database error gets the generic message', () {
      final result = translateException(
        PostgrestException(message: 'something odd', code: 'XX000'),
      );
      expect(result.message, 'Something went wrong. Please try again.');
    });

    test('ClientException (how web reports a network failure) becomes '
        'NetworkException', () {
      final result = translateException(
        ClientException('XMLHttpRequest error.'),
      );
      expect(result, isA<NetworkException>());
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
