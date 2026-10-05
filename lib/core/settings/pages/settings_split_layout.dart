import 'package:flutter/material.dart';

import '../../layout/two_pane_layout.dart';
import 'settings_page.dart';

/// Settings on wide windows: the hub on the left, the selected setting's page
/// (the routed [child]) on the right. Narrow windows show [child] alone.
class SettingsSplitLayout extends StatelessWidget {
  const SettingsSplitLayout({
    super.key,
    required this.selectedLocation,
    required this.child,
  });

  final String selectedLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TwoPaneLayout(
      pane: SettingsPage(selectedLocation: selectedLocation),
      child: child,
    );
  }
}
