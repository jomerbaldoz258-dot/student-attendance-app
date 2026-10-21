import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _db = DatabaseService();
  List<Subject> _subjects = [];
  List<Subject> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _db.getAllSubjects();
    setState(() {
      _subjects = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _subjects.where((s) {
        return s.subjectCode.toLowerCase().contains(q) ||
            s.subjectName.toLowerCase().contains(q) ||
            (s.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _addOrEditSubject({Subject? subject}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => SubjectFormDialog(subject: subject),
    );
    if (result == true) _load();
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Subject', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${subject.subjectName}"?\n\nAttendance records linked to this subject will not be deleted but will lose their subject association.',
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

    if (confirm == true && subject.id != null) {
      await _db.deleteSubject(subject.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${subject.subjectName}" deleted')),
        );
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search subjects…',
                prefixIcon: Icon(Icons.search, color: Color(0xFF8B8BA7)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Count chip
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7C3AED).withAlpha(80)),
                ),
                child: Text(
                  '${_filtered.length} subject${_filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyState(hasSearch: _searchCtrl.text.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF4F46E5),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final subject = _filtered[i];
                            return _SubjectCard(
                              subject: subject,
                              onEdit: () => _addOrEditSubject(subject: subject),
                              onDelete: () => _deleteSubject(subject),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditSubject(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }
}

// ─── Subject Card ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.menu_book, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF7C3AED).withAlpha(80)),
                        ),
                        child: Text(
                          subject.subjectCode,
                          style: const TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject.subjectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subject.description != null &&
                      subject.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subject.description!,
                      style: const TextStyle(
                          color: Color(0xFF8B8BA7), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subject.schedule != null &&
                      subject.schedule!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 12, color: Color(0xFF34D399)),
                        const SizedBox(width: 4),
                        Text(
                          subject.schedule!,
                          style: const TextStyle(
                              color: Color(0xFF34D399), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF2A2A4A)),
              ),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          color: Color(0xFF34D399), size: 18),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subject Form Dialog ──────────────────────────────────────────────────────

class SubjectFormDialog extends StatefulWidget {
  final Subject? subject;
  const SubjectFormDialog({super.key, this.subject});

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _schedCtrl;
  final _db = DatabaseService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.subject?.subjectCode ?? '');
    _nameCtrl = TextEditingController(text: widget.subject?.subjectName ?? '');
    _descCtrl = TextEditingController(text: widget.subject?.description ?? '');
    _schedCtrl = TextEditingController(text: widget.subject?.schedule ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _schedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final subject = Subject(
      id: widget.subject?.id,
      subjectCode: _codeCtrl.text.trim(),
      subjectName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      schedule: _schedCtrl.text.trim(),
    );

    try {
      if (widget.subject == null) {
        await _db.insertSubject(subject);
      } else {
        await _db.updateSubject(subject);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Subject' : 'New Subject',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _codeCtrl,
                label: 'Subject Code *',
                hint: 'e.g. MATH101',
                icon: Icons.tag,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Subject code is required' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _nameCtrl,
                label: 'Subject Name *',
                hint: 'e.g. Mathematics',
                icon: Icons.text_fields,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Subject name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _descCtrl,
                label: 'Description (optional)',
                hint: 'Brief description of the subject',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _schedCtrl,
                label: 'Schedule (optional)',
                hint: 'e.g. Mon/Wed 8:00–9:30 AM',
                icon: Icons.schedule,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isEdit ? 'Update' : 'Add Subject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8B8BA7), size: 18),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book,
                color: Color(0xFF7C3AED), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No subjects found' : 'No subjects yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Tap the button below to register a subject',
            style: const TextStyle(color: Color(0xFF8B8BA7), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
