enum UserRole { teacher, student }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final UserRole role;
  final List<String> classIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.role,
    required this.classIds,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle role parsing for different formats
    UserRole role;
    final roleValue = json['role'];
    if (roleValue is String) {
      if (roleValue.startsWith('UserRole.')) {
        // Handle format: 'UserRole.teacher'
        role = UserRole.values.firstWhere(
          (e) => e.toString() == roleValue,
          orElse: () => UserRole.student,
        );
      } else {
        // Handle format: 'teacher' or 'student'
        role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleValue,
          orElse: () => UserRole.student,
        );
      }
    } else {
      role = UserRole.student;
    }

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      role: role,
      classIds: List<String>.from(json['classIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'classIds': classIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    UserRole? role,
    List<String>? classIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      classIds: classIds ?? this.classIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
