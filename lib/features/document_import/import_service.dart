import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import '../projects/project.dart';
import '../projects/project_repository.dart';

class ImportService {
  ImportService(this.repository);
  final ProjectRepository repository;

  Future<SourceAsset> importFile(String path, {int page = 1}) async {
    final original = File(path);
    if (await original.length() > 128 * 1024 * 1024) {
      throw const FormatException('Import limit is 128 MB per source file.');
    }
    final bytes = await original.readAsBytes();
    final ext = p.extension(path).toLowerCase();
    if (ext == '.doc' || ext == '.docx') {
      _validateWord(bytes, ext);
      return _convertWord(original);
    }
    if (bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-') {
      final target = await repository.assetFile('.pdf');
      await target.writeAsBytes(bytes, flush: true);
      try {
        return await pdfSource(target.path, p.basename(path), page);
      } catch (_) {
        await target.delete();
        rethrow;
      }
    }
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
      throw const FormatException(
        'Choose a JPG, PNG, WebP, PDF, DOC or DOCX file.',
      );
    }
    final info = await compute(inspectImage, bytes);
    final target = await repository.assetFile(ext);
    await target.writeAsBytes(bytes, flush: true);
    final thumb = '${target.path}.thumb.png';
    await File(thumb).writeAsBytes(info.$3, flush: true);
    return SourceAsset(
      path: target.path,
      name: p.basename(path),
      kind: 'image',
      width: info.$1,
      height: info.$2,
      thumbnail: thumb,
    );
  }

  Future<SourceAsset> pdfSource(String path, String name, int page) async {
    final doc = await PdfDocument.openFile(path);
    try {
      if (page < 1 || page > doc.pages.length) {
        throw const FormatException('Invalid PDF page.');
      }
      final pdfPage = doc.pages[page - 1];
      final ratio = math.min(
        1.0,
        480 / math.max(pdfPage.width, pdfPage.height),
      );
      final rendered = await pdfPage.render(
        fullWidth: pdfPage.width * ratio,
        fullHeight: pdfPage.height * ratio,
      );
      if (rendered == null) {
        throw const FormatException('PDF page could not be rendered.');
      }
      try {
        final png = await compute(bgraToPng, (
          rendered.width,
          rendered.height,
          Uint8List.fromList(rendered.pixels),
        ));
        final thumb = '$path.page$page.png';
        await File(thumb).writeAsBytes(png, flush: true);
        // Nominal 300 DPI metadata; PDF sources are rasterized on demand.
        return SourceAsset(
          path: path,
          name: name,
          kind: 'pdf',
          width: (pdfPage.width / 72 * 300).round(),
          height: (pdfPage.height / 72 * 300).round(),
          thumbnail: thumb,
          page: page,
          pageCount: doc.pages.length,
        );
      } finally {
        rendered.dispose();
      }
    } finally {
      await doc.dispose();
    }
  }

  void _validateWord(Uint8List bytes, String ext) {
    if (ext == '.doc') {
      if (bytes.length < 8 ||
          !listEquals(bytes.take(8).toList(), [
            0xd0,
            0xcf,
            0x11,
            0xe0,
            0xa1,
            0xb1,
            0x1a,
            0xe1,
          ])) {
        throw const FormatException('Invalid legacy Word file signature.');
      }
    } else {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      if (archive.findFile('word/document.xml') == null) {
        throw const FormatException('This is not a valid Word document.');
      }
    }
  }

  Future<SourceAsset> _convertWord(File source) async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      throw const FormatException(
        'Word import requires desktop LibreOffice. On mobile, save as PDF first.',
      );
    }
    final candidates = [
      if (Platform.isWindows) ...[
        r'C:\Program Files\LibreOffice\program\soffice.exe',
        r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
      ],
      if (Platform.isMacOS)
        '/Applications/LibreOffice.app/Contents/MacOS/soffice',
    ];
    String? executable;
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        executable = candidate;
        break;
      }
    }
    if (executable == null) {
      throw const FormatException(
        'Install LibreOffice to import Word documents, or convert to PDF first.',
      );
    }
    final staging = await Directory.systemTemp.createTemp('zslice-word-');
    try {
      final result = await Process.run(executable, [
        '-env:UserInstallation=${Directory(p.join(staging.path, 'profile')).uri}',
        '--headless',
        '--convert-to',
        'pdf',
        '--outdir',
        staging.path,
        source.path,
      ]).timeout(const Duration(minutes: 2));
      final converted = File(
        p.join(staging.path, '${p.basenameWithoutExtension(source.path)}.pdf'),
      );
      if (result.exitCode != 0 || !await converted.exists()) {
        throw const FormatException(
          'LibreOffice could not convert this document.',
        );
      }
      final asset = await importFile(converted.path);
      return asset.copyWith(name: p.basename(source.path));
    } finally {
      await staging.delete(recursive: true);
    }
  }
}

(int, int, Uint8List) inspectImage(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null) {
    throw const FormatException('Unsupported or damaged image data.');
  }
  if (info.width * info.height > 64000000) {
    throw const FormatException(
      'Image limit is 64 megapixels. Resize the source before importing.',
    );
  }
  final image = img.decodeImage(bytes);
  if (image == null) throw const FormatException('Image could not be decoded.');
  final upright = img.bakeOrientation(image);
  final thumb = img.copyResize(upright, width: math.min(480, upright.width));
  return (upright.width, upright.height, img.encodePng(thumb));
}

Uint8List bgraToPng((int, int, Uint8List) data) => img.encodePng(
  img.Image.fromBytes(
    width: data.$1,
    height: data.$2,
    bytes: data.$3.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  ),
);
