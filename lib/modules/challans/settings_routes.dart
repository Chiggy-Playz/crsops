import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/handlers_manager_page.dart';

part 'settings_routes.g.dart';

// Challan pages opened from the Settings hub — see the attendance
// settings_routes.dart for why these live under /settings/<section>/.

@TypedGoRoute<HandlersRoute>(path: '/settings/challans/handlers')
class HandlersRoute extends GoRouteData with $HandlersRoute {
  const HandlersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HandlersManagerPage();
}
