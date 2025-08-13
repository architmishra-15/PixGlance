class CachedImage {
  final String originalPath;
  final String cachePath;
  final String fileName;
  final int fileSize;
  final DateTime lastAccessed;

  const CachedImage({
    required this.originalPath,
    required this.cachePath,
    required this.fileName,
    required this.fileSize,
    required this.lastAccessed,
  });

  CachedImage copyWith({
    String? originalPath,
    String? cachePath,
    String? fileName,
    int? fileSize,
    DateTime? lastAccessed,
  }) {
    return CachedImage(
      originalPath: originalPath ?? this.originalPath,
      cachePath: cachePath ?? this.cachePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'cachePath': cachePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory CachedImage.fromJson(Map<String, dynamic> json) {
    return CachedImage(
      originalPath: json['originalPath'] as String,
      cachePath: json['cachePath'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedImage && other.originalPath == originalPath;
  }

  @override
  int get hashCode => originalPath.hashCode;
}