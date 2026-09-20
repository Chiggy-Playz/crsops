import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/models/app_session.dart';

const signInPath = '/sign-in';
const unauthorizedPath = '/unauthorized';
const loadingPath = '/loading';

String? computeRedirect({
  required AsyncValue<AppSession?> sessionValue,
  required String currentLocation,
}) {
  if (sessionValue.isLoading) {
    return currentLocation == loadingPath ? null : loadingPath;
  }

  if (sessionValue.hasError) {
    return currentLocation == signInPath ? null : signInPath;
  }

  final session = sessionValue.value;

  if (session == null) {
    return currentLocation == signInPath ? null : signInPath;
  }

  if (session.role == null) {
    return currentLocation == unauthorizedPath ? null : unauthorizedPath;
  }

  if (currentLocation == signInPath ||
      currentLocation == unauthorizedPath ||
      currentLocation == loadingPath) {
    return '/';
  }

  return null;
}
