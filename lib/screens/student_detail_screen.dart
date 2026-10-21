import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';
import 'add_student_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _db = DatabaseService();
  late Student _student;
  List<AttendanceRecord> _records = [];
  Map<String, int> _summary = {'total': 0, 'present': 0, 'absent': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final updated = await _db.getStudentById(_student.studentId);
    if (updated != null) _student = updated;
    final records = await _db.getAttendanceByStudent(_student.studentId);
    final summary = await _db.getStudentAttendanceSummary(_student.studentId);
    setState(() {
      _records = records;
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _deleteStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${_student.fullName}? This will also delete all their attendance records.',
          style: const TextStyle(color: Color(0xFFB0B0C8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _student.id != null) {
      await _db.deleteStudent(_student.id!, studentId: _student.studentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_student.fullName} deleted')),
        );
        Navigator.pop(context);
      }
    }
  }

  double get _attendanceRate {
    final total = _summary['total'] ?? 0;
    if (total == 0) return 0.0;
    return (_summary['present'] ?? 0) / total;
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return const Color(0xFF10B981);
    if (rate >= 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final rate = _attendanceRate;
    final rateColor = _rateColor(rate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(student: _student),
                ),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: _deleteStudent,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF4F46E5),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                _student.fullName
                                    .split(' ')
                                    .take(2)
                                    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                    .join(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _student.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Chip(label: _student.studentId, icon: Icons.badge_outlined),
                              const SizedBox(width: 8),
                              _Chip(label: _student.courseYear, icon: Icons.school_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatBox(
                                label: 'Total',
                                value: '${_summary['total']}',
                                color: const Color(0xFF818CF8),
                              ),
                              _StatBox(
                                label: 'Present',
                                value: '${_summary['present']}',
                                color: const Color(0xFF10B981),
                              ),
                              _StatBox(
                                label: 'Absent',
                                value: '${_summary['absent']}',
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Progress bar
                          Row(
                            children: [
                              Text(
                                'Rate: ${(rate * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: rateColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: rate,
                              minHeight: 8,
                              backgroundColor: const Color(0xFF2A2A4A),
                              valueColor: AlwaysStoppedAnimation(rateColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance history
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_records.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No attendance records yet',
                          style: TextStyle(color: Color(0xFF8B8BA7)),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_records.length, (i) {
                      final rec = _records[i];
                      final isPresent = rec.status == 'Present';
                      final dateStr = _formatDate(rec.date);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (isPresent
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPresent ? Icons.check : Icons.close,
                                  color: isPresent
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (rec.subjectName != null || rec.subjectCode != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            if (rec.subjectCode != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                margin: const EdgeInsets.only(right: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED).withAlpha(40),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  rec.subjectCode!,
                                                  style: const TextStyle(
                                                    color: Color(0xFFA78BFA),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            if (rec.subjectName != null)
                                              Flexible(
                                                child: Text(
                                                  rec.subjectName!,
                                                  style: const TextStyle(
                                                    color: Color(0xFF8B8BA7),
                                                    fontSize: 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (rec.remarks != null &&
                                        rec.remarks!.isNotEmpty)
                                      Text(
                                        rec.remarks!,
                                        style: const TextStyle(
                                          color: Color(0xFF8B8BA7),
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isPresent
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  rec.status,
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEEE, MMMM d, y').format(dt);
    } catch (_) {
      return date;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4F46E5).withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF818CF8)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8B8BA7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
