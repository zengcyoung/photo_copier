import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final String lastDestDir;
  final bool thumbnailEnabled;

  const AppPrefs({
    this.lastDestDir = '/storage/emulated/0/DCIM/Imported',
    this.thumbnailEnabled = true,
  });

  AppPrefs copyWith({String? lastDestDir, bool? thumbnailEnabled}) => AppPrefs(
        lastDestDir: lastDestDir ?? this.lastDestDir,
        thumbnailEnabled: thumbnailEnabled ?? this.thumbnailEnabled,
      );
}

class PrefsNotifier extends AsyncNotifier<AppPrefs> {
  static const _destKey = 'last_dest_dir';
  static const _thumbKey = 'thumbnail_enabled';

  @override
  Future<AppPrefs> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPrefs(
      lastDestDir: prefs.getString(_destKey) ??
          '/storage/emulated/0/DCIM/Imported',
      thumbnailEnabled: prefs.getBool(_thumbKey) ?? true,
    );
  }

  Future<void> setLastDestDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_destKey, path);
    state = AsyncData((state.value ?? const AppPrefs()).copyWith(lastDestDir: path));
  }

  Future<void> setThumbnailEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_thumbKey, enabled);
    state = AsyncData(
        (state.value ?? const AppPrefs()).copyWith(thumbnailEnabled: enabled));
  }
}

final prefsProvider = AsyncNotifierProvider<PrefsNotifier, AppPrefs>(
  PrefsNotifier.new,
);
