class ClassModel {
  final String id;
  final String name;
  final String description;
  final String teacherId;
  final String teacherName;
  final String section;
  final String subject;
  final String room;
  final String classCode;
  final DateTime createdAt;
  final int studentCount;
  final String? bannerImageUrl;
  final String? themeColor;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    required this.section,
    required this.subject,
    required this.room,
    required this.classCode,
    required this.createdAt,
    required this.studentCount,
    this.bannerImageUrl,
    this.themeColor,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      teacherId: json['teacher_id'] ?? json['teacherId'] ?? '',
      teacherName: json['teacher_name'] ?? json['teacherName'] ?? '',
      section: json['section'] ?? '',
      subject: json['subject'] ?? '',
      room: json['room'] ?? '',
      classCode: json['class_code'] ?? json['classCode'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      studentCount: json['student_count'] ?? json['studentCount'] ?? 0,
      bannerImageUrl: json['banner_image_url'] ?? json['bannerImageUrl'],
      themeColor: json['theme_color'] ?? json['themeColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'section': section,
      'subject': subject,
      'room': room,
      'class_code': classCode,
      'created_at': createdAt.toIso8601String(),
      'student_count': studentCount,
      'banner_image_url': bannerImageUrl,
      'theme_color': themeColor,
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? teacherId,
    String? teacherName,
    String? section,
    String? subject,
    String? room,
    String? classCode,
    DateTime? createdAt,
    int? studentCount,
    String? bannerImageUrl,
    String? themeColor,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      classCode: classCode ?? this.classCode,
      createdAt: createdAt ?? this.createdAt,
      studentCount: studentCount ?? this.studentCount,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
