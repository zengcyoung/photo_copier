import 'package:flutter/material.dart';
import '../models/file_filter.dart';
import '../utils/format_utils.dart';

class FilterSheet extends StatefulWidget {
  final FileFilter initial;
  final Set<String> availableExtensions;
  final ValueChanged<FileFilter> onApply;

  const FilterSheet({
    super.key,
    required this.initial,
    required this.availableExtensions,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late Set<String> _extensions;
  late TextEditingController _sizeCtrl;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
    _extensions = Set.from(widget.initial.extensions);
    _sizeCtrl = TextEditingController(
      text: widget.initial.minSizeMiB?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _apply() {
    final minSize = double.tryParse(_sizeCtrl.text);
    widget.onApply(FileFilter(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      extensions: _extensions,
      minSizeMiB: minSize,
    ));
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _extensions = {};
      _sizeCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scroll,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter', style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const Divider(),

            // Date section
            Text('Date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateFrom != null
                        ? 'From: ${formatDateShort(_dateFrom!)}'
                        : 'From: any'),
                    onPressed: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateTo != null
                        ? 'To: ${formatDateShort(_dateTo!)}'
                        : 'To: any'),
                    onPressed: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            if (_dateFrom != null || _dateTo != null)
              TextButton(
                onPressed: () => setState(() {
                  _dateFrom = null;
                  _dateTo = null;
                }),
                child: const Text('Clear date filter'),
              ),

            const SizedBox(height: 16),
            // Extension section
            Text('File type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.availableExtensions.map((ext) {
                final selected = _extensions.contains(ext);
                return FilterChip(
                  label: Text(ext.toUpperCase()),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _extensions.add(ext);
                      } else {
                        _extensions.remove(ext);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            // Size section
            Text('Minimum size', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _sizeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Larger than (MiB)',
                suffixText: 'MiB',
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _apply,
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
