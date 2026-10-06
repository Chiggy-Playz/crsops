import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/app_snack_bar.dart';

/// Hands a file the app made (an export) to the user: the share sheet on
/// phones and Windows, a download on the web. Linux has no share sheet for
/// files, so there it's saved to Downloads and a snackbar says where.
Future<void> shareGeneratedFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (!kIsWeb && Platform.isLinux) {
    final path = await _saveToDownloads(bytes, fileName);
    showAppSnackBar('Saved to $path');
    return;
  }
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
      fileNameOverrides: [fileName],
      downloadFallbackEnabled: true,
    ),
  );
}

/// Writes [bytes] into Downloads as [fileName], adding " (2)", " (3)", …
/// rather than overwriting an earlier file. Returns the path.
Future<String> _saveToDownloads(Uint8List bytes, String fileName) async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final dot = fileName.lastIndexOf('.');
  final stem = dot < 0 ? fileName : fileName.substring(0, dot);
  final extension = dot < 0 ? '' : fileName.substring(dot);

  var file = File('${directory.path}/$fileName');
  for (var copy = 2; file.existsSync(); copy++) {
    file = File('${directory.path}/$stem ($copy)$extension');
  }
  await file.writeAsBytes(bytes);
  return file.path;
}
