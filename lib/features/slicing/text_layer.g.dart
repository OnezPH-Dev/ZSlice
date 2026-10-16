// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextLayer _$TextLayerFromJson(Map<String, dynamic> json) => TextLayer(
  id: json['id'] as String,
  text: json['text'] as String? ?? 'Your text',
  x: (json['x'] as num?)?.toDouble() ?? 20,
  y: (json['y'] as num?)?.toDouble() ?? 20,
  width: (json['width'] as num?)?.toDouble() ?? 150,
  fontSize: (json['fontSize'] as num?)?.toDouble() ?? 72,
  color: (json['color'] as num?)?.toInt() ?? 0xff0f172a,
  bold: json['bold'] as bool? ?? false,
  italic: json['italic'] as bool? ?? false,
  align: json['align'] as String? ?? 'left',
);

Map<String, dynamic> _$TextLayerToJson(TextLayer instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'align': instance.align,
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'fontSize': instance.fontSize,
  'color': instance.color,
  'bold': instance.bold,
  'italic': instance.italic,
};
