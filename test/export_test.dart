import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zslice/features/export/export_service.dart';
import 'package:zslice/features/editor/poster_renderer.dart';
import 'package:zslice/features/slicing/print_config.dart';
import 'package:zslice/features/slicing/slicing_plan.dart';
import 'package:zslice/features/slicing/text_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image image;
  const config = PrintConfig(
    rows: 2,
    columns: 2,
    paper: 'Custom',
    customWidth: 100,
    customHeight: 100,
    margins: false,
    lines: false,
    scissors: false,
    numbering: false,
  );
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (final (x, y, color) in [
      (0.0, 0.0, 0xffff0000),
      (100.0, 0.0, 0xff00ff00),
      (0.0, 100.0, 0xff0000ff),
      (100.0, 100.0, 0xffffff00),
    ]) {
      canvas.drawRect(
        ui.Rect.fromLTWH(x, y, 100, 100),
        ui.Paint()..color = ui.Color(color),
      );
    }
    final picture = recorder.endRecording();
    image = await picture.toImage(200, 200);
    picture.dispose();
  });
  tearDownAll(() => image.dispose());
  Future<File> generate(
    String format, {
    PrintConfig settings = config,
    ExportCancellation? token,
  }) async {
    final dir = await Directory(
      'build/verification/$format-${settings.lineStyle}',
    ).create(recursive: true);
    final oldStaging = Directory('${dir.path}/staging');
    if (await oldStaging.exists()) await oldStaging.delete(recursive: true);
    return ExportService().export(
      plan: SlicingPlan.create(settings),
      image: image,
      format: format,
      dpi: 36,
      directory: dir,
      cancellation: token ?? ExportCancellation(),
      progress: (_, _) {},
    );
  }

  test('PNG ZIP contains every correctly cropped page', () async {
    final output = await generate('png');
    final archive = ZipDecoder().decodeBytes(
      await output.readAsBytes(),
      verify: true,
    );
    expect(archive.files.length, 4);
    final expected = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)];
    for (var i = 0; i < 4; i++) {
      final entry = archive.findFile(
        'Page_${(i + 1).toString().padLeft(3, '0')}.png',
      )!;
      final raster = img.decodePng(entry.content)!;
      expect(raster.width, 142);
      expect(raster.height, 142);
      final pixel = raster.getPixel(70, 70);
      expect((pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()), expected[i]);
    }
  });
  test('JPEG ZIP has correctly encoded pages', () async {
    final archive = ZipDecoder().decodeBytes(
      await (await generate('jpeg')).readAsBytes(),
    );
    expect(archive.files.length, 4);
    expect(img.decodeJpg(archive.findFile('Page_001.jpg')!.content), isNotNull);
  });
  for (final rotation in [0, 1]) {
    test(
      'independent image dimensions render in sheet export at rotation $rotation',
      () async {
        final output = await generate(
          'png',
          settings: config.change({
            'stretchX': 0.5,
            'stretchY': 0.75,
            'rotation': rotation,
          }),
        );
        final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
        final raster = img.decodePng(
          archive.findFile('Page_001.png')!.content,
        )!;
        final border = raster.getPixel(10, 70);
        expect(
          (border.r.toInt(), border.g.toInt(), border.b.toInt()),
          (255, 255, 255),
        );
        final content = raster.getPixel(110, 70);
        expect((
          content.r.toInt(),
          content.g.toInt(),
          content.b.toInt(),
        ), rotation == 0 ? (255, 0, 0) : (0, 0, 255));
      },
    );
  }
  test('streamed PDF has four page objects and valid xref offsets', () async {
    final output = await generate('pdf');
    final bytes = await output.readAsBytes();
    final text = latin1.decode(bytes);
    expect(text.startsWith('%PDF-1.4'), isTrue);
    expect(RegExp(r'/Type /Page ').allMatches(text).length, 4);
    expect(
      text,
      contains('/MediaBox [0 0 283.46456692913387 283.46456692913387]'),
    );
    final start = int.parse(
      RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!,
    );
    expect(text.substring(start).startsWith('xref'), isTrue);
    final xref = text.substring(start).split('\n');
    for (var id = 1; id < 15; id++) {
      final offset = int.parse(xref[2 + id].substring(0, 10));
      expect(text.substring(offset).startsWith('$id 0 obj'), isTrue);
    }
  });
  test(
    'DOCX contains OOXML relationships, page sizes, and page images',
    () async {
      final output = await generate('docx');
      final archive = ZipDecoder().decodeBytes(
        await output.readAsBytes(),
        verify: true,
      );
      expect(archive.findFile('[Content_Types].xml'), isNotNull);
      expect(archive.findFile('_rels/.rels'), isNotNull);
      final doc = utf8.decode(archive.findFile('word/document.xml')!.content);
      expect(doc, contains('<w:pgSz w:w="5669" w:h="5669"/>'));
      expect(RegExp('<w:drawing>').allMatches(doc).length, 4);
      expect(RegExp('<w:br w:type="page"/>').allMatches(doc).length, 3);
      for (var i = 1; i <= 4; i++) {
        expect(
          img.decodePng(archive.findFile('word/media/page$i.png')!.content),
          isNotNull,
        );
      }
    },
  );
  test('cancelled export leaves no output or staging pages', () async {
    final token = ExportCancellation()..cancelled = true;
    await expectLater(
      generate('png', token: token),
      throwsA(isA<ExportCancelled>()),
    );
    expect(
      await File('build/verification/png-dashed/output.zip').exists(),
      isFalse,
    );
    expect(
      await Directory('build/verification/png-dashed/staging').exists(),
      isFalse,
    );
  });
  test('mid-export cancellation removes partial PDF', () async {
    final dir = await Directory(
      'build/verification/cancel',
    ).create(recursive: true);
    final token = ExportCancellation();
    await expectLater(
      ExportService().export(
        plan: SlicingPlan.create(config),
        image: image,
        format: 'pdf',
        dpi: 36,
        directory: dir,
        cancellation: token,
        progress: (done, _) {
          if (done == 1) token.cancelled = true;
        },
      ),
      throwsA(isA<ExportCancelled>()),
    );
    expect(await File('${dir.path}/output.pdf').exists(), isFalse);
  });
  test('400-sheet PDF streams every page with monotonic progress', () async {
    final dir = await Directory(
      'build/verification/400-sheets',
    ).create(recursive: true);
    final large = config.change({
      'rows': 20,
      'columns': 20,
      'customWidth': 25.4,
      'customHeight': 25.4,
    });
    var last = 0;
    final output = await ExportService().export(
      plan: SlicingPlan.create(large),
      image: image,
      format: 'pdf',
      dpi: 36,
      directory: dir,
      cancellation: ExportCancellation(),
      progress: (done, total) {
        expect(total, 400);
        expect(done, last + 1);
        last = done;
      },
    );
    expect(last, 400);
    final text = latin1.decode(await output.readAsBytes());
    expect(RegExp(r'/Type /Page ').allMatches(text).length, 400);
    expect(await Directory('${dir.path}/staging').exists(), isFalse);
  });
  test('oversized raster fails before allocating a bitmap', () async {
    final dir = await Directory(
      'build/verification/oversized',
    ).create(recursive: true);
    await expectLater(
      ExportService().export(
        plan: SlicingPlan.create(config.change({'customWidth': 200.0})),
        image: image,
        format: 'pdf',
        dpi: 1200,
        directory: dir,
        cancellation: ExportCancellation(),
        progress: (_, _) {},
      ),
      throwsFormatException,
    );
  });
  test(
    'subpixel paper fails with a helpful error before raster allocation',
    () async {
      final dir = await Directory(
        'build/verification/subpixel',
      ).create(recursive: true);
      await expectLater(
        ExportService().export(
          plan: SlicingPlan.create(
            config.change({'customWidth': 0.1, 'customHeight': 0.1}),
          ),
          image: image,
          format: 'pdf',
          dpi: 36,
          directory: dir,
          cancellation: ExportCancellation(),
          progress: (_, _) {},
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('too small'),
          ),
        ),
      );
    },
  );
  for (final style in ['solid', 'dashed', 'dotted', 'dashDot', 'corners']) {
    test('$style guide rendering and scissors change output', () async {
      final output = await generate(
        'png',
        settings: config.change({
          'lines': true,
          'scissors': true,
          'lineStyle': style,
          'numbering': true,
        }),
      );
      final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
      final raster = img.decodePng(archive.findFile('Page_001.png')!.content)!;
      // Trim marks and labels must actually alter pixels of the red source.
      expect(raster.getPixel(141, 70).r.toInt(), lessThan(255));
    });
  }
  test('preview/export visibility are independent', () async {
    final p = SlicingPlan.create(
      config.change({
        'lines': true,
        'scissors': true,
        'exportGuides': false,
        'previewGuides': true,
      }),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    PosterRenderer.sheet(canvas, p, p.tiles.first, image, exporting: true);
    final picture = recorder.endRecording();
    final raster = await picture.toImage(100, 100);
    picture.dispose();
    final data = (await raster.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    raster.dispose();
    expect(data.getUint8((50 * 100 + 80) * 4), 255);
  });
  test(
    'text-only PNG, PDF and DOCX contain rendered text and no source image is required',
    () async {
      final c = config.change({
        'rows': 1,
        'columns': 1,
        'texts': [
          const TextLayer(
            id: 'title',
            text: 'ZSLICE',
            x: 10,
            y: 10,
            width: 80,
            fontSize: 48,
            bold: true,
          ).toJson(),
        ],
      });
      for (final format in ['png', 'pdf', 'docx']) {
        final directory = await Directory(
          'build/verification/text-only-$format',
        ).create(recursive: true);
        final output = await ExportService().export(
          plan: SlicingPlan.create(c),
          image: null,
          format: format,
          dpi: 72,
          directory: directory,
          cancellation: ExportCancellation(),
          progress: (_, _) {},
        );
        expect(await output.length(), greaterThan(500));
        if (format == 'png') {
          final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
          final raster = img.decodePng(
            archive.findFile('Page_001.png')!.content,
          )!;
          var ink = 0;
          for (final pixel in raster) {
            if (pixel.r < 180) ink++;
          }
          expect(ink, greaterThan(200));
        }
      }
    },
  );
}
