class ImageAttachmentModel {
  final String id;
  final String url;
  final String fileName;
  final String originalName;
  final double sizeInMB;
  final DateTime uploadedAt;
  final String submissionId;
  // Optional local preview path (when not uploaded yet)
  final String? previewPath;
  // Indicates whether this image has been uploaded to storage
  final bool isUploaded;

  ImageAttachmentModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.originalName,
    required this.sizeInMB,
    required this.uploadedAt,
    required this.submissionId,
    this.previewPath,
    this.isUploaded = true,
  });

  factory ImageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ImageAttachmentModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      originalName: json['original_name'] ?? json['originalName'] ?? '',
      sizeInMB: (json['size_in_mb'] ?? json['sizeInMB'] ?? 0.0).toDouble(),
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      submissionId: json['submission_id'] ?? json['submissionId'] ?? '',
      previewPath: null,
      isUploaded: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'file_name': fileName,
      'original_name': originalName,
      'size_in_mb': sizeInMB,
      'uploaded_at': uploadedAt.toIso8601String(),
      'submission_id': submissionId,
      // previewPath and isUploaded are UI-only and excluded
    };
  }

  ImageAttachmentModel copyWith({
    String? id,
    String? url,
    String? fileName,
    String? originalName,
    double? sizeInMB,
    DateTime? uploadedAt,
    String? submissionId,
    String? previewPath,
    bool? isUploaded,
  }) {
    return ImageAttachmentModel(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      sizeInMB: sizeInMB ?? this.sizeInMB,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      submissionId: submissionId ?? this.submissionId,
      previewPath: previewPath ?? this.previewPath,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  @override
  String toString() {
    return 'ImageAttachmentModel(id: $id, fileName: $fileName, sizeInMB: $sizeInMB)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageAttachmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
