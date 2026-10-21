import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student; // non-null = edit mode
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _db = DatabaseService();
  bool _saving = false;

  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _idCtrl.text = widget.student!.studentId;
      _nameCtrl.text = widget.student!.fullName;
      _courseCtrl.text = widget.student!.courseYear;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (_isEdit) {
        final updated = widget.student!.copyWith(
          studentId: _idCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          courseYear: _courseCtrl.text.trim(),
        );
        await _db.updateStudent(updated);
      } else {
        final existing = await _db.getStudentById(_idCtrl.text.trim());
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A student with this ID already exists!'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }
        final student = Student(
          studentId: _idCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          courseYear: _courseCtrl.text.trim(),
        );
        await _db.insertStudent(student);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Student updated!' : 'Student added!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Student' : 'Add Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isEdit ? 'Edit Student Details' : 'New Student',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in the details below',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B8BA7), fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Student ID
              _FieldLabel(label: 'Student ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. 2024-00123',
                  prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF8B8BA7)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Student ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Full Name
              _FieldLabel(label: 'Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Juan dela Cruz',
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8B8BA7)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Full name is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Course & Year
              _FieldLabel(label: 'Course & Year'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _courseCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. BSCS-3A',
                  prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF8B8BA7)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Course & Year is required';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Student' : 'Add Student',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFB0B0C8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
