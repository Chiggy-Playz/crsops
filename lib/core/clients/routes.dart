import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/window_size.dart';
import '../router/dialog_page.dart';
import '../router/navigator_keys.dart';
import '../widgets/empty_state.dart';
import 'models/client.dart';
import 'models/client_address.dart';
import 'pages/address_edit_page.dart';
import 'pages/client_detail_page.dart';
import 'pages/client_edit_page.dart';
import 'pages/client_list_page.dart';
import 'pages/clients_split_layout.dart';

part 'routes.g.dart';

/// Same shape as the employees routes: list + detail as two panes on wide
/// windows, list → detail pages on narrow ones. The forms are nested
/// sub-routes so they can open above everything as dialogs (see the
/// employees routes for why that needs nesting).
@TypedShellRoute<ClientsShellRoute>(
  routes: [
    TypedGoRoute<ClientsRoute>(
      path: '/clients',
      routes: [
        TypedGoRoute<ClientNewRoute>(path: 'new'),
        TypedGoRoute<ClientDetailRoute>(
          path: ':id',
          routes: [
            TypedGoRoute<ClientEditRoute>(path: 'edit'),
            TypedGoRoute<AddressNewRoute>(path: 'addresses/new'),
            TypedGoRoute<AddressEditRoute>(path: 'addresses/:addressId/edit'),
          ],
        ),
      ],
    ),
  ],
)
class ClientsShellRoute extends ShellRouteData {
  const ClientsShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      ClientsSplitLayout(
        selectedId: state.pathParameters['id'],
        child: navigator,
      );
}

class ClientsRoute extends GoRouteData with $ClientsRoute {
  const ClientsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Wide: the list is the left pane, so the right pane waits for a pick.
    if (context.isTwoPane) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.business_outlined,
          title: 'Select a client',
          message: 'Pick a client from the list to see their addresses.',
        ),
      );
    }
    return const ClientListPage();
  }
}

class ClientNewRoute extends GoRouteData with $ClientNewRoute {
  const ClientNewRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: const ClientEditPage(existing: null),
  );
}

class ClientDetailRoute extends GoRouteData with $ClientDetailRoute {
  const ClientDetailRoute(this.id);
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ClientDetailPage(clientId: id);
}

// The edit forms get the already-fetched record through `extra`. A deep link
// or reload arrives without it, so they fall back to the client's page.

class ClientEditRoute extends GoRouteData with $ClientEditRoute {
  const ClientEditRoute(this.id, {this.$extra});
  final String id;
  final Client? $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is Client ? null : ClientDetailRoute(id).location;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: ClientEditPage(existing: $extra as Client),
  );
}

/// [$extra] is the client, so the new address can start with its name.
class AddressNewRoute extends GoRouteData with $AddressNewRoute {
  const AddressNewRoute(this.id, {this.$extra});
  final String id;
  final Client? $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is Client ? null : ClientDetailRoute(id).location;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: AddressEditPage(
      clientId: id,
      defaultNameOnChallan: ($extra as Client).name,
      existing: null,
    ),
  );
}

class AddressEditRoute extends GoRouteData with $AddressEditRoute {
  const AddressEditRoute(this.id, this.addressId, {this.$extra});
  final String id;
  final String addressId;
  final ClientAddress? $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is ClientAddress ? null : ClientDetailRoute(id).location;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: AddressEditPage(clientId: id, existing: $extra as ClientAddress),
  );
}
