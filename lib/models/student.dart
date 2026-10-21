class Student {
  final int? id;
  final String studentId;
  final String fullName;
  final String courseYear;
  final String createdAt;

  Student({
    this.id,
    required this.studentId,
    required this.fullName,
    required this.courseYear,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId.trim(),
      'full_name': fullName.trim(),
      'course_year': courseYear.trim(),
      'created_at': createdAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      studentId: map['student_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      courseYear: map['course_year'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Student copyWith({
    int? id,
    String? studentId,
    String? fullName,
    String? courseYear,
    String? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      courseYear: courseYear ?? this.courseYear,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
