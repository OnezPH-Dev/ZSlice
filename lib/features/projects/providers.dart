import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_repository.dart';
import 'project.dart';

final repositoryProvider = Provider<ProjectRepository>(
  (ref) => throw UnimplementedError('Override at startup.'),
);
final projectsProvider = StreamProvider<List<SliceProject>>(
  (ref) => ref.watch(repositoryProvider).watch(),
);
final projectProvider = FutureProvider.autoDispose
    .family<SliceProject?, String>(
      (ref, id) => ref.watch(repositoryProvider).get(id),
    );

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, Map<String, dynamic>>(
      PreferencesController.new,
    );

class PreferencesController extends AsyncNotifier<Map<String, dynamic>> {
  Future<void> _writes = Future.value();
  @override
  Future<Map<String, dynamic>> build() =>
      ref.watch(repositoryProvider).preference('app');
  Future<void> setValues(Map<String, dynamic> changes) async {
    final current = state.value ?? await future;
    final next = {...current, ...changes};
    state = AsyncData(next);
    final write = _writes.then(
      (_) => ref.read(repositoryProvider).setPreference('app', next),
    );
    _writes = write.catchError((Object error, StackTrace stack) {
      // Keep the queue usable; propagate this failure to the caller below.
    });
    await write;
  }
}
