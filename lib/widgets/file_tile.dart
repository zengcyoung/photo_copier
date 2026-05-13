import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../utils/format_utils.dart';

class FileTile extends StatelessWidget {
  final FileItem item;
  final bool selected;
  final bool multiSelectMode;
  final bool showThumbnail;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FileTile({
    super.key,
    required this.item,
    required this.selected,
    required this.multiSelectMode,
    required this.showThumbnail,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isDirectory) {
      return ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Colors.amber),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: _buildLeading(context),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatSize(item.size)}  ·  ${formatDate(item.modifiedAt)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: multiSelectMode
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : null,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (showThumbnail && (item.isImage || item.isVideo)) {
      return _ThumbnailWidget(item: item);
    }
    return _ExtIcon(extension: item.extension);
  }
}

class _ThumbnailWidget extends StatefulWidget {
  final FileItem item;

  const _ThumbnailWidget({required this.item});

  @override
  State<_ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  ImageProvider? _image;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final file = File(widget.item.path);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _image = FileImage(file);
            _loaded = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _image != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Image(
          image: _image!,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _ExtIcon(extension: widget.item.extension),
        ),
      );
    }
    return _ExtIcon(extension: widget.item.extension);
  }
}

class _ExtIcon extends StatelessWidget {
  final String extension;

  const _ExtIcon({required this.extension});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if ({'jpg', 'jpeg', 'heic', 'heif', 'png', 'gif', 'webp', 'bmp',
          'raw', 'arw', 'cr2', 'cr3', 'nef', 'orf', 'raf', 'dng', 'rw2'}
        .contains(extension)) {
      icon = Icons.image;
      color = Colors.green;
    } else if ({'mp4', 'mov', 'avi', 'mkv', 'm4v', '3gp', 'mts', 'm2ts'}
        .contains(extension)) {
      icon = Icons.videocam;
      color = Colors.blue;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}
