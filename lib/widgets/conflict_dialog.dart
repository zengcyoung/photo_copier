import 'package:flutter/material.dart';
import '../services/copy_service.dart';
import '../utils/format_utils.dart';

class ConflictDialog extends StatefulWidget {
  final ConflictInfo info;
  final ValueChanged<(ConflictChoice, bool applyAll)> onDecide;

  const ConflictDialog({
    super.key,
    required this.info,
    required this.onDecide,
  });

  @override
  State<ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<ConflictDialog> {
  bool _applyAll = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final source = info.source;
    final dest = info.dest;

    return AlertDialog(
      title: const Text('File already exists'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _CompareRow(
            label: 'Source',
            size: source.size,
            modified: source.modifiedAt,
          ),
          const Divider(),
          _CompareRow(
            label: 'Destination',
            size: dest.size,
            modified: dest.modified,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _applyAll,
            onChanged: (v) => setState(() => _applyAll = v ?? false),
            title: const Text('Apply to all remaining conflicts'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              widget.onDecide((ConflictChoice.skip, _applyAll)),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () =>
              widget.onDecide((ConflictChoice.overwrite, _applyAll)),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final int size;
  final DateTime modified;

  const _CompareRow({
    required this.label,
    required this.size,
    required this.modified,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatSize(size)),
                Text(formatDate(modified),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
