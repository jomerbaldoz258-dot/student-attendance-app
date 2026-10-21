import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';

class StudentPortalScreen extends StatefulWidget {
  final Student student;
  const StudentPortalScreen({super.key, required this.student});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final _db = DatabaseService();
  List<AttendanceRecord> _records = [];
  Map<String, int> _summary = {'total': 0, 'present': 0, 'absent': 0};
  AttendanceRecord? _todayRecord;
  bool _loading = true;
  bool _signingIn = false;

  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await _db.getAttendanceByStudent(widget.student.studentId);
    final summary = await _db.getStudentAttendanceSummary(widget.student.studentId);
    final today = await _db.getStudentAttendanceForDate(widget.student.studentId, _todayStr);

    setState(() {
      _records = records;
      _summary = summary;
      _todayRecord = today;
      _loading = false;
    });
  }

  Future<void> _selfCheckIn() async {
    setState(() => _signingIn = true);
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    await _db.recordStudentSelfCheckIn(
      widget.student.studentId,
      _todayStr,
      remarks: 'Signed in at $timeStr',
    );

    if (mounted) {
      setState(() => _signingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance recorded! You are marked Present today.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadData();
    }
  }

  double get _attendanceRate {
    final total = _summary['total'] ?? 0;
    if (total == 0) return 0.0;
    return ((_summary['present'] ?? 0) / total) * 100.0;
  }

  Color _rateColor(double rate) {
    if (rate >= 80) return const Color(0xFF10B981);
    if (rate >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final rate = _attendanceRate;
    final rateColor = _rateColor(rate);
    final todayFormatted = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final isPresentToday = _todayRecord?.status == 'Present';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: Color(0xFF818CF8), size: 22),
            SizedBox(width: 8),
            Text('Student Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Exit'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B8BA7)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4F46E5),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Student Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              widget.student.fullName
                                  .split(' ')
                                  .take(2)
                                  .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                  .join(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.student.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.student.studentId} • ${widget.student.courseYear}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Today's Sign-In Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Today's Attendance",
                                    style: TextStyle(
                                      color: Color(0xFF8B8BA7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    todayFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isPresentToday
                                          ? const Color(0xFF10B981)
                                          : _todayRecord != null
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B))
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPresentToday
                                        ? const Color(0xFF10B981)
                                        : _todayRecord != null
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Text(
                                  isPresentToday
                                      ? 'Present'
                                      : _todayRecord != null
                                          ? 'Absent'
                                          : 'Not Checked In',
                                  style: TextStyle(
                                    color: isPresentToday
                                        ? const Color(0xFF10B981)
                                        : _todayRecord != null
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (!isPresentToday) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _signingIn ? null : _selfCheckIn,
                                icon: _signingIn
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: const Text('Sign Attendance for Today'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified,
                                      color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _todayRecord?.remarks?.isNotEmpty == true
                                          ? _todayRecord!.remarks!
                                          : 'You are signed in for today',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overall Stats
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Attendance Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _SummaryStat(
                                label: 'Total Classes',
                                value: '${_summary['total']}',
                                color: const Color(0xFF818CF8),
                              ),
                              _SummaryStat(
                                label: 'Attended',
                                value: '${_summary['present']}',
                                color: const Color(0xFF10B981),
                              ),
                              _SummaryStat(
                                label: 'Missed',
                                value: '${_summary['absent']}',
                                color: const Color(0xFFEF4444),
                              ),
                              _SummaryStat(
                                label: 'Rate',
                                value: '${rate.toStringAsFixed(0)}%',
                                color: rateColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_summary['total'] ?? 0) > 0 ? (rate / 100) : 0,
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

                  // Attendance History
                  const Text(
                    'My Attendance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_records.isEmpty) ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No attendance records found yet.',
                            style: TextStyle(color: Color(0xFF8B8BA7)),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._records.map((rec) {
                      final isPresent = rec.status == 'Present';
                      String dateDisplay;
                      try {
                        final dt = DateTime.parse(rec.date);
                        dateDisplay = DateFormat('EEEE, MMM d, y').format(dt);
                      } catch (_) {
                        dateDisplay = rec.date;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                isPresent
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color: isPresent
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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
                                    if (rec.remarks?.isNotEmpty == true)
                                      Text(
                                        rec.remarks!,
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
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
                                      .withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  rec.status,
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B8BA7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
