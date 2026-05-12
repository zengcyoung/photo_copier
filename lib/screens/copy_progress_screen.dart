import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../models/copy_session.dart';
import '../providers/history_provider.dart';
import '../providers/prefs_provider.dart';
import '../services/copy_service.dart';
import '../services/history_service.dart';
import '../widgets/conflict_dialog.dart';

class CopyProgressScreen extends ConsumerStatefulWidget {
  final List<FileItem> files;
  final String sourceDir;
  final String suggestedDestDir;

  const CopyProgressScreen({
    super.key,
    required this.files,
    required this.sourceDir,
    required this.suggestedDestDir,
  });

  @override
  ConsumerState<CopyProgressScreen> createState() =>
      _CopyProgressScreenState();
}

class _CopyProgressScreenState extends ConsumerState<CopyProgressScreen> {
  late final CopyService _copyService;
  late final HistoryService _historyService;

  String _destDir = '';
  bool _running = false;
  bool _done = false;
  bool _interrupted = false;

  int _current = 0;
  int _total = 0;
  String _currentFile = '';
  int _succeeded = 0;
  int _skipped = 0;
  int _failed = 0;
  String _interruptReason = '';
  List<FileItem> _remaining = [];

  // For conflict dialogs
  ConflictChoice? _globalConflict;

  StreamSubscription<CopyEvent>? _sub;
  Completer<ConflictChoice>? _pendingConflict;

  @override
  void initState() {
    super.initState();
    _historyService = ref.read(historyServiceProvider);
    _copyService = CopyService(_historyService);
    _destDir = widget.suggestedDestDir;
    _total = widget.files.length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _selectDest() async {
    // Use a simple TextEditingController dialog since file_picker isn't installed
    final ctrl = TextEditingController(text: _destDir);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Destination directory'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/DCIM/Imported',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _destDir = result;
      });
      await ref.read(prefsProvider.notifier).setLastDestDir(result);
    }
  }

  Future<void> _startCopy({List<FileItem>? files}) async {
    final copyFiles = files ?? widget.files;
    if (_destDir.isEmpty) {
      await _selectDest();
      if (_destDir.isEmpty) return;
    }

    // Ensure dest directory exists
    await Directory(_destDir).create(recursive: true);

    final session = CopySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceDir: widget.sourceDir,
      destDir: _destDir,
      files: copyFiles
          .map((f) => CopySessionFile(
                sourcePath: f.path,
                destPath: p.join(_destDir, f.name),
                name: f.name,
                size: f.size,
                status: CopyFileStatus.pending,
              ))
          .toList(),
      status: CopySessionStatus.running,
      startedAt: DateTime.now(),
    );

    await _historyService.saveSession(session);

    setState(() {
      _running = true;
      _done = false;
      _interrupted = false;
      _current = 0;
      _total = copyFiles.length;
      _succeeded = 0;
      _skipped = 0;
      _failed = 0;
      _remaining = [];
    });

    _sub = _copyService
        .copyFiles(
          session: session,
          files: copyFiles,
          destDir: _destDir,
          defaultConflict: _globalConflict,
        )
        .listen(
          _onEvent,
          onError: (e) {
            setState(() {
              _running = false;
              _interrupted = true;
              _interruptReason = e.toString();
            });
          },
          onDone: () {},
        );
  }

  void _onEvent(CopyEvent event) {
    switch (event) {
      case CopyProgress p:
        setState(() {
          _current = p.current;
          _currentFile = p.fileName;
        });

      case CopyConflict c:
        _pendingConflict = c.completer;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ConflictDialog(
            info: c.info,
            onDecide: (result) {
              final (choice, applyAll) = result;
              if (applyAll) _globalConflict = choice;
              Navigator.pop(context);
              _pendingConflict?.complete(choice);
              _pendingConflict = null;
            },
          ),
        );

      case CopyDone d:
        setState(() {
          _running = false;
          _done = true;
          _succeeded = d.succeeded;
          _skipped = d.skipped;
          _failed = d.failed;
        });
        ref.read(historyProvider.notifier).reload();

      case CopyInterrupted i:
        setState(() {
          _running = false;
          _interrupted = true;
          _interruptReason = i.error;
          _remaining = i.remaining;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copy'),
        automaticallyImplyLeading: !_running,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_running && !_done && !_interrupted) {
      return _buildSetup();
    }
    if (_running) {
      return _buildProgress();
    }
    if (_done) {
      return _buildDone();
    }
    if (_interrupted) {
      return _buildInterrupted();
    }
    return const SizedBox.shrink();
  }

  Widget _buildSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.files.length} files selected',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Destination: $_destDir',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
                onPressed: _selectDest, child: const Text('Change')),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _startCopy,
          icon: const Icon(Icons.copy),
          label: const Text('Start Copy'),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _total > 0 ? _current / _total : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 16),
        Text('$_current / $_total', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          _currentFile,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text('Done!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text('✅ $_succeeded  copied'),
        if (_skipped > 0) Text('⏭ $_skipped  skipped'),
        if (_failed > 0) Text('❌ $_failed  failed', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done')),
      ],
    );
  }

  Widget _buildInterrupted() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning, color: Colors.orange, size: 64),
        const SizedBox(height: 16),
        Text('Copy interrupted',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(_interruptReason,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (_remaining.isNotEmpty)
          Text('${_remaining.length} files remaining'),
        const SizedBox(height: 24),
        if (_remaining.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _startCopy(files: _remaining),
            icon: const Icon(Icons.replay),
            label: const Text('Retry remaining'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}
