import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'subjects_screen.dart';
import 'students_screen.dart';
import 'take_attendance_screen.dart';
import 'history_screen.dart';
import 'student_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    _NavItem(
      label: 'Subjects',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
    ),
    _NavItem(
      label: 'Students',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _NavItem(
      label: 'Attendance',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
    ),
    _NavItem(
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
    ),
  ];

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigate: _onNavigate);
      case 1:
        return const SubjectsScreen();
      case 2:
        return const StudentsScreen();
      case 3:
        return const TakeAttendanceScreen();
      case 4:
        return const HistoryScreen();
      default:
        return DashboardScreen(onNavigate: _onNavigate);
    }
  }

  final List<String> _titles = const [
    'Dashboard',
    'Subjects',
    'Students',
    'Take Attendance',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentLoginScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_pin, size: 18),
              label: const Text('Student View'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF818CF8),
                backgroundColor: const Color(0xFF4F46E5).withAlpha(30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0E17),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A4A), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4F46E5).withAlpha(25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF6B7280),
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF6B7280),
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
