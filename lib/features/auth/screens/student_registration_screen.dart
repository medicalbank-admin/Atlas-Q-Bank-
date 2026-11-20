import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_buttons.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../../shared/widgets/atlas_profile_image_picker.dart';
import '../../../shared/widgets/atlas_selection_fields.dart';
import '../../../shared/widgets/atlas_text_field.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedCountry;
  String? _selectedUniversity;

  // This callback receives the selected image.
  // Firebase upload will be connected through the auth service.
  dynamic _profileImage;

  bool _acceptedTerms = false;
  bool _isSubmitting = false;

  static const Map<String, List<String>> _universities = {
    'Pakistan': [
      'Aga Khan University',
      'Dow University of Health Sciences',
      'Khyber Medical University',
      'King Edward Medical University',
      'Lahore Medical and Dental College',
      'Rawalpindi Medical University',
      'University of Health Sciences Lahore',
      'Other University',
    ],
    'India': [
      'All India Institute of Medical Sciences',
      'Christian Medical College',
      'Kasturba Medical College',
      'Maulana Azad Medical College',
      'Other University',
    ],
    'United Kingdom': [
      'University of Oxford',
      'University of Cambridge',
      'University College London',
      'Imperial College London',
      'Other University',
    ],
    'United States': [
      'Harvard University',
      'Johns Hopkins University',
      'Stanford University',
      'University of California',
      'Other University',
    ],
    'Australia': [
      'University of Melbourne',
      'University of Sydney',
      'Monash University',
      'Other University',
    ],
  };

  List<String> get _availableUniversities {
    return _universities[_selectedCountry] ??
        ['Other University'];
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must contain at least 8 characters';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp number is required';
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number with country code';
    }

    return null;
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (_profileImage == null) {
      _showMessage('Please upload your profile picture.');
      return;
    }

    if (_selectedCountry == null) {
      _showMessage('Please select your country of study.');
      return;
    }

    if (_selectedUniversity == null) {
      _showMessage('Please select your university.');
      return;
    }

    if (!_acceptedTerms) {
      _showMessage('Please accept the terms and conditions.');
      return;
    }

    if (!isValid) return;

    // Firebase registration will be connected here.
    // Do not create an account until the backend service is ready.

    _showMessage(
      'Your information is valid. Account registration service is not connected yet.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _nationalIdController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  36,
                ),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 26),

                  AtlasCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: AtlasProfileImagePicker(
                            onImageSelected: (image) {
                              setState(() {
                                _profileImage = image;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        _sectionTitle(
                          'Personal Information',
                          'Tell us about yourself.',
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),

                        AtlasTextField(
                          controller: _fullNameController,
                          label: 'Full Name *',
                          hint: 'Enter your full name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: _requiredValidator,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                        const SizedBox(height: 17),

                        AtlasTextField(
                          controller: _fatherNameController,
                          label: "Father's Name *",
                          hint: "Enter your father's full name",
                          prefixIcon: Icons.person_rounded,
                          validator: _requiredValidator,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                        const SizedBox(height: 17),

                        AtlasTextField(
                          controller: _nationalIdController,
                          label: 'National ID / CNIC / Passport *',
                          hint: 'Enter your identification number',
                          prefixIcon: Icons.badge_outlined,
                          validator: _requiredValidator,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 17),

                        AtlasPhoneField(
                          controller: _whatsappController,
                          validator: _phoneValidator,
                        ),
                        const SizedBox(height: 17),

                        AtlasEmailField(
                          controller: _emailController,
                          validator: _emailValidator,
                        ),

                        const SizedBox(height: 30),

                        _sectionTitle(
                          'Academic Information',
                          'Where are you studying medicine?',
                          Icons.school_outlined,
                        ),
                        const SizedBox(height: 20),

                        AtlasCountryField(
                          value: _selectedCountry,
                          onChanged: (country) {
                            setState(() {
                              _selectedCountry = country;
                              _selectedUniversity = null;
                            });
                          },
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 17),

                        AtlasUniversityField(
                          value: _selectedUniversity,
                          universities: _availableUniversities,
                          onChanged: (university) {
                            setState(() {
                              _selectedUniversity = university;
                            });
                          },
                          validator: _requiredValidator,
                        ),

                        const SizedBox(height: 30),

                        _sectionTitle(
                          'Account Security',
                          'Create a secure password.',
                          Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 20),

                        AtlasPasswordField(
                          controller: _passwordController,
                          validator: _passwordValidator,
                        ),
                        const SizedBox(height: 17),

                        AtlasPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          validator: _confirmPasswordValidator,
                        ),

                        const SizedBox(height: 24),

                        CheckboxListTile(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity:
                              ListTileControlAffinity.leading,
                          activeColor: AtlasColors.oceanTeal,
                          title: const Text(
                            'I agree to the Terms & Conditions and Privacy Policy.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 20),

                        AtlasPrimaryButton(
                          label: 'Create My Account',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting
                              ? null
                              : _submitRegistration,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      child: const Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: AtlasColors.oceanTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AtlasColors.deepTeal,
                AtlasColors.oceanTeal,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'Join The Atlas Academy',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.w800,
                color: AtlasColors.deepTeal,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your student profile and begin your medical learning journey.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AtlasColors.secondaryText,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AtlasColors.softTeal,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: AtlasColors.oceanTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AtlasColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
