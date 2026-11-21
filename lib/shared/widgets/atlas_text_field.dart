import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';

class AtlasTextField extends StatelessWidget {
  const AtlasTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AtlasColors.charcoal,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: AtlasColors.oceanTeal,
                size: 21,
              ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AtlasPasswordField extends StatefulWidget {
  const AtlasPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<AtlasPasswordField> createState() =>
      _AtlasPasswordFieldState();
}

class _AtlasPasswordFieldState
    extends State<AtlasPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AtlasTextField(
      controller: widget.controller,
      label: widget.label,
      hint: 'Enter your password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscure = !_obscure;
          });
        },
        icon: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}

class AtlasEmailField extends StatelessWidget {
  const AtlasEmailField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Email Address',
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AtlasTextField(
      controller: controller,
      label: label,
      hint: 'name@example.com',
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      validator: validator,
    );
  }
}

class AtlasPhoneField extends StatelessWidget {
  const AtlasPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'WhatsApp Number',
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AtlasTextField(
      controller: controller,
      label: label,
      hint: '+92 300 1234567',
      prefixIcon: Icons.phone_iphone_rounded,
      keyboardType: TextInputType.phone,
      validator: validator,
    );
  }
}

class AtlasSearchField extends StatelessWidget {
  const AtlasSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search anything...',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AtlasColors.charcoal,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AtlasColors.oceanTeal,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            controller.clear();
            onChanged?.call('');
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class AtlasMultilineField extends StatelessWidget {
  const AtlasMultilineField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 4,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AtlasTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
