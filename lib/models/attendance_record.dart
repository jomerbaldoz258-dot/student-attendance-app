class AttendanceRecord {
  final int? id;
  final String date; // Format: YYYY-MM-DD
  final String studentId;
  final String? studentName;
  final String? courseYear;
  final String status; // 'Present' or 'Absent'
  final String? remarks;
  final String createdAt;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;

  AttendanceRecord({
    this.id,
    required this.date,
    required this.studentId,
    this.studentName,
    this.courseYear,
    required this.status,
    this.remarks,
    String? createdAt,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'student_id': studentId,
      'status': status,
      'remarks': remarks ?? '',
      'created_at': createdAt,
      if (subjectId != null) 'subject_id': subjectId,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      studentName: map['full_name'] as String?,
      courseYear: map['course_year'] as String?,
      status: map['status'] as String? ?? 'Absent',
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      subjectId: map['subject_id'] as int?,
      subjectName: map['subject_name'] as String?,
      subjectCode: map['subject_code'] as String?,
    );
  }

  AttendanceRecord copyWith({
    int? id,
    String? date,
    String? studentId,
    String? studentName,
    String? courseYear,
    String? status,
    String? remarks,
    String? createdAt,
    int? subjectId,
    String? subjectName,
    String? subjectCode,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseYear: courseYear ?? this.courseYear,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
    );
  }
}

class AttendanceSession {
  final String date;
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;

  AttendanceSession({
    required this.date,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
  });

  double get attendancePercentage {
    if (totalCount == 0) return 0.0;
    return (presentCount / totalCount) * 100.0;
  }
}
