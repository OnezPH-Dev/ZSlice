import 'package:json_annotation/json_annotation.dart';
import 'text_layer.dart';

part 'print_config.g.dart';

const paperSizes = <String, (double, double)>{
  'Short Bond': (215.9, 279.4),
  'Long Bond': (215.9, 330.2),
  'Legal': (215.9, 355.6),
  'A4': (210, 297),
  'A3': (297, 420),
  'A5': (148, 210),
  'Tabloid': (279.4, 431.8),
};

@JsonSerializable(explicitToJson: true)
class PrintConfig {
  const PrintConfig({
    this.rows = 3,
    this.columns = 3,
    this.layout = 'grid',
    this.posterWidth = 600,
    this.posterHeight = 800,
    this.paper = 'Short Bond',
    this.customWidth = 215.9,
    this.customHeight = 279.4,
    this.landscape = false,
    this.margins = true,
    this.linkMargins = true,
    this.top = 6.35,
    this.right = 6.35,
    this.bottom = 6.35,
    this.left = 6.35,
    this.overlapEnabled = false,
    this.overlap = 6.35,
    this.showOverlap = true,
    this.lines = true,
    this.lineStyle = 'dashed',
    this.lineWidth = 0.5,
    this.guideColor = 0xff64748b,
    this.previewGuides = true,
    this.exportGuides = true,
    this.scissors = true,
    this.scissorsPlacement = 'selected',
    this.scissorsSize = 1,
    this.scissorsColor = 0xff64748b,
    this.cutTop = false,
    this.cutRight = true,
    this.cutBottom = true,
    this.cutLeft = false,
    this.numbering = true,
    this.numberStyle = 'page',
    this.numberPosition = 'bottomCenter',
    this.numberSize = 10,
    this.numberColor = 0xff0f172a,
    this.order = 'row',
    this.autoDpi = true,
    this.dpi = 300,
    this.grid = true,
    this.rulers = true,
    this.boundaries = true,
    this.scale = 1,
    this.stretchX = 1,
    this.stretchY = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.rotation = 0,
    this.cropLeft = 0,
    this.cropTop = 0,
    this.cropRight = 1,
    this.cropBottom = 1,
    this.texts = const [],
    this.snap = true,
  });

  final int rows, columns;
  final String layout, paper;
  final double posterWidth, posterHeight, customWidth, customHeight;
  final bool landscape, margins, linkMargins;
  final double top, right, bottom, left;
  final bool overlapEnabled, showOverlap;
  final double overlap;
  final bool lines, previewGuides, exportGuides, scissors;
  final String scissorsPlacement;
  final double scissorsSize;
  final int scissorsColor;
  final String lineStyle;
  final double lineWidth;
  final int guideColor;
  final bool cutTop, cutRight, cutBottom, cutLeft, numbering;
  final String numberStyle, numberPosition, order;
  final double numberSize;
  final int numberColor;
  final bool autoDpi;
  final int dpi;
  final bool grid, rulers, boundaries;
  final double scale, stretchX, stretchY, offsetX, offsetY;
  final int rotation;
  final double cropLeft, cropTop, cropRight, cropBottom;
  final List<TextLayer> texts;
  final bool snap;

  (double, double) get paperSize {
    final size = paperSizes[paper] ?? (customWidth, customHeight);
    return landscape ? (size.$2, size.$1) : size;
  }

  PrintConfig change(Map<String, dynamic> values) =>
      PrintConfig.fromJson({...toJson(), ...values});
  factory PrintConfig.fromJson(Map<String, dynamic> json) =>
      _$PrintConfigFromJson(json);
  Map<String, dynamic> toJson() => _$PrintConfigToJson(this);
}
