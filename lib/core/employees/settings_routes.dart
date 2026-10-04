import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/event_types_manager_page.dart';

part 'settings_routes.g.dart';

// Employee pages opened from the Settings hub — see the attendance
// settings_routes.dart for why these live under /settings/<section>/.

@TypedGoRoute<EventTypesRoute>(path: '/settings/employees/event-types')
class EventTypesRoute extends GoRouteData with $EventTypesRoute {
  const EventTypesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EventTypesManagerPage();
}
