import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

late final Talker appTalker;

Future<void> initAppTalker() async {
  final dir = await getApplicationSupportDirectory();
  final logFile = File('${dir.path}/crs_ops.log');

  appTalker = TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: true,
    ),
  );

  appTalker.stream.listen((event) {
    logFile.writeAsStringSync(
      '${DateTime.now().toIso8601String()} ${event.title}: ${event.message}\n',
      mode: FileMode.append,
    );
  });
}
