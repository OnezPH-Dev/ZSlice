import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Bounded-memory PDF writer: streams one JPEG page at a time to disk. Object
/// offsets are the only data retained for already-written pages.
class PdfStreamWriter {
  PdfStreamWriter(File file, this.count, this.widthPt, this.heightPt)
    : _sink = file.openWrite() {
    _text('%PDF-1.4\n%ZSlice\n');
    _object(1, '<< /Type /Catalog /Pages 2 0 R >>');
    _object(
      2,
      '<< /Type /Pages /Count $count /Kids [${List.generate(count, (i) => '${3 + i * 3} 0 R').join(' ')}] >>',
    );
  }
  final IOSink _sink;
  final int count;
  final double widthPt, heightPt;
  final Map<int, int> _offsets = {};
  int _position = 0;
  void _bytes(List<int> bytes) {
    _sink.add(bytes);
    _position += bytes.length;
  }

  void _text(String text) => _bytes(latin1.encode(text));
  void _object(int id, String body) {
    _offsets[id] = _position;
    _text('$id 0 obj\n$body\nendobj\n');
  }

  Future<void> addPage(int index, Uint8List jpeg, int width, int height) async {
    final id = 3 + index * 3;
    _object(
      id,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $widthPt $heightPt] '
      '/Resources << /XObject << /Im0 ${id + 1} 0 R >> >> /Contents ${id + 2} 0 R >>',
    );
    _offsets[id + 1] = _position;
    _text(
      '${id + 1} 0 obj\n<< /Type /XObject /Subtype /Image /Width $width /Height $height '
      '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n',
    );
    _bytes(jpeg);
    _text('\nendstream\nendobj\n');
    final commands = 'q $widthPt 0 0 $heightPt 0 0 cm /Im0 Do Q\n';
    _object(
      id + 2,
      '<< /Length ${latin1.encode(commands).length} >>\nstream\n${commands}endstream',
    );
    await _sink.flush();
  }

  Future<void> close({bool complete = true}) async {
    if (complete) {
      final start = _position;
      final size = 3 + count * 3;
      _text('xref\n0 $size\n0000000000 65535 f \n');
      for (var i = 1; i < size; i++) {
        _text('${_offsets[i]!.toString().padLeft(10, '0')} 00000 n \n');
      }
      _text(
        'trailer\n<< /Size $size /Root 1 0 R >>\nstartxref\n$start\n%%EOF\n',
      );
    }
    await _sink.close();
  }
}
