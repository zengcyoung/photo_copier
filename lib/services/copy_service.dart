import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../models/copy_session.dart';
import 'history_service.dart';

enum ConflictChoice { overwrite, skip }

class ConflictInfo {
  final FileItem source;
  final FileStat dest;
  final String destPath;

  const ConflictInfo({
    required this.source,
    required this.dest,
    required this.destPath,
  });
}

sealed class CopyEvent {}

class CopyProgress extends CopyEvent {
  final int current;
  final int total;
  final String fileName;

  CopyProgress(
      {required this.current, required this.total, required this.fileName});
}

class CopyConflict extends CopyEvent {
  final ConflictInfo info;
  final Completer<ConflictChoice> completer;

  CopyConflict({required this.info, required this.completer});
}

class CopyDone extends CopyEvent {
  final int succeeded;
  final int skipped;
  final int failed;

  CopyDone(
      {required this.succeeded, required this.skipped, required this.failed});
}

class CopyInterrupted extends CopyEvent {
  final List<FileItem> remaining;
  final String error;

  CopyInterrupted({required this.remaining, required this.error});
}

class CopyService {
  final HistoryService _history;

  CopyService(this._history);

  Stream<CopyEvent> copyFiles({
    required CopySession session,
    required List<FileItem> files,
    required String destDir,
    ConflictChoice? defaultConflict,
  }) async* {
    int succeeded = 0;
    int skipped = 0;
    int failed = 0;
    ConflictChoice? globalConflict = defaultConflict;

    final updatedFiles = List<CopySessionFile>.from(session.files);

    // Write pending list
    await _history.savePending(
        session.id, files.map((f) => f.path).toList());

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      yield CopyProgress(
          current: i + 1, total: files.length, fileName: file.name);

      final destPath = p.join(destDir, file.name);
      final destFile = File(destPath);

      try {
        // Check source still accessible
        final srcFile = File(file.path);
        if (!srcFile.existsSync()) {
          // External storage disconnected
          final remaining = files.sublist(i);
          await _history.savePending(
              session.id, remaining.map((f) => f.path).toList());
          yield CopyInterrupted(
              remaining: remaining,
              error: 'Source file not accessible: ${file.name}');
          return;
        }

        // Conflict check
        if (destFile.existsSync()) {
          ConflictChoice choice;
          if (globalConflict != null) {
            choice = globalConflict;
          } else {
            final destStat = destFile.statSync();
            final completer = Completer<ConflictChoice>();
            yield CopyConflict(
              info: ConflictInfo(
                  source: file, dest: destStat, destPath: destPath),
              completer: completer,
            );
            final result = await completer.future;
            if (result == ConflictChoice.skip) {
              // Check if user set "apply to all"
              choice = result;
            } else {
              choice = result;
            }
          }

          if (choice == ConflictChoice.skip) {
            skipped++;
            _updateFile(updatedFiles, file,
                CopyFileStatus.skipped, destPath, null);
            continue;
          }
          // overwrite: proceed to copy
        }

        // Actual copy
        await srcFile.copy(destPath);
        succeeded++;
        _updateFile(updatedFiles, file, CopyFileStatus.success, destPath, null);

        // Remove from pending
        final remaining =
            files.sublist(i + 1).map((f) => f.path).toList();
        await _history.savePending(session.id, remaining);
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 113 || // No route to host
            e.osError?.errorCode == 5 || // I/O error
            e.osError?.errorCode == 6 // No such device or address
            ) {
          final remaining = files.sublist(i);
          await _history.savePending(
              session.id, remaining.map((f) => f.path).toList());
          yield CopyInterrupted(
              remaining: remaining, error: 'Storage disconnected: ${e.message}');
          return;
        }
        failed++;
        _updateFile(updatedFiles, file, CopyFileStatus.failed, destPath,
            e.message);
      } catch (e) {
        failed++;
        _updateFile(updatedFiles, file, CopyFileStatus.failed, destPath,
            e.toString());
      }
    }

    final done = session.copyWith(
      status: CopySessionStatus.completed,
      files: updatedFiles,
      finishedAt: DateTime.now(),
    );
    await _history.saveSession(done);
    await _history.clearPending();
    yield CopyDone(
        succeeded: succeeded, skipped: skipped, failed: failed);
  }

  void _updateFile(
    List<CopySessionFile> list,
    FileItem item,
    CopyFileStatus status,
    String destPath,
    String? error,
  ) {
    final idx = list.indexWhere((f) => f.sourcePath == item.path);
    if (idx >= 0) {
      list[idx] = CopySessionFile(
        sourcePath: item.path,
        destPath: destPath,
        name: item.name,
        size: item.size,
        status: status,
        error: error,
      );
    }
  }
}
