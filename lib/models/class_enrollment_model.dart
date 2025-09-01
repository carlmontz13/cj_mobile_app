class ClassEnrollmentModel {
  final String id;
  final String classId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final DateTime enrolledAt;
  final String status;

  ClassEnrollmentModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.enrolledAt,
    required this.status,
  });

  factory ClassEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return ClassEnrollmentModel(
      id: json['id'] ?? '',
      classId: json['class_id'] ?? json['classId'] ?? '',
      studentId: json['student_id'] ?? json['studentId'] ?? '',
      studentName: json['student_name'] ?? json['studentName'] ?? '',
      studentEmail: json['student_email'] ?? json['studentEmail'] ?? '',
      enrolledAt: DateTime.parse(json['enrolled_at'] ?? json['enrolledAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'enrolled_at': enrolledAt.toIso8601String(),
      'status': status,
    };
  }

  ClassEnrollmentModel copyWith({
    String? id,
    String? classId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    DateTime? enrolledAt,
    String? status,
  }) {
    return ClassEnrollmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      status: status ?? this.status,
    );
  }
}
