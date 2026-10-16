import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

Future<bool> saveOutput(File source, String suggestedName, String mime) async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final destination = await getSaveLocation(suggestedName: suggestedName);
    if (destination == null) return false;
    final target = File(destination.path);
    // Copy to a sibling staging file, then atomically replace at finalization.
    final staging = File(
      p.join(
        p.dirname(target.path),
        '.${p.basename(target.path)}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    try {
      await source.copy(staging.path);
      await staging.rename(target.path);
    } finally {
      if (await staging.exists()) await staging.delete();
    }
    return true;
  }
  if (await source.length() > 128 * 1024 * 1024) {
    throw const FormatException(
      'Mobile saving supports up to 128 MB. Reduce DPI or export on desktop.',
    );
  }
  return await FilePicker.saveFile(
        fileName: suggestedName,
        bytes: await source.readAsBytes(),
        mimeType: mime,
      ) !=
      null;
}
