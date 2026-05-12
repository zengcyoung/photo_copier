import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'file_list_screen.dart';

class StoragePickerScreen extends ConsumerStatefulWidget {
  const StoragePickerScreen({super.key});

  @override
  ConsumerState<StoragePickerScreen> createState() =>
      _StoragePickerScreenState();
}

class _StoragePickerScreenState extends ConsumerState<StoragePickerScreen> {
  final _storageService = StorageService();
  List<StorageVolume>? _volumes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVolumes();
  }

  Future<void> _loadVolumes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final volumes = await _storageService.getVolumes();
      if (!mounted) return;
      if (volumes.length == 1) {
        // Skip picker if only one volume
        _openVolume(volumes.first);
        return;
      }
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
