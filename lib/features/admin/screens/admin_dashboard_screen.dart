
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_subscription_requests_screen.dart';
import 'admin_students_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF5F7F5);

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
                Icons.lock_outline,
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                'Manage your academy operations.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              _managementTile(
                icon: Icons.payments_outlined,
                title: 'Subscription Requests',
                subtitle: 'Review student payments and requests',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminSubscriptionRequestsScreen(),
                    ),
                  );
                },
              ),

              _managementTile(
                icon: Icons.people_outline,
                title: 'Student Management',
                subtitle: 'View and search registered students',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStudentsScreen(),
                    ),
                  );
                },
              ),

              _managementTile(
                icon: Icons.menu_book_outlined,
                title: 'Academic Management',
                subtitle: 'Manage years, subjects and topics',
                onTap: () =>
                    _comingSoon(context, 'Academic Management'),
              ),

              _managementTile(
                icon: Icons.video_library_outlined,
                title: 'Learning Resources',
                subtitle: 'Manage notes, PDFs and video lessons',
                onTap: () =>
                    _comingSoon(context, 'Learning Resources'),
              ),

              _managementTile(
                icon: Icons.quiz_outlined,
                title: 'Exams & MCQs',
                subtitle: 'Manage question banks and examinations',
                onTap: () => _comingSoon(context, 'Exams & MCQs'),
              ),

              _managementTile(
                icon: Icons.card_membership_outlined,
                title: 'Subscription Plans',
                subtitle: 'Configure plans and student access',
                onTap: () =>
                    _comingSoon(context, 'Subscription Plans'),
              ),

              _managementTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Send announcements to students',
                onTap: () => _comingSoon(context, 'Notifications'),
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
              Icons.admin_panel_settings_outlined,
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
                Icons.verified_user_outlined,
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: navy.withValues(alpha: 0.045),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 11,
        ),
        leading: Container(
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: navy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: teal,
        ),
        onTap: onTap,
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
