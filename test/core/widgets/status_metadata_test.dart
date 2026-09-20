import 'package:crs_ops/core/widgets/status_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconFor', () {
    test('resolves a known icon name', () {
      expect(iconFor('check'), Icons.check);
    });

    test('falls back to help_outline for an unknown name', () {
      expect(iconFor('some_future_icon'), Icons.help_outline);
    });

    test('falls back to help_outline for null', () {
      expect(iconFor(null), Icons.help_outline);
    });
  });

  group('colorFor', () {
    test('parses a hex string into a Color', () {
      expect(colorFor('#4CAF50'), const Color(0xFF4CAF50));
    });

    test('falls back to grey for null', () {
      expect(colorFor(null), Colors.grey);
    });
  });
}
