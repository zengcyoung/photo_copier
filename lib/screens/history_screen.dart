import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/copy_session.dart';
import '../models/file_item.dart';
import '../providers/history_provider.dart';
import '../utils/format_utils.dart';
import 'copy_progress_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Copy History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No copy history yet'),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (context, i) => const Divider(height: 1),
            itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final CopySession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final hasFailed = session.failedCount > 0;
    final isInterrupted = session.status == CopySessionStatus.interrupted;
    final showRetry = hasFailed || isInterrupted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.status == CopySessionStatus.completed
                    ? Icons.check_circle
                    : Icons.warning,
                color: session.status == CopySessionStatus.completed
                    ? Colors.green
                    : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatDate(session.startedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${session.sourceDir} → ${session.destDir}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Text('✅ ${session.succeededCount} copied'),
              if (session.skippedCount > 0)
                Text('⏭ ${session.skippedCount} skipped'),
              if (hasFailed)
                Text('❌ ${session.failedCount} failed',
                    style: const TextStyle(color: Colors.red)),
            ],
          ),
          if (showRetry) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _retry(context, session),
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Retry failed'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _retry(BuildContext context, CopySession session) {
    final filesToRetry = [
      ...session.failedFiles,
      ...session.pendingFiles,
    ].map((f) => FileItem(
          path: f.sourcePath,
          name: f.name,
          size: f.size,
          modifiedAt: DateTime.now(),
          extension: f.name.contains('.')
              ? f.name.split('.').last.toLowerCase()
              : '',
        ))
        .toList();

    if (filesToRetry.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopyProgressScreen(
          files: filesToRetry,
          sourceDir: session.sourceDir,
          suggestedDestDir: session.destDir,
        ),
      ),
    );
  }
}
