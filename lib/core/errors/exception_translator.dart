import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_talker.dart';
import 'app_exception.dart';

/// Turns any error from Supabase or the network into an [AppException]
/// whose message is fit to show the user. The original error is logged,
/// since the friendly message hides the technical detail.
AppException translateException(Object error) {
  if (error is AppException) return error;
  if (error is SocketException) return const NetworkException();
  // On web every failed request is a ClientException ("XMLHttpRequest
  // error"); on Android/desktop it's the SocketException above.
  if (error is ClientException) return const NetworkException();
  // Auth's own wrapper for "couldn't reach the server".
  if (error is AuthRetryableFetchException) return const NetworkException();
  if (error is AuthException) return AuthFailureException(error.message);
  if (error is PostgrestException) {
    appTalker.error('Database error ${error.code}: ${error.message}', error);
    return DataException(friendlyDatabaseMessage(error));
  }
  appTalker.error('Unexpected error', error);
  return const UnknownException();
}

/// A plain-language message for a database error, chosen by its Postgres
/// (or PostgREST) error code.
String friendlyDatabaseMessage(PostgrestException error) {
  switch (error.code) {
    // unique_violation: a row with the same key already exists.
    case '23505':
      return 'That already exists.';
    // foreign_key_violation: deleting a row something else still points
    // at, or saving a row that points at something that's gone.
    case '23503':
      if (error.message.startsWith('update or delete')) {
        return "It's still in use, so it can't be removed.";
      }
      return 'Something it refers to no longer exists. Refresh and try again.';
    // insufficient_privilege: blocked by a row-level security policy.
    case '42501':
      return "You don't have permission to do that.";
    // PostgREST: .single() found no row, e.g. it was deleted meanwhile or
    // RLS hides it.
    case 'PGRST116':
      return 'That no longer exists. It may have been deleted.';
    // raise_exception: our own database functions refusing something
    // ("A client named … already exists."). Those messages are written for
    // the user, so show them as they are.
    case 'P0001':
      return error.message;
    default:
      return 'Something went wrong. Please try again.';
  }
}
