class Otak {
  final String id;
  final String userId;
  final String fileName;
  final int fileSize;
  final String fileUrl;
  final String storagePath;
  final String summary;
  final DateTime uploadedAt;
  final List<String> topics;
  final String? folderId;

  Otak({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.storagePath,
    this.summary = '',
    required this.uploadedAt,
    this.topics = const [],
    this.folderId,
  });

  factory Otak.fromJson(Map<String, dynamic> json, String id) {
    return Otak(
      id: id,
      userId: json['userId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      fileUrl: json['fileUrl'] as String,
      storagePath: json['storagePath'] as String,
      summary: json['summary'] as String? ?? '',
      uploadedAt: (json['uploadedAt'] as dynamic).toDate(),
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      folderId: json['folderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'summary': summary,
      'uploadedAt': uploadedAt,
      'topics': topics,
      'folderId': folderId,
    };
  }

  Otak copyWith({
    String? id,
    String? userId,
    String? fileName,
    int? fileSize,
    String? fileUrl,
    String? storagePath,
    String? summary,
    DateTime? uploadedAt,
    List<String>? topics,
    String? folderId,
  }) {
    return Otak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      summary: summary ?? this.summary,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      topics: topics ?? this.topics,
      folderId: folderId ?? this.folderId,
    );
  }
}