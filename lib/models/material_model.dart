class MaterialModel {
  final int? id;
  final String classId;
  final String title;
  final String languageCode;
  final String? simplifiedContent;
  final String? standardContent;
  final String? advancedContent;
  final String? selectedContentType;
  final String? selectedContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive;

  MaterialModel({
    this.id,
    required this.classId,
    required this.title,
    required this.languageCode,
    this.simplifiedContent,
    this.standardContent,
    this.advancedContent,
    this.selectedContentType,
    this.selectedContent,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.isActive,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] as int?,
      classId: map['class_id'] as String,
      title: map['title'] as String,
      languageCode: map['language_code'] as String,
      simplifiedContent: map['simplified_content'] as String?,
      standardContent: map['standard_content'] as String?,
      advancedContent: map['advanced_content'] as String?,
      selectedContentType: map['selected_content_type'] as String?,
      selectedContent: map['selected_content'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'language_code': languageCode,
      'simplified_content': simplifiedContent,
      'standard_content': standardContent,
      'advanced_content': advancedContent,
      'selected_content_type': selectedContentType,
      'selected_content': selectedContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'is_active': isActive,
    };
  }

  MaterialModel copyWith({
    int? id,
    String? classId,
    String? title,
    String? languageCode,
    String? simplifiedContent,
    String? standardContent,
    String? advancedContent,
    String? selectedContentType,
    String? selectedContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      languageCode: languageCode ?? this.languageCode,
      simplifiedContent: simplifiedContent ?? this.simplifiedContent,
      standardContent: standardContent ?? this.standardContent,
      advancedContent: advancedContent ?? this.advancedContent,
      selectedContentType: selectedContentType ?? this.selectedContentType,
      selectedContent: selectedContent ?? this.selectedContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
