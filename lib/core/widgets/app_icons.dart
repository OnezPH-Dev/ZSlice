import 'package:flutter/material.dart';
import 'package:flutter_solar_icons/bold_duotone/home.dart';
import 'package:flutter_solar_icons/bold_duotone/add_circle.dart';
import 'package:flutter_solar_icons/bold_duotone/upload.dart';
import 'package:flutter_solar_icons/bold_duotone/folder_open.dart';
import 'package:flutter_solar_icons/bold_duotone/document_text.dart';
import 'package:flutter_solar_icons/bold_duotone/settings.dart';
import 'package:flutter_solar_icons/bold_duotone/sun.dart';
import 'package:flutter_solar_icons/bold_duotone/moon.dart';
import 'package:flutter_solar_icons/bold_duotone/download.dart';
import 'package:flutter_solar_icons/bold_duotone/eye.dart';
import 'package:flutter_solar_icons/bold_duotone/diskette.dart';
import 'package:flutter_solar_icons/bold_duotone/undo_left.dart';
import 'package:flutter_solar_icons/bold_duotone/undo_right.dart';
import 'package:flutter_solar_icons/bold_duotone/widget.dart';
import 'package:flutter_solar_icons/bold_duotone/ruler.dart';
import 'package:flutter_solar_icons/bold_duotone/crop.dart';
import 'package:flutter_solar_icons/bold_duotone/cursor.dart';
import 'package:flutter_solar_icons/bold_duotone/scissors.dart';
import 'package:flutter_solar_icons/bold_duotone/copy.dart';
import 'package:flutter_solar_icons/bold_duotone/trash_bin_trash.dart';
import 'package:flutter_solar_icons/bold_duotone/pen.dart';
import 'package:flutter_solar_icons/bold_duotone/printer.dart';
import 'package:flutter_solar_icons/bold_duotone/close_circle.dart';
import 'package:flutter_solar_icons/bold_duotone/minus_circle.dart';
import 'package:flutter_solar_icons/bold_duotone/maximize.dart';
import 'package:flutter_solar_icons/bold_duotone/restart.dart';
import 'package:flutter_solar_icons/bold_duotone/arrow_left.dart';
import 'package:flutter_solar_icons/bold_duotone/arrow_right.dart';
import 'package:flutter_solar_icons/bold_duotone/layers.dart';
import 'package:flutter_solar_icons/bold_duotone/check_circle.dart';
import 'package:flutter_solar_icons/bold_duotone/alt_arrow_down.dart';
import 'package:flutter_solar_icons/bold_duotone/text_square.dart';
import 'package:flutter_solar_icons/bold_duotone/minus_square.dart';
import 'package:flutter_solar_icons/bold_duotone/maximize_square.dart';
import 'package:flutter_solar_icons/bold_duotone/minimize_square.dart';
import 'package:flutter_solar_icons/bold_duotone/close_square.dart';
import 'package:flutter_solar_icons/bold_duotone/align_horizontal_center.dart';

/// App-authored icons deliberately use only Solar's Bold Duotone payloads.
abstract final class AppIcons {
  static const align = AlignHorizontalCenterBoldDuotoneIcon();
  static const text = TextSquareBoldDuotoneIcon();
  static const windowMinimize = MinusSquareBoldDuotoneIcon();
  static const windowMaximize = MaximizeSquareBoldDuotoneIcon();
  static const windowRestore = MinimizeSquareBoldDuotoneIcon();
  static const windowClose = CloseSquareBoldDuotoneIcon();
  static const home = HomeBoldDuotoneIcon();
  static const add = AddCircleBoldDuotoneIcon();
  static const importFile = UploadBoldDuotoneIcon();
  static const open = FolderOpenBoldDuotoneIcon();
  static const document = DocumentTextBoldDuotoneIcon();
  static const settings = SettingsBoldDuotoneIcon();
  static const sun = SunBoldDuotoneIcon();
  static const moon = MoonBoldDuotoneIcon();
  static const export = DownloadBoldDuotoneIcon();
  static const preview = EyeBoldDuotoneIcon();
  static const save = DisketteBoldDuotoneIcon();
  static const undo = UndoLeftBoldDuotoneIcon();
  static const redo = UndoRightBoldDuotoneIcon();
  static const grid = WidgetBoldDuotoneIcon();
  static const ruler = RulerBoldDuotoneIcon();
  static const crop = CropBoldDuotoneIcon();
  static const select = CursorBoldDuotoneIcon();
  static const scissors = ScissorsBoldDuotoneIcon();
  static const copy = CopyBoldDuotoneIcon();
  static const delete = TrashBinTrashBoldDuotoneIcon();
  static const edit = PenBoldDuotoneIcon();
  static const print = PrinterBoldDuotoneIcon();
  static const close = CloseCircleBoldDuotoneIcon();
  static const minus = MinusCircleBoldDuotoneIcon();
  static const fit = MaximizeBoldDuotoneIcon();
  static const rotate = RestartBoldDuotoneIcon();
  static const back = ArrowLeftBoldDuotoneIcon();
  static const next = ArrowRightBoldDuotoneIcon();
  static const layers = LayersBoldDuotoneIcon();
  static const check = CheckCircleBoldDuotoneIcon();
  static const arrowDown = AltArrowDownBoldDuotoneIcon();
}

class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    isSelected: selected,
    style: IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      foregroundColor: selected ? Theme.of(context).colorScheme.primary : null,
    ),
    icon: icon,
  );
}
