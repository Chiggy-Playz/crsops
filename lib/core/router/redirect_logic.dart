import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/models/app_session.dart';
import '../sections/app_section.dart';

const signInPath = '/sign-in';
const unauthorizedPath = '/unauthorized';
const loadingPath = '/loading';
const noModulesPath = '/no-modules';

const _authPaths = {signInPath, unauthorizedPath, loadingPath, noModulesPath};

/// Where a signed-in user with a role belongs by default: the first landable
/// section they can access, in nav order. Settings isn't landable, so a user
/// who can only see Settings gets the no-modules page.
String landingLocation(AppSession session, List<AppSection> sections) {
  for (final section in sections) {
    if (section.isLandingCandidate && section.canAccess(session)) {
      return section.homeLocation;
    }
  }
  return noModulesPath;
}

String? computeRedirect({
  required AsyncValue<AppSession?> sessionValue,
  required String currentLocation,
  required List<AppSection> sections,
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

  final landing = landingLocation(session, sections);
  String? toLanding() => currentLocation == landing ? null : landing;

  // Guard failures go straight to the user's landing page. Nav visibility
  // reads the same canAccess, so a hidden section is also a locked one —
  // typing its URL (web) or opening an old bookmark lands you back home.
  for (final section in sections) {
    if (section.owns(currentLocation) && !section.canAccess(session)) {
      return toLanding();
    }
    final roleCheck = section.roleGuards[currentLocation];
    if (roleCheck != null && !roleCheck(session)) {
      return toLanding();
    }
  }

  if (_authPaths.contains(currentLocation) || currentLocation == '/') {
    return toLanding();
  }

  return null;
}
