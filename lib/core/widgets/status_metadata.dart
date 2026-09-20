import 'package:flutter/material.dart';

const _iconByName = <String, IconData>{
  'check': Icons.check,
  'close': Icons.close,
  'event_busy': Icons.event_busy,
  'beach_access': Icons.beach_access,
  'weekend': Icons.weekend,
  // extend as new icon needs come up; an unrecognized name falls through below
};

IconData iconFor(String? iconName) =>
    _iconByName[iconName] ?? Icons.help_outline;

/// The curated icon names a status/event type may use — the single source
/// for the manager-page dropdowns, so adding a key to [_iconByName] reaches
/// every picker without a lockstep edit elsewhere.
List<String> get knownIconNames => _iconByName.keys.toList();

Color colorFor(String? colorHex) {
  // One malformed color_hex row must never crash every screen that renders
  // a color — fall back to grey on anything that isn't #RRGGBB.
  final hex = colorHex?.replaceFirst('#', '');
  final value = hex != null && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)
      ? int.tryParse('FF$hex', radix: 16)
      : null;
  return value == null ? Colors.grey : Color(value);
}

/// Ids/entry types are stored as lowercase slugs (`rehired`, `salary_payment`)
/// so they stay stable as FK/lookup keys — this only affects how they're shown.
String displayLabel(String id) => id
    .split(RegExp('[_ ]+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

String initialsFor(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();

Color contrastingTextColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;
