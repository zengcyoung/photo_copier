import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check if any storage-level access is already granted.
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    if (await Permission.photos.isGranted) return true;
    if (await Permission.videos.isGranted) return true;
    return false;
  }

  /// Request storage access. On Android 11+ this opens the "All files
  /// access" settings page; on older versions it shows the system dialog.
  /// Returns true if any permission is ultimately granted.
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return await Permission.manageExternalStorage.isGranted;
    }

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();
    return photos.isGranted || videos.isGranted;
  }
}
