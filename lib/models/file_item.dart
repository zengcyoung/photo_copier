class FileItem {
  final String path;
  final String name;
  final int size; // bytes
  final DateTime modifiedAt;
  final String extension; // lowercase, no dot e.g. "jpg"

  const FileItem({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedAt,
    required this.extension,
  });

  double get sizeMiB => size / (1024 * 1024);

  bool get isImage => const {
        'jpg', 'jpeg', 'heic', 'heif', 'png', 'gif', 'webp', 'bmp',
        'raw', 'arw', 'cr2', 'cr3', 'nef', 'orf', 'raf', 'dng', 'rw2',
      }.contains(extension);

  bool get isVideo => const {
        'mp4', 'mov', 'avi', 'mkv', 'm4v', '3gp', 'mts', 'm2ts',
      }.contains(extension);

  @override
  bool operator ==(Object other) =>
      other is FileItem && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
