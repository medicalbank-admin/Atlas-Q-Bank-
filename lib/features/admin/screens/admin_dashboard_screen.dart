import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_academic_screen.dart';
import 'admin_mcq_bank_screen.dart';
import 'admin_students_screen.dart';
import 'admin_subscription_plans_screen.dart';
import 'admin_subscription_requests_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  Future<bool> _isAuthorizedAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthorizedAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: ivory,
            body: Center(
              child: CircularProgressIndicator(color: teal),
            ),
          );
        }

        if (snapshot.data != true) {
          return _accessDenied(context);
        }

        return _dashboard(context);
      },
    );
  }

  Widget _accessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 65,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Administrator Access Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account does not have administrator permission.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Atlas Administration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 28 : 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcomeBanner(),

                      const SizedBox(height: 28),

                      const Text(
                        'Management Centre',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Manage your academy from one place.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 18),

                      GridView.count(
                        crossAxisCount: isWide ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isWide ? 3.0 : 3.5,
                        children: [
                          _managementTile(
                            icon: Icons.people_alt_rounded,
                            title: 'Student Management',
                            subtitle:
                                'View and search registered students',
                            onTap: () => _openPage(
                              context,
                              const AdminStudentsScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.payments_rounded,
                            title: 'Subscription Requests',
                            subtitle:
                                'Review student payments and requests',
                            onTap: () => _openPage(
                              context,
                              const AdminSubscriptionRequestsScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Subscription Plans',
                            subtitle:
                                'Create plans, set prices and manage access',
                            onTap: () => _openPage(
                              context,
                              const AdminSubscriptionPlansScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.school_rounded,
                            title: 'Academic Management',
                            subtitle:
                                'Manage academic years, subjects and topics',
                            onTap: () => _openPage(
                              context,
                              const AdminAcademicScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.video_library_rounded,
                            title: 'Learning Resources',
                            subtitle:
                                'Manage notes, PDFs and videos through topics',
                            onTap: () => _openPage(
                              context,
                              const AdminAcademicScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.quiz_rounded,
                            title: 'MCQ Question Bank',
                            subtitle:
                                'Create, edit, publish and bulk import MCQs',
                            onTap: () => _openPage(
                              context,
                              const AdminMcqBankScreen(),
                            ),
                          ),

                          _managementTile(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notifications',
                            subtitle:
                                'Student announcements and alerts',
                            onTap: () => _showComingSoon(
                              context,
                              'Notifications',
                            ),
                          ),

                          _managementTile(
                            icon: Icons.analytics_rounded,
                            title: 'Analytics & Reports',
                            subtitle:
                                'Student activity and academy performance',
                            onTap: () => _showComingSoon(
                              context,
                              'Analytics & Reports',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 45,
                              height: 3,
                              decoration: BoxDecoration(
                                color: gold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'THE ATLAS ACADEMY',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Excellence in Medical Education',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _welcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: gold,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome, Administrator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage The Atlas Academy from one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: gold,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                'Administrator Workspace',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: navy.withValues(alpha: 0.045),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: teal,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is planned but not implemented yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of the admin workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
