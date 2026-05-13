import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../models/file_filter.dart';

class FileService {
  /// List directories and files in [dirPath]. Directories are always shown
  /// first; filters apply only to files.
  Future<List<FileItem>> listFiles(String dirPath, FileFilter filter) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final dirs = <FileItem>[];
    final files = <FileItem>[];
    try {
      await for (final entity in dir.list(recursive: false)) {
        final stat = entity.statSync();
        final name = p.basename(entity.path);
        // Skip hidden entries
        if (name.startsWith('.')) continue;

        if (entity is Directory) {
          dirs.add(FileItem(
            path: entity.path,
            name: name,
            size: 0,
            modifiedAt: stat.modified,
            extension: '',
            isDirectory: true,
          ));
        } else if (entity is File) {
          final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
          if (ext.isEmpty) continue;
          final item = FileItem(
            path: entity.path,
            name: name,
            size: stat.size,
            modifiedAt: stat.modified,
            extension: ext,
          );
          if (_matchesFilter(item, filter)) files.add(item);
        }
      }
    } catch (_) {
      // Permission denied or unmounted — return what we have
    }

    dirs.sort((a, b) => a.name.compareTo(b.name));
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return [...dirs, ...files];
  }

  /// Aggregate all unique extensions from files in a directory (for filter chips).
  Future<Set<String>> aggregateExtensions(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return {};
    final exts = <String>{};
    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is! File) continue;
        final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (ext.isNotEmpty) exts.add(ext);
      }
    } catch (_) {}
    return exts;
  }

  bool _matchesFilter(FileItem item, FileFilter filter) {
    if (filter.dateFrom != null &&
        item.modifiedAt.isBefore(filter.dateFrom!)) {
      return false;
    }
    if (filter.dateTo != null &&
        item.modifiedAt.isAfter(filter.dateTo!)) {
      return false;
    }
    if (filter.extensions.isNotEmpty &&
        !filter.extensions.contains(item.extension)) {
      return false;
    }
    if (filter.minSizeMiB != null &&
        item.sizeMiB < filter.minSizeMiB!) {
      return false;
    }
    return true;
  }
}
