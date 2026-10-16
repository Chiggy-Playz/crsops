import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/app_snack_bar.dart';

/// Hands a file the app made (an export, a challan PDF) to the user: a
/// download on the web, the share sheet on phones and Windows. Linux has no
/// share sheet for files, so there it's saved to Downloads and a snackbar
/// says where.
Future<void> shareGeneratedFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (kIsWeb) {
    // Always a download: browsers that support sharing files would
    // otherwise open their share dialog instead.
    final file = XFile.fromData(bytes, mimeType: mimeType, name: fileName);
    await file.saveTo(fileName);
    return;
  }
  if (Platform.isLinux) {
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

/// Like [shareGeneratedFile], but on phones the file opens in the device's
/// viewer (a PDF reader), which has its own share and print. The web and
/// Linux behave as in [shareGeneratedFile].
Future<void> openGeneratedFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (kIsWeb || Platform.isLinux) {
    await shareGeneratedFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    return;
  }
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  var opened = false;
  try {
    final result = await OpenFilex.open(file.path, type: mimeType);
    opened = result.type == ResultType.done;
  } on MissingPluginException {
    // Not built into this install yet; sharing below still works.
  }
  if (!opened) {
    // No viewer installed, or it refused: sharing still gets the file out.
    await shareGeneratedFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
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
