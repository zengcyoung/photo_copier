import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import 'file_list_screen.dart';

enum _PermState { checking, granted, denied }

class StoragePickerScreen extends ConsumerStatefulWidget {
  const StoragePickerScreen({super.key});

  @override
  ConsumerState<StoragePickerScreen> createState() =>
      _StoragePickerScreenState();
}

class _StoragePickerScreenState extends ConsumerState<StoragePickerScreen> {
  final _storageService = StorageService();
  final _permService = PermissionService();
  List<StorageVolume>? _volumes;
  bool _loading = true;
  String? _error;
  _PermState _permState = _PermState.checking;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await _permService.hasStoragePermission();
    if (!mounted) return;
    setState(() => _permState = granted ? _PermState.granted : _PermState.denied);
    if (granted) _loadVolumes();
  }

  Future<void> _requestPermission() async {
    setState(() => _permState = _PermState.checking);
    final granted = await _permService.requestStoragePermission();
    if (!mounted) return;
    setState(() => _permState = granted ? _PermState.granted : _PermState.denied);
    if (granted) _loadVolumes();
  }

  Future<void> _loadVolumes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final volumes = await _storageService.getVolumes();
      if (!mounted) return;
      setState(() {
        _volumes = volumes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openVolume(StorageVolume volume) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => FileListScreen(volume: volume),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_permState == _PermState.checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permState == _PermState.denied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Storage')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Storage permission is required to browse files on external storage.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app needs access to read and copy photos and videos from SD cards and USB drives.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Grant Permission'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _loadVolumes, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Storage')),
      body: ListView.builder(
        itemCount: _volumes?.length ?? 0,
        itemBuilder: (context, i) {
          final vol = _volumes![i];
          return ListTile(
            leading: Icon(
              vol.isRemovable ? Icons.sd_storage : Icons.storage,
              color: vol.isRemovable ? Colors.blue : Colors.grey,
            ),
            title: Text(vol.name),
            subtitle: Text(vol.path),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openVolume(vol),
          );
        },
      ),
    );
  }
}
