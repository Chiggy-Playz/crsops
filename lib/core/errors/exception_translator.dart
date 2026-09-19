import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

AppException translateException(Object error) {
  if (error is AppException) return error;
  if (error is SocketException) return const NetworkException();
  if (error is AuthException) return AuthFailureException(error.message);
  if (error is PostgrestException) return DataException(error.message);
  return const UnknownException();
}
