import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

late final Talker appTalker;

Future<void> initAppTalker() async {
  appTalker = TalkerFlutter.init(
    settings: TalkerSettings(useConsoleLogs: true),
  );

  // Browsers have no app file system: path_provider has no web
  // implementation (MissingPluginException at startup) and dart:io's File
  // doesn't work there. Web keeps the console logs (browser DevTools) only.
  if (kIsWeb) return;

  final dir = await getApplicationSupportDirectory();
  final logFile = File('${dir.path}/crs_ops.log');

  appTalker.stream.listen((event) {
    logFile.writeAsStringSync(
      '${DateTime.now().toIso8601String()} ${event.title}: ${event.message}\n',
      mode: FileMode.append,
    );
  });
}
