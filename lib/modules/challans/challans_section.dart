import 'package:flutter/material.dart';

import '../../core/modules/module_names.dart';
import '../../core/sections/app_section.dart';
import 'pages/widgets/client_challans_panel.dart';
import 'routes.dart' as routes;

final challansSection = AppSection(
  label: 'Challans',
  icon: Icons.receipt_long_outlined,
  selectedIcon: Icons.receipt_long,
  canAccess: (s) => s.hasModuleAccess(ModuleNames.challans),
  pathPrefix: '/challans',
  homeLocation: const routes.ChallansRoute().location,
  routes: routes.$appRoutes,
  clientPanels: [
    ClientPanel(
      icon: Icons.receipt_long_outlined,
      title: 'Challans',
      canSee: (s) => s.hasModuleAccess(ModuleNames.challans),
      builder: (context, clientId) => ClientChallansPanel(clientId: clientId),
    ),
  ],
);
