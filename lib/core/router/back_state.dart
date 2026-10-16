import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// For `MaterialApp.router(onNavigationNotification: …)`: tells Android
/// whether back is the app's to handle, from what the router can really go
/// back from ([canGoBack]).
///
/// Android's predictive back decides up front, from the last report, whether
/// back stays in the app or leaves it. The navigators each report their own
/// state, and the last report wins: when a dialog closed, the outer navigator
/// said "nothing to go back to" although the page underneath (inside a
/// section) could still go back, so the next back quit the app. The router
/// knows the truth, whichever navigator spoke last.
bool Function(NavigationNotification) reportBackState(
  bool Function() canGoBack,
) {
  return (notification) {
    SystemNavigator.setFrameworkHandlesBack(canGoBack());
    return true;
  };
}
