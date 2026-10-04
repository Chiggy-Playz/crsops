import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/loading_page.dart';
import '../auth/pages/no_modules_page.dart';
import '../auth/pages/sign_in_page.dart';
import '../auth/pages/unauthorized_page.dart';
import 'redirect_logic.dart';

part 'auth_routes.g.dart';

@TypedGoRoute<LoadingRoute>(path: loadingPath)
class LoadingRoute extends GoRouteData with $LoadingRoute {
  const LoadingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoadingPage();
}

@TypedGoRoute<SignInRoute>(path: signInPath)
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SignInPage();
}

@TypedGoRoute<UnauthorizedRoute>(path: unauthorizedPath)
class UnauthorizedRoute extends GoRouteData with $UnauthorizedRoute {
  const UnauthorizedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UnauthorizedPage();
}

@TypedGoRoute<NoModulesRoute>(path: noModulesPath)
class NoModulesRoute extends GoRouteData with $NoModulesRoute {
  const NoModulesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NoModulesPage();
}
