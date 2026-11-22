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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium navy hero section.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(26, 38, 26, 38),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AtlasColors.navy,
                      AtlasColors.deepNavy,
                      AtlasColors.royalBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(38),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 108,
                      width: 108,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AtlasColors.royalBlue.withValues(
                            alpha: 0.65,
                          ),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AtlasColors.royalBlue,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 23),
                    const Text(
                      'THE ATLAS ACADEMY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        letterSpacing: 2.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      height: 3,
                      width: 58,
                      decoration: BoxDecoration(
                        color: AtlasColors.royalBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'LEARN  •  PREPARE  •  EXCEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AtlasColors.royalBlue,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Your Journey to\nMedical Excellence',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Learn smarter. Prepare confidently. '
                      'Build the future you deserve.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Everything you need to succeed',
                      style: TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'A focused learning experience for your medical journey.',
                      style: TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Feature card.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: AtlasColors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          color: AtlasColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AtlasColors.navy.withValues(
                              alpha: 0.055,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          _FeatureRow(
                            icon: Icons.menu_book_rounded,
                            title: 'Structured Medical Learning',
                            subtitle:
                                'Organised subjects and study resources',
                          ),
                          SizedBox(height: 22),
                          _FeatureRow(
                            icon: Icons.quiz_rounded,
                            title: 'Practice and Assessments',
                            subtitle:
                                'MCQs, examinations and answer reviews',
                          ),
                          SizedBox(height: 22),
                          _FeatureRow(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Guided Exam Preparation',
                            subtitle:
                                'Prepare for your chosen medical pathway',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 27),

                    // Registration button.
                    SizedBox(
                      width: double.infinity,
                      height: 57,
                      child: ElevatedButton(
                        onPressed: () => _openRegistration(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AtlasColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor:
                              AtlasColors.navy.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Create Student Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    // Login button.
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => _openLogin(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AtlasColors.navy,
                          backgroundColor: AtlasColors.white,
                          side: const BorderSide(
                            color: AtlasColors.royalBlue,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Already Have an Account? Log In',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'THE ATLAS ACADEMY',
                            style: TextStyle(
                              color: AtlasColors.navy,
                              fontSize: 11,
                              letterSpacing: 1.7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'EXCELLENCE IN MEDICAL EDUCATION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AtlasColors.secondaryText,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          height: 49,
          width: 49,
          decoration: BoxDecoration(
            color: AtlasColors.paleBlue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: AtlasColors.navy,
            size: 24,
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
                  color: AtlasColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AtlasColors.gold,
          size: 13,
        ),
      ],
    );
  }
}
