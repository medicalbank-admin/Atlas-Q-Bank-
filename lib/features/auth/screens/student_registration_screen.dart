import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/atlas_buttons.dart';
import '../../../shared/widgets/atlas_profile_image_picker.dart';
import '../../../shared/widgets/atlas_selection_fields.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../services/auth_service.dart';

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

  final AuthService _authService = AuthService();

  XFile? _profileImage;
  String? _selectedCountry;
  String? _selectedUniversity;

  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Map<String, List<String>> _universityData = {
    'Pakistan': [
      'Aga Khan University',
      'Khyber Medical University',
      'King Edward Medical University',
      'Dow University of Health Sciences',
      'University of Health Sciences Lahore',
      'Rawalpindi Medical University',
      'Bolan University of Medical and Health Sciences',
      'Riphah International University',
      'Ziauddin University',
    ],
    'India': [
      'All India Institute of Medical Sciences',
      'Christian Medical College Vellore',
      'Maulana Azad Medical College',
      'Kasturba Medical College',
      'King George Medical University',
    ],
    'United Kingdom': [
      'University of Oxford',
      'University of Cambridge',
      'Imperial College London',
      'University College London',
      'University of Edinburgh',
      "King's College London",
    ],
    'United States': [
      'Harvard University',
      'Johns Hopkins University',
      'Stanford University',
      'Yale University',
      'University of California',
    ],
    'Australia': [
      'University of Melbourne',
      'University of Sydney',
      'Monash University',
      'University of Queensland',
    ],
    'Bangladesh': [
      'Dhaka Medical College',
      'Sir Salimullah Medical College',
      'Chittagong Medical College',
      'Rajshahi Medical College',
    ],
    'Nepal': [
      'Tribhuvan University',
      'Kathmandu University',
      'B.P. Koirala Institute of Health Sciences',
    ],
    'Saudi Arabia': [
      'King Saud University',
      'King Abdulaziz University',
      'Imam Abdulrahman Bin Faisal University',
    ],
    'Malaysia': [
      'University of Malaya',
      'Universiti Kebangsaan Malaysia',
      'International Medical University',
    ],
    'Egypt': [
      'Cairo University',
      'Ain Shams University',
      'Alexandria University',
    ],
  };

  List<String> get _availableUniversities {
    return _universityData[_selectedCountry] ?? [];
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp number is required';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid WhatsApp number';
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

  Future<void> _selectUniversity() async {
    if (_selectedCountry == null) {
      AtlasFeedback.showWarning(
        context,
        'Please select your country first.',
      );
      return;
    }

    final universities = _availableUniversities;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AtlasColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return _UniversitySelectionSheet(
          universities: universities,
          selectedUniversity: _selectedUniversity,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    if (selected == '__OTHER__') {
      final controller = TextEditingController();

      final customUniversity = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AtlasColors.white,
            title: const Text(
              'Enter University Name',
              style: TextStyle(
                color: AtlasColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'University name',
                hintText: 'Enter your university',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();

                  if (name.isNotEmpty) {
                    Navigator.pop(dialogContext, name);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      controller.dispose();

      if (customUniversity == null ||
          customUniversity.trim().isEmpty ||
          !mounted) {
        return;
      }

      setState(() {
        _selectedUniversity = customUniversity.trim();
      });
    } else {
      setState(() {
        _selectedUniversity = selected;
      });
    }
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImage == null) {
      AtlasFeedback.showWarning(
        context,
        'Please upload your profile picture.',
      );
      return;
    }

    if (_selectedCountry == null ||
        _selectedCountry!.trim().isEmpty) {
      AtlasFeedback.showWarning(
        context,
        'Please select your country of study.',
      );
      return;
    }

    if (_selectedUniversity == null ||
        _selectedUniversity!.trim().isEmpty) {
      AtlasFeedback.showWarning(
        context,
        'Please select or enter your university.',
      );
      return;
    }

    if (!_acceptedTerms) {
      AtlasFeedback.showWarning(
        context,
        'Please accept the Terms and Privacy Policy.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Uint8List imageBytes =
          await _profileImage!.readAsBytes();

      final registrationData = StudentRegistrationData(
        fullName: _fullNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        countryOfStudy: _selectedCountry!,
        university: _selectedUniversity!,
        profileImageBytes: imageBytes,
        profileImageFileName: _profileImage!.name,
        termsAccepted: _acceptedTerms,
      );

      await _authService.registerStudent(registrationData);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AtlasColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
            ),
            icon: const Icon(
              Icons.mark_email_read_rounded,
              color: AtlasColors.royalBlue,
              size: 48,
            ),
            title: const Text(
              'Registration Successful',
              style: TextStyle(
                color: AtlasColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text(
              'Your student account has been created. '
              'Please check your email and verify your email address. '
              'Your account is now awaiting administrator approval.',
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        _friendlyError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error.toString().contains('email-already-in-use')) {
      return 'This email address is already registered.';
    }

    if (error.toString().contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (error.toString().contains('weak-password')) {
      return 'Please choose a stronger password.';
    }

    if (error.toString().contains('network-request-failed')) {
      return 'Network connection failed. Please try again.';
    }

    if (error.toString().contains('permission-denied')) {
      return 'Registration permissions are not configured correctly. Please contact support.';
    }

    return 'Registration failed. Please check your information and try again.';
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AtlasColors.navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AtlasColors.secondaryText,
            ),
          ),
          const SizedBox(height: 11),
          Container(
            height: 3,
            width: 42,
            decoration: BoxDecoration(
              color: AtlasColors.champagne,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator ?? _requiredValidator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: AtlasColors.royalBlue,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _registrationCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AtlasColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AtlasColors.border),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  // Premium registration header.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 27,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AtlasColors.navy,
                          AtlasColors.deepNavy,
                          AtlasColors.royalBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 47,
                          color: AtlasColors.champagne,
                        ),
                        SizedBox(height: 13),
                        Text(
                          'THE ATLAS ACADEMY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Begin Your Medical Journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your student account and take the next step towards medical excellence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Profile Picture.
                  _registrationCard(
                    child: Column(
                      children: [
                        _sectionTitle(
                          'Profile Picture',
                          'Upload a clear and recent photograph.',
                        ),
                        AtlasProfileImagePicker(
                          onImageSelected: (image) {
                            setState(() {
                              _profileImage = image;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 17),

                  // Personal Information.
                  _registrationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Personal Information',
                          'Enter your official personal details.',
                        ),
                        _textField(
                          controller: _fullNameController,
                          label: 'Full Name *',
                          icon: Icons.person_outline_rounded,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                        _textField(
                          controller: _fatherNameController,
                          label: "Father's Name *",
                          icon: Icons.person_rounded,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                        _textField(
                          controller: _nationalIdController,
                          label: 'National ID / CNIC / Passport *',
                          icon: Icons.badge_outlined,
                        ),
                        _textField(
                          controller: _whatsappController,
                          label: 'WhatsApp Number *',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: _phoneValidator,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 17),

                  // Academic Information.
                  _registrationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Academic Information',
                          'Tell us where you are studying.',
                        ),
                        AtlasCountryField(
                          value: _selectedCountry,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Country is required';
                            }

                            return null;
                          },
                          onChanged: (country) {
                            setState(() {
                              _selectedCountry = country;
                              _selectedUniversity = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectUniversity,
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'University *',
                              prefixIcon: Icon(
                                Icons.account_balance_rounded,
                                color: AtlasColors.royalBlue,
                              ),
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                            child: Text(
                              _selectedUniversity ??
                                  'Search or enter your university',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedUniversity == null
                                    ? AtlasColors.secondaryText
                                    : AtlasColors.charcoal,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedUniversity == null)
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 12,
                              top: 6,
                            ),
                            child: Text(
                              'Please select or enter your university.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AtlasColors.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 17),

                  // Account Security.
                  _registrationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Account Security',
                          'Create secure login credentials.',
                        ),
                        _textField(
                          controller: _emailController,
                          label: 'Email Address *',
                          icon: Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        _textField(
                          controller: _passwordController,
                          label: 'Password *',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          validator: _passwordValidator,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        _textField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password *',
                          icon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirmPassword,
                          validator: _confirmPasswordValidator,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 17),

                  // Terms and Conditions.
                  _registrationCard(
                    child: CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      activeColor: AtlasColors.navy,
                      title: const Text(
                        'I accept the Terms & Conditions and Privacy Policy.',
                        style: TextStyle(
                          color: AtlasColors.charcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  AtlasPrimaryButton(
                    label: 'Create Student Account',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting
                        ? null
                        : _submitRegistration,
                  ),

                  const SizedBox(height: 17),

                  TextButton(
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        color: AtlasColors.royalBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
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
          ),
        ),
      ),
    );
  }
}

class _UniversitySelectionSheet extends StatefulWidget {
  const _UniversitySelectionSheet({
    required this.universities,
    required this.selectedUniversity,
  });

  final List<String> universities;
  final String? selectedUniversity;

  @override
  State<_UniversitySelectionSheet> createState() =>
      _UniversitySelectionSheetState();
}

class _UniversitySelectionSheetState
    extends State<_UniversitySelectionSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.universities.where((university) {
      return university.toLowerCase().contains(
            _query.trim().toLowerCase(),
          );
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select University',
                style: TextStyle(
                  color: AtlasColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search university...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AtlasColors.royalBlue,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    ...filtered.map((university) {
                      return ListTile(
                        title: Text(
                          university,
                          style: const TextStyle(
                            color: AtlasColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: university ==
                                widget.selectedUniversity
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AtlasColors.gold,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context, university);
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.edit_location_alt_rounded,
                        color: AtlasColors.royalBlue,
                      ),
                      title: const Text(
                        'Other — Enter University Manually',
                        style: TextStyle(
                          color: AtlasColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, '__OTHER__');
                      },
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
