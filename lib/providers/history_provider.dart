import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/copy_session.dart';
import '../services/history_service.dart';

class HistoryNotifier extends AsyncNotifier<List<CopySession>> {
  late HistoryService _service;

  @override
  Future<List<CopySession>> build() async {
    _service = ref.read(historyServiceProvider);
    return _service.loadHistory();
  }

  Future<void> saveSession(CopySession session) async {
    await _service.saveSession(session);
    state = AsyncData(await _service.loadHistory());
  }

  Future<void> reload() async {
    state = AsyncData(await _service.loadHistory());
  }
}

final historyServiceProvider = Provider((_) => HistoryService());

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<CopySession>>(
  HistoryNotifier.new,
);
