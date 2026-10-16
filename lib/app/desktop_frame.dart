import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../core/widgets/app_icons.dart';

bool get isDesktopPlatform =>
    !kIsWeb &&
    {
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform);

Future<void> prepareDesktopWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(400, 600),
      title: 'ZSlice by OnezPH',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    ),
  );
  await windowManager.maximize();
  await windowManager.show();
  await windowManager.focus();
}

class DesktopFrame extends StatelessWidget {
  const DesktopFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: DragToMoveArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/ZSlice Logo.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ZSlice',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ToolButton(
                  label: 'Minimize window',
                  icon: AppIcons.windowMinimize,
                  onPressed: windowManager.minimize,
                ),
                ToolButton(
                  label: 'Close window',
                  icon: AppIcons.windowClose,
                  onPressed: windowManager.close,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}
