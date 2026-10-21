import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'student_attendance.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        course_year TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_code TEXT NOT NULL UNIQUE,
        subject_name TEXT NOT NULL,
        description TEXT,
        schedule TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        student_id TEXT NOT NULL,
        status TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL,
        subject_id INTEGER,
        FOREIGN KEY (student_id) REFERENCES students (student_id),
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add subjects table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subjects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_code TEXT NOT NULL UNIQUE,
          subject_name TEXT NOT NULL,
          description TEXT,
          schedule TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Add subject_id column to attendance
      await db.execute(
          'ALTER TABLE attendance ADD COLUMN subject_id INTEGER REFERENCES subjects(id)');
    }
  }

  // ─── Subject CRUD ────────────────────────────────────────────────────────────

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'subject_name ASC');
    return maps.map(Subject.fromMap).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final maps = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Subject.fromMap(maps.first);
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    // Nullify subject_id in attendance records
    await db.update(
      'attendance',
      {'subject_id': null},
      where: 'subject_id = ?',
      whereArgs: [id],
    );
    return db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Student CRUD ───────────────────────────────────────────────────────────

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final maps = await db.query('students', orderBy: 'full_name ASC');
    return maps.map(Student.fromMap).toList();
  }

  Future<Student?> getStudentById(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id, {String? studentId}) async {
    final db = await database;
    if (studentId != null && studentId.isNotEmpty) {
      await db.delete('attendance', where: 'student_id = ?', whereArgs: [studentId]);
    } else {
      final s = await db.query('students', where: 'id = ?', whereArgs: [id]);
      if (s.isNotEmpty) {
        final sid = s.first['student_id'] as String?;
        if (sid != null) {
          await db.delete('attendance', where: 'student_id = ?', whereArgs: [sid]);
        }
      }
    }
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Attendance CRUD ─────────────────────────────────────────────────────────

  Future<int> insertAttendance(AttendanceRecord record) async {
    final db = await database;
    return db.insert(
      'attendance',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceByDate(String date, {int? subjectId}) async {
    final db = await database;
    String query = '''
      SELECT a.*, s.full_name, s.course_year,
             sub.subject_name, sub.subject_code
      FROM attendance a
      LEFT JOIN students s ON a.student_id = s.student_id
      LEFT JOIN subjects sub ON a.subject_id = sub.id
      WHERE a.date = ?
    ''';
    List<dynamic> args = [date];
    if (subjectId != null) {
      query += ' AND a.subject_id = ?';
      args.add(subjectId);
    }
    query += ' ORDER BY s.full_name ASC';
    final maps = await db.rawQuery(query, args);
    return maps.map(AttendanceRecord.fromMap).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByStudent(String studentId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT a.*, s.full_name, s.course_year,
             sub.subject_name, sub.subject_code
      FROM attendance a
      LEFT JOIN students s ON a.student_id = s.student_id
      LEFT JOIN subjects sub ON a.subject_id = sub.id
      WHERE a.student_id = ?
      ORDER BY a.date DESC
    ''', [studentId]);
    return maps.map(AttendanceRecord.fromMap).toList();
  }

  /// Get attendance sessions grouped by date (and optionally subject)
  Future<List<AttendanceSession>> getAttendanceSessions({int? subjectId}) async {
    final db = await database;
    String query = '''
      SELECT 
        a.date,
        a.subject_id,
        sub.subject_name,
        sub.subject_code,
        COUNT(*) as total_count,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) as present_count,
        SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) as absent_count
      FROM attendance a
      LEFT JOIN subjects sub ON a.subject_id = sub.id
    ''';
    List<dynamic> args = [];
    if (subjectId != null) {
      query += ' WHERE a.subject_id = ?';
      args.add(subjectId);
    }
    query += ' GROUP BY a.date, a.subject_id ORDER BY a.date DESC';

    final maps = await db.rawQuery(query, args);

    return maps
        .map((m) => AttendanceSession(
              date: m['date'] as String,
              totalCount: (m['total_count'] as num?)?.toInt() ?? 0,
              presentCount: (m['present_count'] as num?)?.toInt() ?? 0,
              absentCount: (m['absent_count'] as num?)?.toInt() ?? 0,
              subjectId: m['subject_id'] as int?,
              subjectName: m['subject_name'] as String?,
              subjectCode: m['subject_code'] as String?,
            ))
        .toList();
  }

  /// Get sessions filtered by date range
  Future<List<AttendanceSession>> getAttendanceSessionsByRange(
      DateTime start, DateTime end, {int? subjectId}) async {
    final db = await database;
    final startStr = '${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}';

    String query = '''
      SELECT 
        a.date,
        a.subject_id,
        sub.subject_name,
        sub.subject_code,
        COUNT(*) as total_count,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) as present_count,
        SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) as absent_count
      FROM attendance a
      LEFT JOIN subjects sub ON a.subject_id = sub.id
      WHERE a.date >= ? AND a.date <= ?
    ''';
    List<dynamic> args = [startStr, endStr];
    if (subjectId != null) {
      query += ' AND a.subject_id = ?';
      args.add(subjectId);
    }
    query += ' GROUP BY a.date, a.subject_id ORDER BY a.date DESC';

    final maps = await db.rawQuery(query, args);
    return maps
        .map((m) => AttendanceSession(
              date: m['date'] as String,
              totalCount: (m['total_count'] as num?)?.toInt() ?? 0,
              presentCount: (m['present_count'] as num?)?.toInt() ?? 0,
              absentCount: (m['absent_count'] as num?)?.toInt() ?? 0,
              subjectId: m['subject_id'] as int?,
              subjectName: m['subject_name'] as String?,
              subjectCode: m['subject_code'] as String?,
            ))
        .toList();
  }

  Future<int> updateAttendance(AttendanceRecord record) async {
    final db = await database;
    return db.update(
      'attendance',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<bool> hasAttendanceForDate(String date, {int? subjectId}) async {
    final db = await database;
    String query = 'SELECT COUNT(*) as count FROM attendance WHERE date = ?';
    List<dynamic> args = [date];
    if (subjectId != null) {
      query += ' AND subject_id = ?';
      args.add(subjectId);
    }
    final result = await db.rawQuery(query, args);
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    return count > 0;
  }

  Future<int> deleteAttendanceByDate(String date, {int? subjectId}) async {
    final db = await database;
    if (subjectId != null) {
      return db.delete('attendance',
          where: 'date = ? AND subject_id = ?', whereArgs: [date, subjectId]);
    }
    return db.delete('attendance', where: 'date = ?', whereArgs: [date]);
  }

  /// Saves a full list of attendance records for a date (upsert by student+date+subject).
  Future<void> saveAttendanceForDate(
      String date, List<AttendanceRecord> records, {int? subjectId}) async {
    final db = await database;
    final batch = db.batch();

    // Delete existing records for that date (and subject if specified)
    if (subjectId != null) {
      batch.delete('attendance',
          where: 'date = ? AND subject_id = ?', whereArgs: [date, subjectId]);
    } else {
      batch.delete('attendance', where: 'date = ?', whereArgs: [date]);
    }

    for (final record in records) {
      batch.insert('attendance', record.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> getStudentAttendanceSummary(String studentId, {int? subjectId}) async {
    final db = await database;
    String query = '''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) as present,
        SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END) as absent
      FROM attendance
      WHERE student_id = ?
    ''';
    List<dynamic> args = [studentId];
    if (subjectId != null) {
      query += ' AND subject_id = ?';
      args.add(subjectId);
    }
    final result = await db.rawQuery(query, args);

    final row = result.first;
    return {
      'total': (row['total'] as num?)?.toInt() ?? 0,
      'present': (row['present'] as num?)?.toInt() ?? 0,
      'absent': (row['absent'] as num?)?.toInt() ?? 0,
    };
  }

  Future<AttendanceRecord?> getStudentAttendanceForDate(
      String studentId, String date, {int? subjectId}) async {
    final db = await database;
    String where = 'student_id = ? AND date = ?';
    List<dynamic> whereArgs = [studentId, date];
    if (subjectId != null) {
      where += ' AND subject_id = ?';
      whereArgs.add(subjectId);
    }
    final maps = await db.query(
      'attendance',
      where: where,
      whereArgs: whereArgs,
    );
    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  Future<void> recordStudentSelfCheckIn(String studentId, String date,
      {String? remarks}) async {
    final db = await database;
    final existing = await db.query(
      'attendance',
      where: 'student_id = ? AND date = ?',
      whereArgs: [studentId, date],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'attendance',
        {
          'status': 'Present',
          'remarks': remarks ?? 'Student Self Check-in',
          'created_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('attendance', {
        'date': date,
        'student_id': studentId,
        'status': 'Present',
        'remarks': remarks ?? 'Student Self Check-in',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
