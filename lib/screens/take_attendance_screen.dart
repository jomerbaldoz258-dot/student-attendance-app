import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import 'subjects_screen.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _db = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  Map<String, _AttendanceEntry> _attendanceMap = {};
  bool _loading = true;
  bool _saving = false;
  bool _alreadySaved = false;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    for (final entry in _attendanceMap.values) {
      entry.remarksCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _db.getAllSubjects();
    setState(() {
      _subjects = subjects;
      _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
    });
    await _loadForDate();
  }

  Future<void> _openAddSubjectDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const SubjectFormDialog(),
    );
    if (result == true) {
      final subjects = await _db.getAllSubjects();
      setState(() {
        _subjects = subjects;
        if (subjects.isNotEmpty) {
          _selectedSubject = subjects.last;
        }
      });
      _loadForDate();
    }
  }

  Future<void> _loadForDate() async {
    for (final entry in _attendanceMap.values) {
      entry.remarksCtrl.dispose();
    }
    setState(() => _loading = true);
    final dateStr = _dateStr(_selectedDate);

    final students = await _db.getAllStudents();
    final existingRecords = await _db.getAttendanceByDate(
      dateStr,
      subjectId: _selectedSubject?.id,
    );
    final alreadySaved = await _db.hasAttendanceForDate(
      dateStr,
      subjectId: _selectedSubject?.id,
    );

    final map = <String, _AttendanceEntry>{};
    for (final s in students) {
      final existing = existingRecords
          .cast<AttendanceRecord?>()
          .firstWhere((r) => r?.studentId == s.studentId, orElse: () => null);
      map[s.studentId] = _AttendanceEntry(
        status: existing?.status ?? 'Present',
        remarks: existing?.remarks ?? '',
        remarksCtrl: TextEditingController(text: existing?.remarks ?? ''),
        recordId: existing?.id,
      );
    }

    setState(() {
      _students = students;
      _attendanceMap = map;
      _alreadySaved = alreadySaved;
      _loading = false;
    });
  }

  String _dateStr(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4F46E5),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadForDate();
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);

    final dateStr = _dateStr(_selectedDate);
    final records = _students.map((s) {
      final entry = _attendanceMap[s.studentId]!;
      return AttendanceRecord(
        id: entry.recordId,
        date: dateStr,
        studentId: s.studentId,
        status: entry.status,
        remarks: entry.remarksCtrl.text.trim(),
        subjectId: _selectedSubject?.id,
      );
    }).toList();

    await _db.saveAttendanceForDate(
      dateStr,
      records,
      subjectId: _selectedSubject?.id,
    );

    if (mounted) {
      setState(() {
        _saving = false;
        _alreadySaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance saved${_selectedSubject != null ? ' for ${_selectedSubject!.subjectName}' : ''}!',
          ),
        ),
      );
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final entry in _attendanceMap.values) {
        entry.status = status;
      }
    });
  }

  Future<void> _editRemark(Student student, _AttendanceEntry entry) async {
    final ctrl = TextEditingController(text: entry.remarksCtrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.note_alt_outlined,
                color: Color(0xFF818CF8), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Note for ${student.fullName}',
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Excused, Late 10 mins, Medical',
          ),
          autofocus: true,
        ),
        actions: [
          if (entry.remarksCtrl.text.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, '');
              },
              child: const Text('Clear',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        entry.remarks = result;
        entry.remarksCtrl.text = result;
      });
    }
  }

  int get _presentCount =>
      _attendanceMap.values.where((e) => e.status == 'Present').length;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d, y').format(_selectedDate);
    final isToday = _dateStr(_selectedDate) == _dateStr(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          // Date selector header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'Today' : 'Selected Date',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withAlpha(40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),

          // Subject Selector
          if (_subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
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
                            'Select a subject',
                            style: TextStyle(color: Color(0xFF8B8BA7)),
                          ),
                          items: [
                            const DropdownMenuItem<Subject?>(
                              value: null,
                              child: Text(
                                'No Subject (General)',
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
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                            _loadForDate();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF4F46E5).withAlpha(80)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add,
                          color: Color(0xFF818CF8), size: 20),
                      tooltip: 'Register New Subject',
                      onPressed: _openAddSubjectDialog,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFA78BFA), size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No subjects registered yet.',
                        style: TextStyle(
                            color: Color(0xFFA78BFA), fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7C3AED).withAlpha(35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openAddSubjectDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Subject',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          if (!_loading && _students.isNotEmpty) ...[
            // Quick action buttons + stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Present count
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '$_presentCount Present',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _QuickBtn(
                    label: 'All Present',
                    color: const Color(0xFF10B981),
                    onTap: () => _markAll('Present'),
                  ),
                  const SizedBox(width: 6),
                  _QuickBtn(
                    label: 'All Absent',
                    color: const Color(0xFFEF4444),
                    onTap: () => _markAll('Absent'),
                  ),
                ],
              ),
            ),
          ],

          // Student list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_outline,
                                  color: Color(0xFF4F46E5), size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No students enrolled',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add students in the Students tab first',
                              style: TextStyle(
                                  color: Color(0xFF8B8BA7), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final student = _students[i];
                          final entry =
                              _attendanceMap[student.studentId]!;
                          return _AttendanceCard(
                            student: student,
                            entry: entry,
                            onStatusChanged: (status) {
                              setState(() => entry.status = status);
                            },
                            onAddRemark: () =>
                                _editRemark(student, entry),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _students.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _saveAttendance,
              backgroundColor: _alreadySaved
                  ? const Color(0xFF10B981)
                  : const Color(0xFF4F46E5),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(_alreadySaved ? Icons.check : Icons.save_outlined),
              label:
                  Text(_alreadySaved ? 'Update Attendance' : 'Save Attendance'),
            ),
    );
  }
}

class _AttendanceEntry {
  String status;
  String remarks;
  TextEditingController remarksCtrl;
  int? recordId;

  _AttendanceEntry({
    required this.status,
    required this.remarks,
    required this.remarksCtrl,
    this.recordId,
  });
}

class _AttendanceCard extends StatelessWidget {
  final Student student;
  final _AttendanceEntry entry;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onAddRemark;

  const _AttendanceCard({
    required this.student,
    required this.entry,
    required this.onStatusChanged,
    required this.onAddRemark,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == 'Present';
    final hasRemark = entry.remarksCtrl.text.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      student.fullName
                          .split(' ')
                          .take(2)
                          .map((w) =>
                              w.isNotEmpty ? w[0].toUpperCase() : '')
                          .join(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text(
                        '${student.studentId} • ${student.courseYear}',
                        style: const TextStyle(
                            color: Color(0xFF8B8BA7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Remark button
                IconButton(
                  icon: Icon(
                    hasRemark ? Icons.note_alt : Icons.note_add_outlined,
                    color: hasRemark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF6B7280),
                    size: 20,
                  ),
                  tooltip: hasRemark ? 'Edit Note' : 'Add Note',
                  onPressed: onAddRemark,
                ),
                // Toggle
                _StatusToggle(
                  isPresent: isPresent,
                  onChanged: onStatusChanged,
                ),
              ],
            ),
            if (hasRemark) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onAddRemark,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sticky_note_2_outlined,
                          size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          entry.remarksCtrl.text,
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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

class _StatusToggle extends StatelessWidget {
  final bool isPresent;
  final ValueChanged<String> onChanged;

  const _StatusToggle({required this.isPresent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleBtn(
          label: 'P',
          active: isPresent,
          activeColor: const Color(0xFF10B981),
          onTap: () => onChanged('Present'),
        ),
        const SizedBox(width: 6),
        _ToggleBtn(
          label: 'A',
          active: !isPresent,
          activeColor: const Color(0xFFEF4444),
          onTap: () => onChanged('Absent'),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFF0F0E17),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? activeColor : const Color(0xFF2A2A4A),
            width: active ? 0 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF8B8BA7),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
