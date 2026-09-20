import 'package:flutter/material.dart';

const _iconByName = <String, IconData>{
  'check': Icons.check,
  'close': Icons.close,
  'event_busy': Icons.event_busy,
  'beach_access': Icons.beach_access,
  'weekend': Icons.weekend,
  // extend as new icon needs come up; an unrecognized name falls through below
};

IconData iconFor(String? iconName) => _iconByName[iconName] ?? Icons.help_outline;

Color colorFor(String? colorHex) => colorHex == null
    ? Colors.grey
    : Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));
