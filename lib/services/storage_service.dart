import 'dart:io';

/// Discovers external storage volumes on Android.
/// Falls back to a best-effort path scan when platform channel is unavailable.
class StorageService {

  Future<List<StorageVolume>> getVolumes() async {
    final volumes = <StorageVolume>[];

    // Walk /storage — on Android, each mounted volume appears here
    final storageDir = Directory('/storage');
    if (storageDir.existsSync()) {
      try {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            // Skip 'self' which is a symlink to emulated/0
            if (name == 'self') continue;
            if (_isAccessible(entity.path)) {
              final isInternal = name == 'emulated';
              final displayPath =
                  isInternal ? '/storage/emulated/0' : entity.path;
              final displayName =
                  isInternal ? 'Internal Storage' : 'SD Card ($name)';
              volumes.add(StorageVolume(
                path: displayPath,
                name: displayName,
                isRemovable: !isInternal,
              ));
            }
          }
        }
      } catch (_) {}
    }

    // Check /mnt/media_rw for USB OTG drives
    final mediaDirs = [Directory('/mnt/media_rw'), Directory('/mnt/usb')];
    for (final dir in mediaDirs) {
      if (!dir.existsSync()) continue;
      try {
        await for (final entity in dir.list()) {
          if (entity is Directory && _isAccessible(entity.path)) {
            final name = entity.path.split('/').last;
            if (!volumes.any((v) => v.path == entity.path)) {
              volumes.add(StorageVolume(
                path: entity.path,
                name: 'USB Drive ($name)',
                isRemovable: true,
              ));
            }
          }
        }
      } catch (_) {}
    }

    // Fallback: at least include internal
    if (volumes.isEmpty) {
      volumes.add(const StorageVolume(
        path: '/storage/emulated/0',
        name: 'Internal Storage',
        isRemovable: false,
      ));
    }

    return volumes;
  }

  bool _isAccessible(String path) {
    try {
      Directory(path).listSync().isEmpty; // ignore: unnecessary_statements
      return true;
    } catch (_) {
      return false;
    }
  }
}

class StorageVolume {
  final String path;
  final String name;
  final bool isRemovable;

  const StorageVolume({
    required this.path,
    required this.name,
    required this.isRemovable,
  });
}
