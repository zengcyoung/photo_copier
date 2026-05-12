class FileFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Set<String> extensions; // lowercase, no dot
  final double? minSizeMiB;

  const FileFilter({
    this.dateFrom,
    this.dateTo,
    this.extensions = const {},
    this.minSizeMiB,
  });

  bool get isEmpty =>
      dateFrom == null &&
      dateTo == null &&
      extensions.isEmpty &&
      minSizeMiB == null;

  FileFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    Set<String>? extensions,
    double? minSizeMiB,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearMinSize = false,
  }) =>
      FileFilter(
        dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
        dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
        extensions: extensions ?? this.extensions,
        minSizeMiB: clearMinSize ? null : (minSizeMiB ?? this.minSizeMiB),
      );

  static const FileFilter empty = FileFilter();
}
