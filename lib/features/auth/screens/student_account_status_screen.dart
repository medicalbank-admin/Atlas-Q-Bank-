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

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
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
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AtlasColors.deepTeal,
          ),
        ),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Status'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: AtlasColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
    final accountStatus =
        (profile['accountStatus'] ?? 'pending').toString();
    final subscriptionStatus =
        (profile['subscriptionStatus'] ?? 'inactive').toString();
    final accessEnabled = profile['accessEnabled'] == true;
    final emailVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    final isApproved = accountStatus == 'approved';
    final isRejected = accountStatus == 'rejected';
    final isActive = subscriptionStatus == 'active';

    final Color statusColor = isRejected
        ? AtlasColors.error
        : isApproved && isActive && accessEnabled
            ? AtlasColors.success
            : AtlasColors.gold;

    final String heading = isRejected
        ? 'Registration Rejected'
        : !emailVerified
            ? 'Verify Your Email'
            : !isApproved
                ? 'Application Under Review'
                : !isActive
                    ? 'Membership Required'
                    : !accessEnabled
                        ? 'Access Not Yet Enabled'
                        : 'Account Approved';

    final String description = isRejected
        ? 'Your registration has been reviewed but was not approved. '
            'Please contact the academy administration for assistance.'
        : !emailVerified
            ? 'Please verify your email address to continue.'
            : !isApproved
                ? 'Your student registration is awaiting approval '
                    'from The Atlas Academy administration.'
                : !isActive
                    ? 'Your account has been approved. Choose or renew '
                        'a membership plan to access learning materials.'
                    : !accessEnabled
                        ? 'Your membership is active, but the academy '
                            'has not enabled your learning access yet.'
                        : 'Your account is approved and your learning '
                            'access is enabled.';

    final canAccess = emailVerified &&
        isApproved &&
        isActive &&
        accessEnabled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Account Status'),
        actions: [
          IconButton(
            onPressed: _loadStatus,
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        color: AtlasColors.deepTeal,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AtlasColors.deepTeal,
                    AtlasColors.oceanTeal,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THE ATLAS ACADEMY',
                    style: TextStyle(
                      color: AtlasColors.champagne,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome, ${profile['fullName'] ?? 'Student'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your medical learning journey starts here.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canAccess
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          color: AtlasColors.champagne,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          canAccess
                              ? 'LEARNING ACCESS ENABLED'
                              : 'ACCOUNT STATUS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRejected
                            ? Icons.cancel_rounded
                            : canAccess
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                        color: statusColor,
                        size: 27,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          heading,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Registration Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _DetailTile(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              value: profile['fullName']?.toString() ?? 'Not available',
            ),
            _DetailTile(
              icon: Icons.email_outlined,
              label: 'Email',
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
            Text(
              'Account Checklist',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _ChecklistTile(
              title: 'Email Verification',
              completed: emailVerified,
            ),
            _ChecklistTile(
              title: 'Registration Approval',
              completed: isApproved,
            ),
            _ChecklistTile(
              title: 'Active Membership',
              completed: isActive,
            ),
            _ChecklistTile(
              title: 'Learning Access',
              completed: accessEnabled,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Account Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtlasColors.deepTeal,
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
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: AtlasColors.oceanTeal,
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AtlasColors.secondaryText,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: completed
                ? AtlasColors.success
                : AtlasColors.secondaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            completed ? 'Complete' : 'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: completed
                  ? AtlasColors.success
                  : AtlasColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
