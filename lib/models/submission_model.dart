import 'image_attachment_model.dart';

enum SubmissionStatus { draft, submitted, graded, late }

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String content; // Text content of the submission
  final List<ImageAttachmentModel>? imageAttachments; // Image attachments
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final int? grade; // Points earned
  final String? feedback; // Teacher feedback
  final SubmissionStatus status;
  final bool isLate;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.content,
    this.imageAttachments,
    required this.submittedAt,
    this.gradedAt,
    this.grade,
    this.feedback,
    required this.status,
    required this.isLate,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing submission JSON: $json');
      
      // Handle status parsing
      SubmissionStatus status;
      final statusValue = json['status'];
      if (statusValue is String) {
        status = SubmissionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusValue,
          orElse: () => SubmissionStatus.submitted,
        );
      } else {
        status = SubmissionStatus.submitted;
      }

      final submission = SubmissionModel(
        id: json['id'] ?? '',
        assignmentId: json['assignment_id'] ?? json['assignmentId'] ?? '',
        studentId: json['student_id'] ?? json['studentId'] ?? '',
        studentName: json['student_name'] ?? json['studentName'] ?? '',
        content: json['content'] ?? '',
        imageAttachments: json['image_attachments'] != null 
            ? (json['image_attachments'] as List)
                .map((item) => ImageAttachmentModel.fromJson(item))
                .toList()
            : null,
        submittedAt: DateTime.parse(json['submitted_at'] ?? json['submittedAt'] ?? DateTime.now().toIso8601String()),
        gradedAt: json['graded_at'] != null || json['gradedAt'] != null
            ? DateTime.parse(json['graded_at'] ?? json['gradedAt'] ?? DateTime.now().toIso8601String())
            : null,
        grade: json['grade'],
        feedback: json['feedback'],
        status: status,
        isLate: json['is_late'] ?? json['isLate'] ?? false,
      );
      
      print('Successfully parsed submission: ${submission.studentName}');
      return submission;
    } catch (e) {
      print('Error parsing submission JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'student_name': studentName,
      'content': content,
      'image_attachments': imageAttachments?.map((img) => img.toJson()).toList(),
      'submitted_at': submittedAt.toIso8601String(),
      'graded_at': gradedAt?.toIso8601String(),
      'grade': grade,
      'feedback': feedback,
      'status': status.toString().split('.').last,
      'is_late': isLate,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? content,
    List<ImageAttachmentModel>? imageAttachments,
    DateTime? submittedAt,
    DateTime? gradedAt,
    int? grade,
    String? feedback,
    SubmissionStatus? status,
    bool? isLate,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      content: content ?? this.content,
      imageAttachments: imageAttachments ?? this.imageAttachments,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      isLate: isLate ?? this.isLate,
    );
  }

  bool get isGraded => status == SubmissionStatus.graded;
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;
}
