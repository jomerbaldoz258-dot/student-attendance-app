import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'student_portal_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _db = DatabaseService();
  final _idCtrl = TextEditingController();
  List<Student> _availableStudents = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableStudents();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStudents() async {
    final list = await _db.getAllStudents();
    if (mounted) {
      setState(() => _availableStudents = list);
    }
  }

  Future<void> _submitLogin([String? studentId]) async {
    final id = (studentId ?? _idCtrl.text).trim();
    if (id.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Student ID');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final student = await _db.getStudentById(id);

    if (!mounted) return;

    if (student == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'Student ID "$id" not found. Check with your teacher.';
      });
      return;
    }

    setState(() => _loading = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentPortalScreen(student: student),
      ),
    );

    // Refresh student list when returning
    _loadAvailableStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Sign-In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Student Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to view your attendance history and sign in for today',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B8BA7), fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Student ID Input
              const Text(
                'STUDENT ID',
                style: TextStyle(
                  color: Color(0xFFB0B0C8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. 2024-001',
                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF8B8BA7)),
                  suffixIcon: _idCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF8B8BA7)),
                          onPressed: () {
                            _idCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
                onSubmitted: (_) => _submitLogin(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _submitLogin(),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login),
                  label: const Text(
                    'Access My Dashboard',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Quick select chips if students are enrolled
              if (_availableStudents.isNotEmpty) ...[
                const SizedBox(height: 36),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF2A2A4A))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR QUICK SELECT ENROLLED STUDENT',
                        style: TextStyle(color: Color(0xFF8B8BA7), fontSize: 11),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF2A2A4A))),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableStudents.map((s) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          s.fullName.isNotEmpty ? s.fullName[0] : 'S',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      label: Text('${s.fullName} (${s.studentId})'),
                      backgroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(color: Color(0xFF2A2A4A)),
                      labelStyle: const TextStyle(color: Color(0xFFB0B0C8), fontSize: 12),
                      onPressed: () {
                        _idCtrl.text = s.studentId;
                        _submitLogin(s.studentId);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
