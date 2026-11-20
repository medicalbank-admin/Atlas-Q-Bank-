
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dashboard/screens/student_dashboard_screen.dart';
import 'auth_landing_screen.dart';
import 'email_verification_screen.dart';
import 'student_account_status_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveScreen(User user) async {
    await user.reload();

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser == null) {
      return const AuthLandingScreen();
    }

    if (!refreshedUser.emailVerified) {
      return EmailVerificationScreen(
        email: refreshedUser.email,
      );
    }

    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshedUser.uid)
        .get();

    if (!document.exists) {
      return const AuthLandingScreen();
    }

    final profile = document.data() ?? {};

    final accountApproved =
        profile['accountStatus'] == 'approved';

    final membershipActive =
        profile['subscriptionStatus'] == 'active';

    final accessEnabled =
        profile['accessEnabled'] == true;

    if (accountApproved && membershipActive && accessEnabled) {
      return const StudentDashboardScreen();
    }

    return const StudentAccountStatusScreen();
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

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthLandingScreen();
        }

        return FutureBuilder<Widget>(
          key: ValueKey(user.uid),
          future: _resolveScreen(user),
          builder: (context, screenSnapshot) {
            if (screenSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (screenSnapshot.hasError) {
              return const _ErrorScreen();
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
  const _ErrorScreen();

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
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.currentUser?.reload();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
