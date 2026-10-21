import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import 'session_detail_screen.dart';

enum _TimeFilter { day, week, month, year, all }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseService();
  List<AttendanceSession> _sessions = [];
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  _TimeFilter _filter = _TimeFilter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndSessions();
  }

  Future<void> _loadSubjectsAndSessions() async {
    final subjects = await _db.getAllSubjects();
    setState(() {
      _subjects = subjects;
    });
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    List<AttendanceSession> sessions;

    switch (_filter) {
      case _TimeFilter.day:
        sessions = await _db.getAttendanceSessionsByRange(
          now,
          now,
          subjectId: _selectedSubject?.id,
        );
        break;
      case _TimeFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        sessions = await _db.getAttendanceSessionsByRange(
          weekStart,
          now,
          subjectId: _selectedSubject?.id,
        );
        break;
      case _TimeFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        sessions = await _db.getAttendanceSessionsByRange(
          monthStart,
          now,
          subjectId: _selectedSubject?.id,
        );
        break;
      case _TimeFilter.year:
        final yearStart = DateTime(now.year, 1, 1);
        sessions = await _db.getAttendanceSessionsByRange(
          yearStart,
          now,
          subjectId: _selectedSubject?.id,
        );
        break;
      case _TimeFilter.all:
        sessions = await _db.getAttendanceSessions(
          subjectId: _selectedSubject?.id,
        );
        break;
    }

    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  String _filterLabel(_TimeFilter f) {
    switch (f) {
      case _TimeFilter.day:
        return 'Today';
      case _TimeFilter.week:
        return 'This Week';
      case _TimeFilter.month:
        return 'This Month';
      case _TimeFilter.year:
        return 'This Year';
      case _TimeFilter.all:
        return 'All Time';
    }
  }

  // Summary stats
  int get _totalPresent =>
      _sessions.fold(0, (sum, s) => sum + s.presentCount);
  int get _totalAbsent =>
      _sessions.fold(0, (sum, s) => sum + s.absentCount);
  int get _totalRecords =>
      _sessions.fold(0, (sum, s) => sum + s.totalCount);
  double get _overallRate =>
      _totalRecords == 0 ? 0 : (_totalPresent / _totalRecords) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _TimeFilter.values.map((f) {
                  final active = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _filter = f);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF2A2A4A),
                          ),
                        ),
                        child: Text(
                          _filterLabel(f),
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : const Color(0xFF8B8BA7),
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Subject filter
          if (_subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4A)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Subject?>(
                    value: _selectedSubject,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.expand_more,
                        color: Color(0xFF8B8BA7)),
                    hint: const Text(
                      'All Subjects',
                      style: TextStyle(color: Color(0xFF8B8BA7)),
                    ),
                    items: [
                      const DropdownMenuItem<Subject?>(
                        value: null,
                        child: Text(
                          'All Subjects',
                          style: TextStyle(color: Color(0xFF8B8BA7)),
                        ),
                      ),
                      ..._subjects.map((s) => DropdownMenuItem<Subject?>(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED)
                                        .withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.subjectCode,
                                    style: const TextStyle(
                                      color: Color(0xFFA78BFA),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.subjectName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSubject = val);
                      _load();
                    },
                  ),
                ),
              ),
            ),

          // Summary stats row
          if (!_loading && _sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _MiniStat(
                    label: 'Sessions',
                    value: '${_sessions.length}',
                    color: const Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Present',
                    value: '$_totalPresent',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Absent',
                    value: '$_totalAbsent',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Avg Rate',
                    value: '${_overallRate.toStringAsFixed(0)}%',
                    color: const Color(0xFFFBBF24),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Sessions list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4F46E5).withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history,
                                  color: Color(0xFF4F46E5), size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No attendance records',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try a different filter or take attendance',
                              style: TextStyle(
                                  color: Color(0xFF8B8BA7), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF4F46E5),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final session = _sessions[i];
                            return _SessionCard(
                              session: session,
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
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Widget ─────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              label,
              style:
                  const TextStyle(color: Color(0xFF8B8BA7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rate = session.attendancePercentage;
    final rateColor = rate >= 80
        ? const Color(0xFF10B981)
        : rate >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    String dateLabel;
    try {
      final dt = DateTime.parse(session.date);
      dateLabel = DateFormat('EEEE, MMMM d, y').format(dt);
    } catch (_) {
      dateLabel = session.date;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date block
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4F46E5).withAlpha(60)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayNum(session.date),
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _month(session.date),
                      style: const TextStyle(
                          color: Color(0xFF8B8BA7), fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (session.subjectName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.subjectCode ?? '',
                              style: const TextStyle(
                                color: Color(0xFFA78BFA),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.subjectName!,
                              style: const TextStyle(
                                  color: Color(0xFF8B8BA7), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Mini(
                          label: '${session.presentCount} P',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        _Mini(
                          label: '${session.absentCount} A',
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        _Mini(
                          label: '${session.totalCount} Total',
                          color: const Color(0xFF818CF8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate / 100,
                        minHeight: 5,
                        backgroundColor: const Color(0xFF2A2A4A),
                        valueColor: AlwaysStoppedAnimation(rateColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: rateColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF8B8BA7), size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayNum(String date) {
    try {
      return DateTime.parse(date).day.toString();
    } catch (_) {
      return '--';
    }
  }

  String _month(String date) {
    try {
      return DateFormat('MMM').format(DateTime.parse(date));
    } catch (_) {
      return '';
    }
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final Color color;
  const _Mini({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
