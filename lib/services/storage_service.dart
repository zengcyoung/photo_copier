import 'package:flutter/services.dart';

/// Discovers external storage volumes on Android via StorageManager MethodChannel.
/// Uses the Android StorageManager API to enumerate mounted volumes safely
/// without touching SELinux-restricted paths like /mnt/media_rw.
class StorageService {
  static const _channel = MethodChannel('com.ewanyang.photo_copier/storage');

  Future<List<StorageVolume>> getVolumes() async {
    try {
      final List<dynamic> raw =
          await _channel.invokeMethod<List<dynamic>>('getStorageVolumes') ??
              [];

      final volumes = raw
          .cast<Map<dynamic, dynamic>>()
          .map((m) => StorageVolume(
                path: m['path'] as String,
                name: m['name'] as String,
                isRemovable: m['isRemovable'] as bool,
                isPrimary: m['isPrimary'] as bool? ?? false,
              ))
          .toList();

      // Sort: primary first, then removable
      volumes.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return a.name.compareTo(b.name);
      });

      return volumes;
    } on PlatformException catch (e) {
      // Fallback on any platform error
      return [
        StorageVolume(
          path: '/storage/emulated/0',
          name: 'Internal Storage',
          isRemovable: false,
          isPrimary: true,
          error: e.message,
        ),
      ];
    }
  }
}

class StorageVolume {
  final String path;
  final String name;
  final bool isRemovable;
  final bool isPrimary;
  final String? error;

  const StorageVolume({
    required this.path,
    required this.name,
    required this.isRemovable,
    required this.isPrimary,
    this.error,
  });
}
