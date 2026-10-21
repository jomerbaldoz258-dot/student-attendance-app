import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_attendance_app/main.dart';

void main() {
  testWidgets('App renders home screen with navigation items', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentAttendanceApp());

    // Verify app starts and renders title
    expect(find.text('Dashboard'), findsWidgets);

    // Verify bottom navigation items exist
    expect(find.text('Students'), findsWidgets);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('History'), findsWidgets);

    // Verify icons
    expect(find.byIcon(Icons.dashboard_outlined), findsNothing); // Active item uses Icons.dashboard
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    expect(find.byIcon(Icons.history_outlined), findsOneWidget);
  });
}
