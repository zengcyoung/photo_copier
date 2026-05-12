import 'package:intl/intl.dart';

final _sizeFormatter = NumberFormat('#,##0.0');
final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${_sizeFormatter.format(bytes / 1024)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${_sizeFormatter.format(bytes / (1024 * 1024))} MB';
  }
  return '${_sizeFormatter.format(bytes / (1024 * 1024 * 1024))} GB';
}

String formatDate(DateTime dt) => _dateFormatter.format(dt);

String formatDateShort(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
