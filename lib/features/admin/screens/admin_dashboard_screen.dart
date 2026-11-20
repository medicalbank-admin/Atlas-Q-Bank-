import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_subscription_requests_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);

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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Administrator Access Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your account does not have administrator permission.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _dashboard(context);
      },
    );
  }

  Widget _dashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Atlas Administration',
          style: TextStyle(fontWeight: FontWeight.bold),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navy, teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: gold,
                      size: 36,
                    ),
                    const SizedBox(height: 18),
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
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Management Centre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 16),
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
                subtitle: 'Manage student accounts and approvals',
                onTap: () => _comingSoon(context, 'Student Management'),
              ),
              _managementTile(
                icon: Icons.menu_book_outlined,
                title: 'Academic Management',
                subtitle: 'Manage years, subjects and topics',
                onTap: () => _comingSoon(context, 'Academic Management'),
              ),
              _managementTile(
                icon: Icons.video_library_outlined,
                title: 'Learning Resources',
                subtitle: 'Manage notes, PDFs and video lessons',
                onTap: () => _comingSoon(context, 'Learning Resources'),
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
                onTap: () => _comingSoon(context, 'Subscription Plans'),
              ),
              _managementTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Send announcements to students',
                onTap: () => _comingSoon(context, 'Notifications'),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'THE ATLAS ACADEMY',
                  style: TextStyle(
                    color: navy.withValues(alpha: 0.65),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: teal, size: 25),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
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
      SnackBar(content: Text('$feature will be available soon.')),
    );
  }
}
