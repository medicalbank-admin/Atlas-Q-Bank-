import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import 'student_login_screen.dart';
import 'student_registration_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentLoginScreen(),
      ),
    );
  }

  void _openRegistration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentRegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        height: 104,
                        width: 104,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AtlasColors.deepTeal,
                              AtlasColors.oceanTeal,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AtlasColors.deepTeal.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AtlasColors.champagne,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'THE ATLAS ACADEMY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AtlasColors.deepTeal,
                          fontSize: 13,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Your Journey to\\nMedical Excellence',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AtlasColors.deepTeal,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Learn smarter. Prepare confidently. '
                        'Achieve your medical career goals with '
                        'expert-guided learning.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AtlasColors.secondaryText,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(21),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AtlasColors.softTeal,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AtlasColors.deepTeal.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const _FeatureRow(
                              icon: Icons.menu_book_rounded,
                              title: 'Structured Medical Learning',
                              subtitle: 'Organised subjects and study resources',
                            ),
                            const SizedBox(height: 20),
                            const _FeatureRow(
                              icon: Icons.quiz_rounded,
                              title: 'Practice and Assessments',
                              subtitle: 'MCQs, exams and performance tracking',
                            ),
                            const SizedBox(height: 20),
                            const _FeatureRow(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Guided Exam Preparation',
                              subtitle: 'Prepare for your chosen medical pathway',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _openRegistration(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AtlasColors.deepTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Create Student Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => _openLogin(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AtlasColors.deepTeal,
                            side: const BorderSide(
                              color: AtlasColors.oceanTeal,
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Already Have an Account? Log In',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'EXCELLENCE IN MEDICAL EDUCATION',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AtlasColors.secondaryText,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
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
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AtlasColors.softTeal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AtlasColors.deepTeal,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AtlasColors.charcoal,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
