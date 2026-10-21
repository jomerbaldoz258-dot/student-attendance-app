class Subject {
  final int? id;
  final String subjectCode;
  final String subjectName;
  final String? description;
  final String? schedule;
  final String createdAt;

  Subject({
    this.id,
    required this.subjectCode,
    required this.subjectName,
    this.description,
    this.schedule,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_code': subjectCode.trim(),
      'subject_name': subjectName.trim(),
      'description': description?.trim() ?? '',
      'schedule': schedule?.trim() ?? '',
      'created_at': createdAt,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      subjectCode: map['subject_code'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? '',
      description: map['description'] as String?,
      schedule: map['schedule'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Subject copyWith({
    int? id,
    String? subjectCode,
    String? subjectName,
    String? description,
    String? schedule,
    String? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
