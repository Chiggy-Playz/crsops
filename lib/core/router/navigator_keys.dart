import 'package:flutter/widgets.dart';

/// The navigator above the nav shell. Routes that set this as their
/// `$parentNavigatorKey` (focused tasks like new/edit employee) cover the bar.
final rootNavigatorKey = GlobalKey<NavigatorState>();
