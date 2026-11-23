import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/device_security_service.dart';

import '../../admin/screens/admin_dashboard_screen.dart';
import '../../dashboard/screens/student_dashboard_screen.dart';
import 'auth_landing_screen.dart';
import 'email_verification_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  String? _deviceRegisteredUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _validateBoundDevice();
  }

  Future<void> _validateBoundDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _deviceRegisteredUid != user.uid) return;
    try {
      await DeviceSecurityService().validateCurrentDevice();
    } on DeviceSecurityException catch (error) {
      if (error.replaced && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // A temporary network failure must not sign out a legitimate student.
    }
  }
  int _retryCount = 0;

  void _retry() {
    if (!mounted) return;

    setState(() {
      _retryCount++;
    });
  }

  Future<Widget> _resolveScreen(User user) async {
    // Refresh the Firebase user before checking account status.
    await user.reload();

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser == null) {
      return const AuthLandingScreen();
    }

    // Email verification is required for all accounts.
    if (!refreshedUser.emailVerified) {
      return EmailVerificationScreen(
        email: refreshedUser.email,
      );
    }

    // Check the trusted Firebase custom claim.
    // Never grant administrator access using a Firestore role field.
    final tokenResult = await refreshedUser.getIdTokenResult(true);

    if (tokenResult.claims?['admin'] == true) {
      return const AdminDashboardScreen();
    }

    // Bind each student account to one app installation. Admins are exempt.
    await DeviceSecurityService().registerCurrentDevice();
    _deviceRegisteredUid = refreshedUser.uid;

    // Non-admin accounts follow the student access flow.
    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshedUser.uid)
        .get();

    if (!document.exists) {
      return const AuthLandingScreen();
    }

    // A verified student profile is sufficient for portal entry.
    // Registration approval is not part of the student onboarding flow.
    // Verified students can enter the dashboard immediately; paid content
    // remains protected by Firestore's active-membership security rules.
    return const StudentDashboardScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (authSnapshot.hasError) {
          return _ErrorScreen(onRetry: _retry);
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthLandingScreen();
        }

        return FutureBuilder<Widget>(
          key: ValueKey('${user.uid}_$_retryCount'),
          future: _resolveScreen(user),
          builder: (context, screenSnapshot) {
            if (screenSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (screenSnapshot.hasError) {
              return _ErrorScreen(onRetry: _retry);
            }

            return screenSnapshot.data ??
                const AuthLandingScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection '
                'and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
