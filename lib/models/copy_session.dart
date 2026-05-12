enum CopySessionStatus { pending, running, completed, interrupted }

class CopySessionFile {
  final String sourcePath;
  final String destPath;
  final String name;
  final int size;
  final CopyFileStatus status;
  final String? error;

  const CopySessionFile({
    required this.sourcePath,
    required this.destPath,
    required this.name,
    required this.size,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'sourcePath': sourcePath,
        'destPath': destPath,
        'name': name,
        'size': size,
        'status': status.name,
        'error': error,
      };

  factory CopySessionFile.fromJson(Map<String, dynamic> j) => CopySessionFile(
        sourcePath: j['sourcePath'] as String,
        destPath: j['destPath'] as String,
        name: j['name'] as String,
        size: j['size'] as int,
        status: CopyFileStatus.values.byName(j['status'] as String),
        error: j['error'] as String?,
      );
}

enum CopyFileStatus { pending, success, skipped, failed }

class CopySession {
  final String id;
  final String sourceDir;
  final String destDir;
  final List<CopySessionFile> files;
  final CopySessionStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const CopySession({
    required this.id,
    required this.sourceDir,
    required this.destDir,
    required this.files,
    required this.status,
    required this.startedAt,
    this.finishedAt,
  });

  int get totalCount => files.length;
  int get succeededCount =>
      files.where((f) => f.status == CopyFileStatus.success).length;
  int get failedCount =>
      files.where((f) => f.status == CopyFileStatus.failed).length;
  int get skippedCount =>
      files.where((f) => f.status == CopyFileStatus.skipped).length;

  List<CopySessionFile> get failedFiles =>
      files.where((f) => f.status == CopyFileStatus.failed).toList();
  List<CopySessionFile> get pendingFiles =>
      files.where((f) => f.status == CopyFileStatus.pending).toList();

  CopySession copyWith({
    CopySessionStatus? status,
    List<CopySessionFile>? files,
    DateTime? finishedAt,
  }) =>
      CopySession(
        id: id,
        sourceDir: sourceDir,
        destDir: destDir,
        files: files ?? this.files,
        status: status ?? this.status,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceDir': sourceDir,
        'destDir': destDir,
        'files': files.map((f) => f.toJson()).toList(),
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory CopySession.fromJson(Map<String, dynamic> j) => CopySession(
        id: j['id'] as String,
        sourceDir: j['sourceDir'] as String,
        destDir: j['destDir'] as String,
        files: (j['files'] as List)
            .map((e) => CopySessionFile.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: CopySessionStatus.values.byName(j['status'] as String),
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: j['finishedAt'] != null
            ? DateTime.parse(j['finishedAt'] as String)
            : null,
      );
}
