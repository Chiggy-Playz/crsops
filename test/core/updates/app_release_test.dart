import 'package:crs_ops/core/updates/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewerVersion', () {
    test('compares each part as a number', () {
      expect(isNewerVersion('1.4.10', '1.4.9'), isTrue);
      expect(isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.99.99'), isTrue);
    });

    test('same or older is not newer', () {
      expect(isNewerVersion('1.4.2', '1.4.2'), isFalse);
      expect(isNewerVersion('1.4.1', '1.4.2'), isFalse);
    });

    test('accepts a leading v (tag names)', () {
      expect(isNewerVersion('v1.0.3', '1.0.2'), isTrue);
    });

    test('malformed versions are never newer', () {
      expect(isNewerVersion('1.5', '1.4.2'), isFalse);
      expect(isNewerVersion('latest', '1.4.2'), isFalse);
      expect(isNewerVersion('1.5.0', ''), isFalse);
    });
  });

  group('pickApkAsset', () {
    const arm64 = ReleaseAsset(name: 'crs-ops-1.0.2-arm64-v8a.apk', url: 'a', bytes: 1);
    const armv7 = ReleaseAsset(name: 'crs-ops-1.0.2-armeabi-v7a.apk', url: 'b', bytes: 1);

    test("follows the phone's ABI preference order", () {
      expect(pickApkAsset([armv7, arm64], ['arm64-v8a', 'armeabi-v7a']), arm64);
      expect(pickApkAsset([arm64, armv7], ['armeabi-v7a', 'armeabi']), armv7);
    });

    test('null when no APK fits the phone', () {
      expect(pickApkAsset([arm64, armv7], ['x86_64']), isNull);
    });
  });
}
