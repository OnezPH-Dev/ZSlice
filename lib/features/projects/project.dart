import 'package:freezed_annotation/freezed_annotation.dart';
import '../slicing/print_config.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class SourceAsset with _$SourceAsset {
  const factory SourceAsset({
    required String path,
    required String name,
    required String kind,
    required int width,
    required int height,
    required String thumbnail,
    @Default(1) int page,
    @Default(1) int pageCount,
  }) = _SourceAsset;
  factory SourceAsset.fromJson(Map<String, dynamic> json) =>
      _$SourceAssetFromJson(json);
}

@JsonSerializable(explicitToJson: true)
class SliceProject {
  const SliceProject({
    required this.id,
    required this.name,
    required this.modified,
    this.version = 1,
    this.source,
    this.config = const PrintConfig(),
  });
  final String id, name;
  final DateTime modified;
  final int version;
  final SourceAsset? source;
  final PrintConfig config;

  SliceProject copy({
    String? id,
    String? name,
    SourceAsset? source,
    PrintConfig? config,
    bool removeSource = false,
  }) => SliceProject(
    id: id ?? this.id,
    name: name ?? this.name,
    source: removeSource ? null : source ?? this.source,
    modified: DateTime.now(),
    config: config ?? this.config,
  );
  factory SliceProject.fromJson(Map<String, dynamic> json) {
    if ((json['version'] ?? 1) != 1) {
      throw const FormatException('Unsupported project version.');
    }
    return _$SliceProjectFromJson(json);
  }
  Map<String, dynamic> toJson() => _$SliceProjectToJson(this);
}
