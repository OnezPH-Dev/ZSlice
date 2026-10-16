import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import '../editor/poster_renderer.dart';
import '../slicing/slicing_plan.dart';
import 'pdf_stream_writer.dart';

class ExportCancelled implements Exception {}

class ExportCancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw ExportCancelled();
  }
}

class ExportService {
  Future<File> export({
    required SlicingPlan plan,
    required ui.Image? image,
    required String format,
    required int dpi,
    required Directory directory,
    required ExportCancellation cancellation,
    required void Function(int, int) progress,
  }) async {
    final (pw, ph) = plan.config.paperSize;
    if (!{'pdf', 'png', 'jpeg', 'docx'}.contains(format) ||
        dpi < 36 ||
        dpi > 1200) {
      throw const FormatException('Unsupported export format or DPI.');
    }
    final width = (pw / 25.4 * dpi).round();
    final height = (ph / 25.4 * dpi).round();
    if (width < 1 || height < 1) {
      throw const FormatException(
        'This paper is too small at the selected DPI. Increase paper size or DPI.',
      );
    }
    if (width * height > 24000000) {
      throw const FormatException(
        'This sheet exceeds the 24 megapixel memory limit. Reduce paper size or DPI.',
      );
    }
    final staging = await Directory(p.join(directory.path, 'staging')).create();
    final output = File(
      p.join(
        directory.path,
        'output.${format == 'pdf'
            ? 'pdf'
            : format == 'docx'
            ? 'docx'
            : 'zip'}',
      ),
    );
    PdfStreamWriter? pdf;
    ZipFileEncoder? zip;
    var closed = false;
    try {
      cancellation.check();
      if (format == 'pdf') {
        final pageFormat = PdfPageFormat(
          pw * PdfPageFormat.mm,
          ph * PdfPageFormat.mm,
        );
        pdf = PdfStreamWriter(
          output,
          plan.tiles.length,
          pageFormat.width,
          pageFormat.height,
        );
      } else {
        zip = ZipFileEncoder()..create(output.path);
      }
      for (final tile in plan.tiles) {
        cancellation.check();
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(width / pw, height / ph);
        PosterRenderer.sheet(canvas, plan, tile, image, exporting: true);
        final picture = recorder.endRecording();
        final raster = await picture.toImage(width, height);
        picture.dispose();
        Uint8List png;
        try {
          png = (await raster.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
        } finally {
          raster.dispose();
        }
        cancellation.check();
        final jpeg = format == 'pdf' || format == 'jpeg';
        final data = jpeg ? await compute(pngToJpeg, png) : png;
        if (pdf != null) {
          await pdf.addPage(tile.index, data, width, height);
        } else {
          final name = format == 'docx'
              ? 'word/media/page${tile.index + 1}.png'
              : 'Page_${(tile.index + 1).toString().padLeft(3, '0')}.${jpeg ? 'jpg' : 'png'}';
          final file = File(
            p.join(staging.path, 'page.${jpeg ? 'jpg' : 'png'}'),
          );
          await file.writeAsBytes(data, flush: true);
          await zip!.addFile(file, name);
          await file.delete();
        }
        progress(tile.index + 1, plan.tiles.length);
        await Future<void>.delayed(Duration.zero);
      }
      cancellation.check();
      if (format == 'docx') {
        for (final entry in docxParts(plan).entries) {
          zip!.addArchiveFile(ArchiveFile.string(entry.key, entry.value));
        }
      }
      if (pdf != null) await pdf.close();
      if (zip != null) await zip.close();
      closed = true;
      cancellation.check();
      return output;
    } catch (_) {
      if (!closed) {
        if (pdf != null) await pdf.close(complete: false);
        if (zip != null) await zip.close();
      }
      if (await output.exists()) await output.delete();
      rethrow;
    } finally {
      await staging.delete(recursive: true);
    }
  }
}

Uint8List pngToJpeg(Uint8List png) =>
    img.encodeJpg(img.decodePng(png)!, quality: 95);

Map<String, String> docxParts(SlicingPlan plan) {
  final (pw, ph) = plan.config.paperSize;
  final w = (pw / 25.4 * 1440).round(), h = (ph / 25.4 * 1440).round();
  // A tiny content inset prevents Word from overflowing the mandatory final
  // paragraph onto a blank page. The image retains exact physical page size.
  final cx = (pw * 36000).round(), cy = (ph * 36000).round();
  final body = StringBuffer();
  for (var i = 1; i <= plan.tiles.length; i++) {
    body.write(
      '''<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="1" w:lineRule="exact"/></w:pPr><w:r><w:drawing>
<wp:anchor distT="0" distB="0" distL="0" distR="0" simplePos="0" relativeHeight="0" behindDoc="0" locked="0" layoutInCell="1" allowOverlap="1">
<wp:simplePos x="0" y="0"/><wp:positionH relativeFrom="page"><wp:posOffset>0</wp:posOffset></wp:positionH><wp:positionV relativeFrom="page"><wp:posOffset>0</wp:posOffset></wp:positionV>
<wp:extent cx="$cx" cy="$cy"/><wp:wrapNone/><wp:docPr id="$i" name="Page $i"/>
<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic>
<pic:nvPicPr><pic:cNvPr id="$i" name="page$i.png"/><pic:cNvPicPr/></pic:nvPicPr>
<pic:blipFill><a:blip r:embed="rId$i"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
</pic:pic></a:graphicData></a:graphic></wp:anchor></w:drawing></w:r></w:p>''',
    );
    if (i < plan.tiles.length) {
      body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
    }
  }
  return {
    '[Content_Types].xml':
        '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''',
    '_rels/.rels':
        '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''',
    'word/_rels/document.xml.rels':
        '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${List.generate(plan.tiles.length, (i) => '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/page${i + 1}.png"/>').join()}</Relationships>''',
    'word/document.xml':
        '''<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>$body<w:sectPr><w:pgSz w:w="$w" w:h="$h"/><w:pgMar w:top="0" w:right="0" w:bottom="0" w:left="0" w:header="0" w:footer="0" w:gutter="0"/></w:sectPr></w:body></w:document>''',
  };
}
