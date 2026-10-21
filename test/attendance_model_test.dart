import 'package:flutter_test/flutter_test.dart';
import 'package:student_attendance_app/models/attendance_record.dart';

void main() {
  group('AttendanceRecord Model Tests', () {
    test('creates AttendanceRecord with valid attributes', () {
      final record = AttendanceRecord(
        date: '2026-10-20',
        studentId: '2024-001',
        status: 'Present',
        remarks: 'On time',
      );

      expect(record.id, isNull);
      expect(record.date, '2026-10-20');
      expect(record.studentId, '2024-001');
      expect(record.status, 'Present');
      expect(record.remarks, 'On time');
      expect(record.createdAt, isNotEmpty);
    });

    test('toMap() formats data correctly for SQLite', () {
      final record = AttendanceRecord(
        id: 5,
        date: '2026-10-20',
        studentId: '2024-002',
        status: 'Absent',
        remarks: 'Sick leave',
        createdAt: '2026-10-20T08:30:00Z',
      );

      final map = record.toMap();

      expect(map['id'], 5);
      expect(map['date'], '2026-10-20');
      expect(map['student_id'], '2024-002');
      expect(map['status'], 'Absent');
      expect(map['remarks'], 'Sick leave');
      expect(map['created_at'], '2026-10-20T08:30:00Z');
    });

    test('fromMap() handles missing remarks with defaults', () {
      final map = {
        'id': 10,
        'date': '2026-10-21',
        'student_id': '2024-003',
        'status': 'Present',
        'full_name': 'Clark Kent',
        'course_year': 'BSIT-4A',
        'created_at': '2026-10-21T09:00:00Z',
      };

      final record = AttendanceRecord.fromMap(map);

      expect(record.id, 10);
      expect(record.date, '2026-10-21');
      expect(record.studentId, '2024-003');
      expect(record.studentName, 'Clark Kent');
      expect(record.courseYear, 'BSIT-4A');
      expect(record.status, 'Present');
      expect(record.remarks, isNull);
    });

    test('copyWith() allows toggling status and remarks', () {
      final original = AttendanceRecord(
        id: 1,
        date: '2026-10-20',
        studentId: '2024-001',
        status: 'Present',
      );

      final updated = original.copyWith(
        status: 'Absent',
        remarks: 'Unexcused',
      );

      expect(updated.id, 1);
      expect(updated.status, 'Absent');
      expect(updated.remarks, 'Unexcused');
    });
  });

  group('AttendanceSession Tests', () {
    test('calculates attendance percentage accurately', () {
      final session = AttendanceSession(
        date: '2026-10-20',
        totalCount: 40,
        presentCount: 30,
        absentCount: 10,
      );

      expect(session.attendancePercentage, 75.0);
    });

    test('returns 0.0 percentage when totalCount is 0', () {
      final emptySession = AttendanceSession(
        date: '2026-10-20',
        totalCount: 0,
        presentCount: 0,
        absentCount: 0,
      );

      expect(emptySession.attendancePercentage, 0.0);
    });

    test('returns 100.0 percentage when all are present', () {
      final perfectSession = AttendanceSession(
        date: '2026-10-20',
        totalCount: 25,
        presentCount: 25,
        absentCount: 0,
      );

      expect(perfectSession.attendancePercentage, 100.0);
    });
  });
}
