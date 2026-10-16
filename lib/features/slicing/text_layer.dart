import 'package:json_annotation/json_annotation.dart';
part 'text_layer.g.dart';

@JsonSerializable()
class TextLayer {
  const TextLayer({
    required this.id,
    this.text = 'Your text',
    this.x = 20,
    this.y = 20,
    this.width = 150,
    this.fontSize = 72,
    this.color = 0xff0f172a,
    this.bold = false,
    this.italic = false,
    this.align = 'left',
  });
  final String id, text, align;

  /// Position and wrapping width in physical poster millimetres; type in points.
  final double x, y, width, fontSize;
  final int color;
  final bool bold, italic;
  factory TextLayer.fromJson(Map<String, dynamic> json) =>
      _$TextLayerFromJson(json);
  Map<String, dynamic> toJson() => _$TextLayerToJson(this);
  TextLayer change(Map<String, dynamic> values) =>
      TextLayer.fromJson({...toJson(), ...values});
}
