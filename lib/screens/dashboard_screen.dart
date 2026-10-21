import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import 'session_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  int _totalStudents = 0;
  int _totalSubjects = 0;
  int _totalSessions = 0;
  double _overallRate = 0;
  List<AttendanceSession> _recentSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _db.getAllStudents();
    final subjects = await _db.getAllSubjects();
    final sessions = await _db.getAttendanceSessions();

    double totalRate = 0;
    for (final s in sessions) {
      totalRate += s.attendancePercentage;
    }
    final avgRate = sessions.isEmpty ? 0.0 : totalRate / sessions.length;

    setState(() {
      _totalStudents = students.length;
      _totalSubjects = subjects.length;
      _totalSessions = sessions.length;
      _overallRate = avgRate;
      _recentSessions = sessions.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF4F46E5),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome banner
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.white, size: 24),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'v1.0.1',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Student Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Track and manage class attendance with subjects',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stat cards (2 rows of 2 for clean readability)
                  Row(
                    children: [
                      _StatCard(
                        label: 'Students',
                        value: '$_totalStudents',
                        icon: Icons.people_alt_outlined,
                        color: const Color(0xFF818CF8),
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Subjects',
                        value: '$_totalSubjects',
                        icon: Icons.menu_book_outlined,
                        color: const Color(0xFFA78BFA),
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Sessions',
                        value: '$_totalSessions',
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFF34D399),
                        onTap: () => widget.onNavigate?.call(4),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Avg Rate',
                        value: '${_overallRate.toStringAsFixed(0)}%',
                        icon: Icons.trending_up,
                        color: const Color(0xFFFBBF24),
                        onTap: () => widget.onNavigate?.call(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => widget.onNavigate?.call(3),
                          icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 18),
                          label: const Text('Take Attendance'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF818CF8),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => widget.onNavigate?.call(1),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('New Subject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA78BFA),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Overall attendance ring
                  if (_totalSessions > 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overall Attendance Rate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _overallRate / 100,
                                        strokeWidth: 8,
                                        backgroundColor:
                                            const Color(0xFF2A2A4A),
                                        valueColor: AlwaysStoppedAnimation(
                                          _overallRate >= 80
                                              ? const Color(0xFF10B981)
                                              : _overallRate >= 60
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFEF4444),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${_overallRate.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _RateLegend(
                                        color: Color(0xFF10B981),
                                        label: '≥ 80% Excellent',
                                      ),
                                      _RateLegend(
                                        color: Color(0xFFF59E0B),
                                        label: '60–79% Average',
                                      ),
                                      _RateLegend(
                                        color: Color(0xFFEF4444),
                                        label: '< 60% Needs Attention',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recent sessions
                  if (_recentSessions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Sessions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate?.call(4),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._recentSessions.map((session) {
                      final rate = session.attendancePercentage;
                      final rateColor = rate >= 80
                          ? const Color(0xFF10B981)
                          : rate >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionDetailScreen(
                                  date: session.date,
                                  subjectId: session.subjectId,
                                  subjectName: session.subjectName,
                                  subjectCode: session.subjectCode,
                                ),
                              ),
                            );
                            _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: Color(0xFF818CF8), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.date,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      if (session.subjectName != null ||
                                          session.subjectCode != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (session.subjectCode != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1),
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED)
                                                      .withAlpha(30),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  session.subjectCode!,
                                                  style: const TextStyle(
                                                    color: Color(0xFFA78BFA),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            if (session.subjectName != null)
                                              Flexible(
                                                child: Text(
                                                  session.subjectName!,
                                                  style: const TextStyle(
                                                    color: Color(0xFF8B8BA7),
                                                    fontSize: 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${session.presentCount}/${session.totalCount} Present',
                                  style: const TextStyle(
                                      color: Color(0xFF8B8BA7), fontSize: 13),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${rate.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: rateColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Color(0xFF8B8BA7), size: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ] else if (_totalSessions == 0 && _totalStudents > 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                color: Color(0xFF4F46E5), size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Ready to take attendance!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Go to the Attendance tab to record today\'s class',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF8B8BA7), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigate?.call(3),
                              icon: const Icon(Icons.assignment),
                              label: const Text('Take Attendance Now'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_totalStudents == 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.person_add_outlined,
                                color: Color(0xFF4F46E5), size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Get started!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add students and subjects first, then take attendance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF8B8BA7), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigate?.call(2),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Students'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (onTap != null)
                      Icon(Icons.arrow_forward_ios,
                          color: color.withAlpha(100), size: 12),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style:
                      const TextStyle(color: Color(0xFF8B8BA7), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RateLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _RateLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8B8BA7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
