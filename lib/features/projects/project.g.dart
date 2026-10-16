// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SliceProject _$SliceProjectFromJson(Map<String, dynamic> json) => SliceProject(
  id: json['id'] as String,
  name: json['name'] as String,
  modified: DateTime.parse(json['modified'] as String),
  version: (json['version'] as num?)?.toInt() ?? 1,
  source: json['source'] == null
      ? null
      : SourceAsset.fromJson(json['source'] as Map<String, dynamic>),
  config: json['config'] == null
      ? const PrintConfig()
      : PrintConfig.fromJson(json['config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SliceProjectToJson(SliceProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'modified': instance.modified.toIso8601String(),
      'version': instance.version,
      'source': instance.source?.toJson(),
      'config': instance.config.toJson(),
    };

_SourceAsset _$SourceAssetFromJson(Map<String, dynamic> json) => _SourceAsset(
  path: json['path'] as String,
  name: json['name'] as String,
  kind: json['kind'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  thumbnail: json['thumbnail'] as String,
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageCount: (json['pageCount'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$SourceAssetToJson(_SourceAsset instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'kind': instance.kind,
      'width': instance.width,
      'height': instance.height,
      'thumbnail': instance.thumbnail,
      'page': instance.page,
      'pageCount': instance.pageCount,
    };
