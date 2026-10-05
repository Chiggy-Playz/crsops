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
/// The reverse of [slugify].
String displayLabel(String id) => titleCase(id.replaceAll('_', ' '));

/// Capitalises the first letter of each word and tidies the spacing
/// (`  ramesh   kumar ` → `Ramesh Kumar`). The rest of each word is left as
/// typed, so `McDonald` stays `McDonald`. Names and labels people type are
/// saved through this so they always show title-cased.
String titleCase(String input) => input
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// What the user typed as a new type/category, as the id it's stored under:
/// lowercase words joined by underscores (`Sick Leave` → `sick_leave`).
/// Without this, `Warning` and `warning` would become two different ids.
String slugify(String input) => input
    .trim()
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .join('_');

String initialsFor(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();
