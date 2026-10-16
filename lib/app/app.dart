import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/projects/providers.dart';
import '../features/settings/settings_screen.dart';
import 'theme/app_theme.dart';
import 'desktop_frame.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (_, _, child) => DesktopFrame(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: '/editor/:id',
            builder: (_, state) => EditorScreen(
              id: state.pathParameters['id']!,
              exportOnLoad: state.uri.queryParameters['export'] == '1',
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class ZSliceApp extends ConsumerWidget {
  const ZSliceApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(preferencesProvider).value?['theme'];
    return MaterialApp.router(
      title: 'ZSlice by OnezPH',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: mode == 'light'
          ? ThemeMode.light
          : mode == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
