import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../models/file_filter.dart';
import '../services/file_service.dart';

class FileListState {
  final String currentPath;
  final List<String> pathStack; // navigation history for back button
  final FileFilter filter;
  final List<FileItem> files;
  final Set<String> allExtensions;
  final bool isLoading;
  final String? error;

  const FileListState({
    this.currentPath = '',
    this.pathStack = const [],
    this.filter = FileFilter.empty,
    this.files = const [],
    this.allExtensions = FileItem.knownExtensions,
    this.isLoading = false,
    this.error,
  });

  FileListState copyWith({
    String? currentPath,
    List<String>? pathStack,
    FileFilter? filter,
    List<FileItem>? files,
    Set<String>? allExtensions,
    bool? isLoading,
    String? error,
  }) =>
      FileListState(
        currentPath: currentPath ?? this.currentPath,
        pathStack: pathStack ?? this.pathStack,
        filter: filter ?? this.filter,
        files: files ?? this.files,
        allExtensions: allExtensions ?? this.allExtensions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get canGoUp => pathStack.isNotEmpty;
}

class FileListNotifier extends StateNotifier<FileListState> {
  final FileService _service;

  FileListNotifier(this._service) : super(const FileListState());

  Future<void> loadPath(String path, {bool pushHistory = false}) async {
    final newStack = pushHistory
        ? [...state.pathStack, state.currentPath]
        : state.pathStack;
    state = state.copyWith(
        currentPath: path,
        pathStack: newStack,
        isLoading: true,
        error: null);
    try {
      final files = await _service.listFiles(path, state.filter);
      state = state.copyWith(
        files: files,
        allExtensions: FileItem.knownExtensions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> navigateInto(String dirPath) =>
      loadPath(dirPath, pushHistory: true);

  Future<void> navigateUp() async {
    if (!state.canGoUp) return;
    final stack = List<String>.from(state.pathStack);
    final parent = stack.removeLast();
    state = state.copyWith(pathStack: stack);
    await loadPath(parent);
  }

  Future<void> applyFilter(FileFilter filter) async {
    state = state.copyWith(filter: filter, isLoading: true, error: null);
    try {
      final files = await _service.listFiles(state.currentPath, filter);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadPath(state.currentPath);

  Future<int> deleteFiles(List<String> paths) async {
    final deleted = _service.deleteFiles(paths);
    await refresh();
    return deleted;
  }
}

final fileServiceProvider = Provider((ref) => FileService());

final fileListProvider =
    StateNotifierProvider<FileListNotifier, FileListState>((ref) {
  return FileListNotifier(ref.read(fileServiceProvider));
});
