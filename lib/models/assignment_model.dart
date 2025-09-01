import 'class_model.dart';

enum AssignmentStatus { active, inactive, archived }

class AssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int totalPoints;
  final AssignmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? attachments; // URLs to attached files
  final String? instructions; // Additional instructions for students
  final ClassModel? classDetails; // Related class, if included via join

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.totalPoints,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.attachments,
    this.instructions,
    this.classDetails,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    // Handle status parsing
    AssignmentStatus status;
    final statusValue = json['status'];
    if (statusValue is String) {
      status = AssignmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusValue,
        orElse: () => AssignmentStatus.active,
      );
    } else {
      status = AssignmentStatus.active;
    }

    return AssignmentModel(
      id: json['id'] ?? '',
      classId: json['class_id'] ?? json['classId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String()),
      totalPoints: json['total_points'] ?? json['totalPoints'] ?? 0,
      status: status,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String())
          : null,
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments'])
          : null,
      instructions: json['instructions'],
      classDetails: _parseClassRelation(json),
      
    );
  }
  
  static ClassModel? _parseClassRelation(Map<String, dynamic> json) {
    final dynamic classJson = json['class'] ?? json['class_details'] ?? json['classInfo'] ?? json['classData'] ?? json['classes'];
    if (classJson is Map<String, dynamic>) {
      return ClassModel.fromJson(classJson);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'total_points': totalPoints,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'attachments': attachments,
      'instructions': instructions,
      'class': classDetails?.toJson(),
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? totalPoints,
    AssignmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    String? instructions,
    ClassModel? classDetails,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      totalPoints: totalPoints ?? this.totalPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      instructions: instructions ?? this.instructions,
      classDetails: classDetails ?? this.classDetails,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get isActive => status == AssignmentStatus.active;
}
