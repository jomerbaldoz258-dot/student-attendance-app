import 'package:flutter_test/flutter_test.dart';
import 'package:student_attendance_app/models/student.dart';

void main() {
  group('Student Model Tests', () {
    test('creates a Student with correct fields and default createdAt', () {
      final student = Student(
        studentId: '2024-001',
        fullName: 'Jane Doe',
        courseYear: 'BSIT-3A',
      );

      expect(student.id, isNull);
      expect(student.studentId, '2024-001');
      expect(student.fullName, 'Jane Doe');
      expect(student.courseYear, 'BSIT-3A');
      expect(student.createdAt, isNotEmpty);
    });

    test('toMap() trims strings and omits id if null', () {
      final student = Student(
        studentId: '  2024-002  ',
        fullName: '  John Smith  ',
        courseYear: '  BSCS-2B  ',
        createdAt: '2026-10-20T10:00:00Z',
      );

      final map = student.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['student_id'], '2024-002');
      expect(map['full_name'], 'John Smith');
      expect(map['course_year'], 'BSCS-2B');
      expect(map['created_at'], '2026-10-20T10:00:00Z');
    });

    test('toMap() includes id when present', () {
      final student = Student(
        id: 42,
        studentId: '2024-003',
        fullName: 'Alice Walker',
        courseYear: 'BSEMC-1A',
      );

      final map = student.toMap();

      expect(map['id'], 42);
      expect(map['student_id'], '2024-003');
    });

    test('fromMap() correctly constructs Student instance', () {
      final map = {
        'id': 101,
        'student_id': '2024-101',
        'full_name': 'Robert Langdon',
        'course_year': 'BSIS-4A',
        'created_at': '2026-09-01T08:00:00Z',
      };

      final student = Student.fromMap(map);

      expect(student.id, 101);
      expect(student.studentId, '2024-101');
      expect(student.fullName, 'Robert Langdon');
      expect(student.courseYear, 'BSIS-4A');
      expect(student.createdAt, '2026-09-01T08:00:00Z');
    });

    test('copyWith() updates only specified fields', () {
      final original = Student(
        id: 1,
        studentId: '2024-001',
        fullName: 'Original Name',
        courseYear: 'BSIT-1A',
        createdAt: '2026-01-01',
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        courseYear: 'BSIT-2A',
      );

      expect(updated.id, 1);
      expect(updated.studentId, '2024-001');
      expect(updated.fullName, 'Updated Name');
      expect(updated.courseYear, 'BSIT-2A');
      expect(updated.createdAt, '2026-01-01');
    });
  });
}
