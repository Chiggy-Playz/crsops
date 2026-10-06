import 'package:flutter/material.dart';

import '../modules/module_names.dart';
import '../sections/app_section.dart';
import 'routes.dart' as routes;

/// Clients are core (other modules will use them too), but for now only the
/// challans module needs them, so its access grant decides who sees them.
final clientsSection = AppSection(
  label: 'Clients',
  icon: Icons.business_outlined,
  selectedIcon: Icons.business,
  canAccess: (s) => s.hasModuleAccess(ModuleNames.challans),
  pathPrefix: '/clients',
  homeLocation: const routes.ClientsRoute().location,
  routes: routes.$appRoutes,
);
