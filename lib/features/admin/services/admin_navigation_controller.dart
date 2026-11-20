import 'package:flutter/material.dart';

import '../screens/admin_academic_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_students_screen.dart';
import '../screens/admin_subscription_requests_screen.dart';

class AdminNavigationController {
  AdminNavigationController._();

  static Widget buildPage(String route) {
    switch (route) {
      case 'dashboard':
        return AdminDashboardScreen();

      case 'students':
        return AdminStudentsScreen();

      case 'academic':
        return AdminAcademicScreen();

      case 'subscription_requests':
        return AdminSubscriptionRequestsScreen();

      case 'content':
        return const _ComingSoonPage(
          title: 'Learning Content',
          description:
              'Manage medical notes, PDFs, videos and learning resources.',
          icon: Icons.library_books_rounded,
        );

      case 'exams':
        return const _ComingSoonPage(
          title: 'Exams & MCQs',
          description:
              'Manage question banks, examinations and student results.',
          icon: Icons.quiz_rounded,
        );

      case 'plans':
        return const _ComingSoonPage(
          title: 'Subscription Plans',
          description:
              'Configure membership plans, prices and student access.',
          icon: Icons.workspace_premium_rounded,
        );

      case 'notifications':
        return const _ComingSoonPage(
          title: 'Notifications',
          description:
              'Prepare announcements and student notifications.',
          icon: Icons.notifications_active_rounded,
        );

      case 'analytics':
        return const _ComingSoonPage(
          title: 'Analytics & Reports',
          description:
              'Review student activity, subscriptions and academy performance.',
          icon: Icons.analytics_rounded,
        );

      case 'settings':
        return const _ComingSoonPage(
          title: 'Settings',
          description:
              'Manage academy configuration and administration settings.',
          icon: Icons.settings_rounded,
        );

      default:
        return const _ComingSoonPage(
          title: 'Page Not Found',
          description: 'The requested administration page is unavailable.',
          icon: Icons.error_outline_rounded,
        );
    }
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _ComingSoonPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7ECEA)),
          boxShadow: [
            BoxShadow(
              color: deepTeal.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: oceanTeal,
                size: 38,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: deepTeal,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            const Chip(
              label: Text('Module planned'),
              avatar: Icon(Icons.construction_rounded, size: 17),
              backgroundColor: Color(0xFFE5F1EF),
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }
}
