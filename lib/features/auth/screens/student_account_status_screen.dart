import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../services/student_auth_service.dart';
class StudentAccountStatusScreen extends StatefulWidget {
  const StudentAccountStatusScreen({super.key});
  @override
  State<StudentAccountStatusScreen> createState() =>
      _StudentAccountStatusScreenState();
}
class _StudentAccountStatusScreenState
    extends State<StudentAccountStatusScreen> {
  final StudentAuthService _authService = StudentAuthService();
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }
  Future<void> _loadStatus() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in to view your account.');
      }
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        throw Exception('Your session has ended. Please sign in again.');
      }
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();
      if (!document.exists) {
        throw Exception('Your student profile could not be found.');
      }
      if (!mounted) return;
      setState(() {
        _profile = document.data();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        AtlasFeedback.showError(
          context,
          'Unable to sign out. Please try again.',
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: const Color(0xFFF2F7FF),
        body: Center(
          child: CircularProgressIndicator(
            color: AtlasColors.royalBlue,
          ),
        ),
      );
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F7FF),
        appBar: AppBar(title: const Text('Account Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 55,
                  color: AtlasColors.error,
                ),
                const SizedBox(height: 17),
                Text(
                  _error ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loadStatus,
                  child: const Text('Try Again'),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final profile = _profile!;
    final subscriptionStatus =
        (profile['subscriptionStatus'] ?? 'inactive').toString();
    final accessEnabled = profile['accessEnabled'] == true;
    final emailVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    final isActive = subscriptionStatus == 'active';
    final canAccess = emailVerified && isActive && accessEnabled;
    final statusColor = canAccess
        ? AtlasColors.success
        : AtlasColors.gold;
    final heading = !emailVerified
        ? 'Verify Your Email'
        : !isActive
            ? 'Membership Required'
            : !accessEnabled
                ? 'Membership Activation Pending'
                : 'Learning Access Enabled';
    final description = !emailVerified
        ? 'Please verify your email address to continue.'
        : !isActive
            ? 'Your student account is ready. Choose a membership plan to unlock the learning materials and examinations.'
            : !accessEnabled
                ? 'Your membership is being activated. Learning content will become available as soon as activation is complete.'
                : 'Your membership is active and your learning access is enabled.';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text('Account Status'),
        actions: [
          IconButton(
            onPressed: _loadStatus,
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        color: AtlasColors.royalBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
          children: [
            // Academy identity card
            Container(
              padding: const EdgeInsets.all(23),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AtlasColors.navy,
                    AtlasColors.royalBlue,
                    AtlasColors.brightBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AtlasColors.navy.withValues(alpha: 0.17),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: AtlasColors.royalBlue,
                        size: 25,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'THE ATLAS ACADEMY',
                        style: TextStyle(
                          color: AtlasColors.royalBlue,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Welcome, ${profile['fullName'] ?? 'Student'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Your medical learning journey starts here.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 23),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canAccess
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          color: AtlasColors.royalBlue,
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          canAccess
                              ? 'LEARNING ACCESS ENABLED'
                              : 'ACCOUNT STATUS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            // Current status
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 43,
                        width: 43,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          canAccess
                              ? Icons.check_circle_rounded
                              : Icons.info_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          heading,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const _SectionTitle(
              title: 'Registration Details',
              subtitle: 'Your registered student information',
            ),
            const SizedBox(height: 14),
            _DetailTile(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              value: profile['fullName']?.toString() ?? 'Not available',
            ),
            _DetailTile(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: profile['email']?.toString() ?? 'Not available',
            ),
            _DetailTile(
              icon: Icons.flag_outlined,
              label: 'Country of Study',
              value: profile['countryOfStudy']?.toString() ??
                  'Not available',
            ),
            _DetailTile(
              icon: Icons.account_balance_outlined,
              label: 'University',
              value: profile['university']?.toString() ??
                  'Not available',
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Account Checklist',
              subtitle: 'Requirements for accessing your learning portal',
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                children: [
                  _ChecklistTile(
                    title: 'Email Verification',
                    completed: emailVerified,
                  ),
                  const Divider(height: 23, color: AtlasColors.border),
                  _ChecklistTile(
                    title: 'Active Membership',
                    completed: isActive,
                  ),
                  const Divider(height: 23, color: AtlasColors.border),
                  _ChecklistTile(
                    title: 'Learning Access',
                    completed: canAccess,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 53,
              child: ElevatedButton.icon(
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text(
                  'Refresh Account Status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtlasColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              style: TextButton.styleFrom(
                foregroundColor: AtlasColors.secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'THE ATLAS ACADEMY  •  EXCELLENCE IN MEDICAL EDUCATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 8,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE0EAF5)),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AtlasColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0EAF5)),
      ),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: AtlasColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AtlasColors.royalBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AtlasColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AtlasColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.title,
    required this.completed,
  });
  final String title;
  final bool completed;
  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AtlasColors.success
        : AtlasColors.secondaryText;
    return Row(
      children: [
        Icon(
          completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 21,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AtlasColors.charcoal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          completed ? 'Complete' : 'Pending',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
