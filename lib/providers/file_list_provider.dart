import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../models/file_filter.dart';
import '../services/file_service.dart';

class FileListState {
  final String currentPath;
  final FileFilter filter;
  final List<FileItem> files;
  final Set<String> allExtensions;
  final bool isLoading;
  final String? error;

  const FileListState({
    this.currentPath = '',
    this.filter = FileFilter.empty,
    this.files = const [],
    this.allExtensions = const {},
    this.isLoading = false,
    this.error,
  });

  FileListState copyWith({
    String? currentPath,
    FileFilter? filter,
    List<FileItem>? files,
    Set<String>? allExtensions,
    bool? isLoading,
    String? error,
  }) =>
      FileListState(
        currentPath: currentPath ?? this.currentPath,
        filter: filter ?? this.filter,
        files: files ?? this.files,
        allExtensions: allExtensions ?? this.allExtensions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class FileListNotifier extends StateNotifier<FileListState> {
  final FileService _service;

  FileListNotifier(this._service) : super(const FileListState());

  Future<void> loadPath(String path) async {
    state = state.copyWith(currentPath: path, isLoading: true, error: null);
    try {
      final exts = await _service.aggregateExtensions(path);
      final files = await _service.listFiles(path, state.filter);
      state = state.copyWith(
        files: files,
        allExtensions: exts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
}

final fileServiceProvider = Provider((ref) => FileService());

final fileListProvider =
    StateNotifierProvider<FileListNotifier, FileListState>((ref) {
  return FileListNotifier(ref.read(fileServiceProvider));
});
