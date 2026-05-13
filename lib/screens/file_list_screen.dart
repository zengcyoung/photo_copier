import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../models/file_filter.dart';
import '../providers/file_list_provider.dart';
import '../providers/prefs_provider.dart';
import '../services/storage_service.dart';
import '../widgets/file_tile.dart';
import '../widgets/filter_sheet.dart';
import '../utils/format_utils.dart';
import 'copy_progress_screen.dart';
import 'history_screen.dart';

class FileListScreen extends ConsumerStatefulWidget {
  final StorageVolume volume;

  const FileListScreen({super.key, required this.volume});

  @override
  ConsumerState<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends ConsumerState<FileListScreen> {
  final Set<String> _selected = {};
  bool _multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileListProvider.notifier).loadPath(widget.volume.path);
    });
  }

  void _onItemTap(FileItem item) {
    if (item.isDirectory) {
      _clearSelection();
      ref.read(fileListProvider.notifier).navigateInto(item.path);
      return;
    }
    // file tap in non-multi mode: enter multi-select
    setState(() {
      _multiSelectMode = true;
      _selected.add(item.path);
    });
  }

  void _toggleSelect(FileItem item) {
    setState(() {
      if (_selected.contains(item.path)) {
        _selected.remove(item.path);
        if (_selected.isEmpty) _multiSelectMode = false;
      } else {
        _selected.add(item.path);
      }
    });
  }

  void _enterMultiSelect(FileItem item) {
    setState(() {
      _multiSelectMode = true;
      _selected.add(item.path);
    });
  }

  void _selectAll(List<FileItem> files) {
    setState(() {
      if (_selected.length == files.length) {
        _selected.clear();
        _multiSelectMode = false;
      } else {
        _selected
          ..clear()
          ..addAll(files.map((f) => f.path));
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
      _multiSelectMode = false;
    });
  }

  void _openFilter(FileListState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        initial: state.filter,
        availableExtensions: state.allExtensions,
        onApply: (filter) =>
            ref.read(fileListProvider.notifier).applyFilter(filter),
      ),
    );
  }

  void _startCopy(List<FileItem> allFiles, String lastDest) async {
    final selected = allFiles
        .where((f) => _selected.contains(f.path))
        .toList();
    if (selected.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopyProgressScreen(
          files: selected,
          sourceDir: widget.volume.path,
          suggestedDestDir: lastDest,
        ),
      ),
    );
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileListProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const AppPrefs();
    final thumbnailEnabled = prefs.thumbnailEnabled;
    final canGoUp = state.canGoUp;

    return PopScope(
      canPop: !canGoUp,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoUp) {
          ref.read(fileListProvider.notifier).navigateUp();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _multiSelectMode
              ? Text('${_selected.length} selected')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.volume.name,
                        style: const TextStyle(fontSize: 16)),
                    if (canGoUp)
                      Text(
                        _relativePath(state.currentPath, widget.volume.path),
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
          leading: _multiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : canGoUp
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () =>
                          ref.read(fileListProvider.notifier).navigateUp(),
                    )
                  : null,
          actions: [
            if (_multiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select all',
              onPressed: () => _selectAll(state.files),
            ),
          ] else ...[
            IconButton(
              icon: Icon(thumbnailEnabled
                  ? Icons.image
                  : Icons.image_not_supported),
              tooltip: 'Toggle thumbnails',
              onPressed: () => ref
                  .read(prefsProvider.notifier)
                  .setThumbnailEnabled(!thumbnailEnabled),
            ),
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (!state.filter.isEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filter',
              onPressed: () => _openFilter(state),
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Copy history',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(fileListProvider.notifier).refresh(),
            ),
          ],
        ],
      ),
      body: _buildBody(state, thumbnailEnabled),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _startCopy(state.files, prefs.lastDestDir),
              icon: const Icon(Icons.copy),
              label: Text('Copy ${_selected.length} items'),
            )
          : null,
      ),
    );
  }

  String _relativePath(String current, String root) {
    if (current.startsWith(root)) {
      final rel = current.substring(root.length);
      return rel.isEmpty ? '/' : rel;
    }
    return current;
  }

  String _itemCountLabel(List<FileItem> items) {
    final dirs = items.where((i) => i.isDirectory).length;
    final files = items.where((i) => !i.isDirectory).length;
    if (dirs > 0 && files > 0) return '$dirs folders, $files files';
    if (dirs > 0) return '$dirs folders';
    return '$files files';
  }

  Widget _buildBody(FileListState state, bool thumbnailEnabled) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(fileListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.filter.isEmpty
                ? 'No files found'
                : 'No files match the current filter'),
            if (!state.filter.isEmpty)
              TextButton(
                onPressed: () => ref
                    .read(fileListProvider.notifier)
                    .applyFilter(FileFilter.empty),
                child: const Text('Clear filter'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!state.filter.isEmpty) _FilterSummary(filter: state.filter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                _itemCountLabel(state.files),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.files.length,
            separatorBuilder: (context, i) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = state.files[i];
              return FileTile(
                item: item,
                selected: _selected.contains(item.path),
                multiSelectMode: _multiSelectMode && !item.isDirectory,
                showThumbnail: thumbnailEnabled,
                onTap: _multiSelectMode && !item.isDirectory
                    ? () => _toggleSelect(item)
                    : () => _onItemTap(item),
                onLongPress: item.isDirectory
                    ? null
                    : () => _enterMultiSelect(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterSummary extends StatelessWidget {
  final FileFilter filter;

  const _FilterSummary({required this.filter});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (filter.dateFrom != null || filter.dateTo != null) {
      String label = 'Date: ';
      if (filter.dateFrom != null && filter.dateTo != null) {
        label +=
            '${formatDateShort(filter.dateFrom!)} – ${formatDateShort(filter.dateTo!)}';
      } else if (filter.dateFrom != null) {
        label += '≥ ${formatDateShort(filter.dateFrom!)}';
      } else {
        label += '≤ ${formatDateShort(filter.dateTo!)}';
      }
      chips.add(Chip(label: Text(label)));
    }
    if (filter.extensions.isNotEmpty) {
      chips.add(
          Chip(label: Text(filter.extensions.map((e) => e.toUpperCase()).join(', '))));
    }
    if (filter.minSizeMiB != null) {
      chips.add(Chip(label: Text('> ${filter.minSizeMiB!.toStringAsFixed(0)} MiB')));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
    );
  }
}
