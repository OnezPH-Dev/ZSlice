import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';
import '../projects/project.dart';

class SourceLoader {
  /// Keep a single bounded source image resident, never a full poster bitmap.
  static Future<ui.Image> load(SourceAsset source) async {
    if (source.kind == 'pdf') {
      final document = await PdfDocument.openFile(source.path);
      try {
        final page = document.pages[source.page - 1];
        final scale = math.min(
          6000 / math.max(page.width, page.height),
          math.sqrt(24000000 / (page.width * page.height)),
        );
        final rendered = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (rendered == null) {
          throw const FormatException('Unable to render PDF page.');
        }
        try {
          return await rendered.createImage();
        } finally {
          rendered.dispose();
        }
      } finally {
        await document.dispose();
      }
    }
    final bytes = await File(source.path).readAsBytes();
    final scale = math.min(
      1.0,
      math.min(
        8192 / math.max(source.width, source.height),
        math.sqrt(24000000 / (source.width * source.height)),
      ),
    );
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: (source.width * scale).round(),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
