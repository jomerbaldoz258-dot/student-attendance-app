import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final String date;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;

  const SessionDetailScreen({
    super.key,
    required this.date,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _db = DatabaseService();
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  bool _isEditing = false;
  bool _saving = false;

  // Working state during edit mode
  final Map<String, String> _editedStatus = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await _db.getAttendanceByDate(
      widget.date,
      subjectId: widget.subjectId,
    );

    // Clean up previous controllers
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    _remarksControllers.clear();
    _editedStatus.clear();

    for (final r in records) {
      _editedStatus[r.studentId] = r.status;
      _remarksControllers[r.studentId] =
          TextEditingController(text: r.remarks ?? '');
    }

    setState(() {
      _records = records;
      _loading = false;
      _isEditing = false;
    });
  }

  int get _presentCount {
    if (_isEditing) {
      return _editedStatus.values
          .where((s) => s == 'Present' || s == 'Late')
          .length;
    }
    return _records
        .where((r) => r.status == 'Present' || r.status == 'Late')
        .length;
  }

  int get _absentCount {
    if (_isEditing) {
      return _editedStatus.values.where((s) => s == 'Absent').length;
    }
    return _records.where((r) => r.status == 'Absent').length;
  }

  double get _rate {
    if (_records.isEmpty) return 0;
    return _presentCount / _records.length;
  }

  void _markAll(String status) {
    setState(() {
      for (final key in _editedStatus.keys) {
        _editedStatus[key] = status;
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);

    final updatedRecords = _records.map((r) {
      return AttendanceRecord(
        id: r.id,
        date: r.date,
        studentId: r.studentId,
        status: _editedStatus[r.studentId] ?? r.status,
        remarks: _remarksControllers[r.studentId]?.text.trim(),
        subjectId: r.subjectId ?? widget.subjectId,
        studentName: r.studentName,
        courseYear: r.courseYear,
        subjectName: r.subjectName ?? widget.subjectName,
        subjectCode: r.subjectCode ?? widget.subjectCode,
      );
    }).toList();

    await _db.saveAttendanceForDate(
      widget.date,
      updatedRecords,
      subjectId: widget.subjectId,
    );

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance records updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _load();
    }
  }

  Future<void> _quickEditStudent(AttendanceRecord rec) async {
    String currentStatus = _editedStatus[rec.studentId] ?? rec.status;
    final remarksCtrl =
        TextEditingController(text: rec.remarks ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF818CF8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.studentName ?? rec.studentId,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${rec.studentId}${rec.courseYear != null ? ' • ${rec.courseYear}' : ''}',
                  style: const TextStyle(color: Color(0xFF8B8BA7), fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attendance Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusOption(
                      label: 'Present',
                      selected: currentStatus == 'Present',
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          setModalState(() => currentStatus = 'Present'),
                    ),
                    const SizedBox(width: 8),
                    _statusOption(
                      label: 'Absent',
                      selected: currentStatus == 'Absent',
                      color: const Color(0xFFEF4444),
                      onTap: () =>
                          setModalState(() => currentStatus = 'Absent'),
                    ),
                    const SizedBox(width: 8),
                    _statusOption(
                      label: 'Late',
                      selected: currentStatus == 'Late',
                      color: const Color(0xFFF59E0B),
                      onTap: () =>
                          setModalState(() => currentStatus = 'Late'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Remarks (Optional)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Excused, Medical, Late 15m',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFF0F0E17),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF8B8BA7))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      final updatedRecord = AttendanceRecord(
        id: rec.id,
        date: rec.date,
        studentId: rec.studentId,
        status: currentStatus,
        remarks: remarksCtrl.text.trim(),
        subjectId: rec.subjectId ?? widget.subjectId,
      );

      if (rec.id != null) {
        await _db.updateAttendance(updatedRecord);
      } else {
        await _db.insertAttendance(updatedRecord);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Updated ${rec.studentName ?? rec.studentId} to $currentStatus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _load();
      }
    }
  }

  Widget _statusOption({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(40) : const Color(0xFF0F0E17),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFF2A2A4A),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : const Color(0xFF8B8BA7),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateLabel;
    try {
      dateLabel =
          DateFormat('EEEE, MMMM d, y').format(DateTime.parse(widget.date));
    } catch (_) {
      dateLabel = widget.date;
    }

    final displaySubjectName = widget.subjectName ??
        (_records.isNotEmpty ? _records.first.subjectName : null);
    final displaySubjectCode = widget.subjectCode ??
        (_records.isNotEmpty ? _records.first.subjectCode : null);

    final rateColor = _rate >= 0.8
        ? const Color(0xFF10B981)
        : _rate >= 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Attendance' : 'Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_isEditing) {
              setState(() => _isEditing = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_loading && _records.isNotEmpty)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
                color: _isEditing ? Colors.orangeAccent : const Color(0xFF818CF8),
              ),
              tooltip: _isEditing ? 'Cancel Editing' : 'Edit All Records',
              onPressed: () {
                setState(() => _isEditing = !_isEditing);
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Session',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Delete Session',
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                    'Are you sure you want to delete attendance records for $dateLabel${displaySubjectName != null ? ' ($displaySubjectName)' : ''}? This action cannot be undone.',
                    style: const TextStyle(color: Color(0xFFB0B0C8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _db.deleteAttendanceByDate(
                  widget.date,
                  subjectId: widget.subjectId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Session deleted successfully')),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: _isEditing
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0E17),
                border: Border(
                  top: BorderSide(color: Color(0xFF2A2A4A), width: 1),
                ),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving ? 'Saving Changes...' : 'Save Updated Attendance',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (displaySubjectName != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (displaySubjectCode != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(40),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            displaySubjectCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          displaySubjectName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isEditing ? 'Editing Mode' : 'Recorded',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SummaryItem(
                              label: 'Total', value: '${_records.length}'),
                          _SummaryItem(
                              label: 'Present', value: '$_presentCount'),
                          _SummaryItem(
                              label: 'Absent', value: '$_absentCount'),
                          _SummaryItem(
                            label: 'Rate',
                            value: '${(_rate * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _rate,
                          minHeight: 8,
                          backgroundColor: Colors.white.withAlpha(40),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_records.length} students',
                        style: const TextStyle(
                          color: Color(0xFF8B8BA7),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_isEditing) ...[
                        TextButton.icon(
                          onPressed: () => _markAll('Present'),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16, color: Color(0xFF10B981)),
                          label: const Text('All Present',
                              style: TextStyle(
                                  color: Color(0xFF10B981), fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: () => _markAll('Absent'),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 16, color: Color(0xFFEF4444)),
                          label: const Text('All Absent',
                              style: TextStyle(
                                  color: Color(0xFFEF4444), fontSize: 12)),
                        ),
                      ] else ...[
                        const Text(
                          'Tap a student to edit',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Student list
                Expanded(
                  child: _records.isEmpty
                      ? const Center(
                          child: Text(
                            'No records for this session',
                            style: TextStyle(color: Color(0xFF8B8BA7)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final rec = _records[i];
                            final status = _isEditing
                                ? (_editedStatus[rec.studentId] ?? rec.status)
                                : rec.status;
                            final isPresent =
                                status == 'Present' || status == 'Late';

                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (_isEditing) {
                                    // In edit mode: toggle Present / Absent quickly on tap
                                    setState(() {
                                      _editedStatus[rec.studentId] =
                                          status == 'Present'
                                              ? 'Absent'
                                              : 'Present';
                                    });
                                  } else {
                                    _quickEditStudent(rec);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF4F46E5),
                                              Color(0xFF7C3AED)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (rec.studentName ?? rec.studentId)
                                                .split(' ')
                                                .take(2)
                                                .map((w) => w.isNotEmpty
                                                    ? w[0].toUpperCase()
                                                    : '')
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rec.studentName ?? rec.studentId,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              '${rec.studentId}${rec.courseYear != null ? ' • ${rec.courseYear}' : ''}',
                                              style: const TextStyle(
                                                  color: Color(0xFF8B8BA7),
                                                  fontSize: 12),
                                            ),
                                            if (rec.remarks != null &&
                                                rec.remarks!.isNotEmpty)
                                              Text(
                                                rec.remarks!,
                                                style: const TextStyle(
                                                    color: Color(0xFF8B8BA7),
                                                    fontSize: 12,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_isEditing) ...[
                                        // Edit buttons for this student
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _miniStatusButton(
                                              label: 'P',
                                              isSelected: status == 'Present',
                                              color: const Color(0xFF10B981),
                                              onTap: () {
                                                setState(() {
                                                  _editedStatus[
                                                      rec.studentId] = 'Present';
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            _miniStatusButton(
                                              label: 'A',
                                              isSelected: status == 'Absent',
                                              color: const Color(0xFFEF4444),
                                              onTap: () {
                                                setState(() {
                                                  _editedStatus[
                                                      rec.studentId] = 'Absent';
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            _miniStatusButton(
                                              label: 'L',
                                              isSelected: status == 'Late',
                                              color: const Color(0xFFF59E0B),
                                              onTap: () {
                                                setState(() {
                                                  _editedStatus[
                                                      rec.studentId] = 'Late';
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: (status == 'Present'
                                                    ? const Color(0xFF10B981)
                                                    : status == 'Late'
                                                        ? const Color(0xFFF59E0B)
                                                        : const Color(0xFFEF4444))
                                                .withAlpha(30),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: status == 'Present'
                                                  ? const Color(0xFF10B981)
                                                  : status == 'Late'
                                                      ? const Color(0xFFF59E0B)
                                                      : const Color(0xFFEF4444),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.edit_note,
                                          color: Color(0xFF8B8BA7),
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _miniStatusButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF0F0E17),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A4A),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8B8BA7),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
