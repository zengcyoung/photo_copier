import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/copy_session.dart';

class HistoryService {
  static const _historyKey = 'copy_history_v1';
  static const _pendingKey = 'pending_copy_v1';

  Future<List<CopySession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CopySession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(CopySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    final idx = history.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      history[idx] = session;
    } else {
      history.insert(0, session);
    }
    // Keep last 100 sessions
    final trimmed = history.take(100).toList();
    await prefs.setString(_historyKey, jsonEncode(trimmed));
  }

  /// Persist the pending file list so we can resume on interruption.
  Future<void> savePending(String sessionId, List<String> pendingPaths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pendingKey, jsonEncode({'sessionId': sessionId, 'paths': pendingPaths}));
  }

  Future<Map<String, dynamic>?> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }
}
