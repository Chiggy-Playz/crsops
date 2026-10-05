import 'package:crs_ops/core/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no version means a development build', () {
    expect(versionLabel(version: '', sha: ''), 'Development build');
    expect(versionLabel(version: '', sha: 'abc1234'), 'Development build');
  });

  test('version and sha', () {
    expect(versionLabel(version: '1.4.2', sha: 'abc1234'), '1.4.2 · abc1234');
  });

  test('version without sha', () {
    expect(versionLabel(version: '1.4.2', sha: ''), '1.4.2');
  });
}
