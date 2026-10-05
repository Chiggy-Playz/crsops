import 'package:crs_ops/core/layout/window_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowSize.of', () {
    test('follows the M3 size-class boundaries', () {
      expect(WindowSize.of(599), WindowSize.compact);
      expect(WindowSize.of(600), WindowSize.medium);
      expect(WindowSize.of(839), WindowSize.medium);
      expect(WindowSize.of(840), WindowSize.expanded);
      expect(WindowSize.of(1199), WindowSize.expanded);
      expect(WindowSize.of(1200), WindowSize.large);
    });
  });
}
