import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../models/file_filter.dart';

class FileService {
  /// List all files in [dirPath] that match [filter].
  /// If [dirPath] is empty or doesn't exist, returns empty list.
  Future<List<FileItem>> listFiles(String dirPath, FileFilter filter) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final items = <FileItem>[];
    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is! File) continue;
        final stat = entity.statSync();
        final name = p.basename(entity.path);
        final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
        if (ext.isEmpty) continue;

        final item = FileItem(
          path: entity.path,
          name: name,
          size: stat.size,
          modifiedAt: stat.modified,
          extension: ext,
        );
        if (_matchesFilter(item, filter)) {
          items.add(item);
        }
      }
    } catch (_) {
      // Permission denied or unmounted — return what we have
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  /// Aggregate all unique extensions from a directory (for filter chips).
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
