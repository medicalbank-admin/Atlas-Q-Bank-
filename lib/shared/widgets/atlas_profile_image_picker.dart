import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/atlas_academy_app.dart';
import '../../theme/atlas_spacing.dart';

class AtlasProfileImagePicker extends StatefulWidget {
  const AtlasProfileImagePicker({
    super.key,
    this.onImageSelected,
    this.initialImage,
    this.size = 124,
  });

  final ValueChanged<File?>? onImageSelected;
  final String? initialImage;
  final double size;

  @override
  State<AtlasProfileImagePicker> createState() =>
      _AtlasProfileImagePickerState();
}

class _AtlasProfileImagePickerState
    extends State<AtlasProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      final file = File(image.path);

      setState(() {
        _selectedImage = file;
      });

      widget.onImageSelected?.call(file);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select image. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AtlasColors.secondaryText.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Choose Profile Picture',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 22),
                _optionTile(
                  context: sheetContext,
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 12),
                _optionTile(
                  context: sheetContext,
                  icon: Icons.camera_alt_rounded,
                  title: 'Take a Photo',
                  subtitle: 'Use your device camera',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  _optionTile(
                    context: sheetContext,
                    icon: Icons.delete_outline_rounded,
                    title: 'Remove Picture',
                    subtitle: 'Choose another photo later',
                    color: AtlasColors.error,
                    onTap: () {
                      Navigator.pop(sheetContext);

                      setState(() {
                        _selectedImage = null;
                      });

                      widget.onImageSelected?.call(null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final accent = color ?? AtlasColors.oceanTeal;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: accent.withValues(alpha: 0.07),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.13),
        child: Icon(icon, color: accent),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isPicking ? null : _showImageOptions,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AtlasColors.champagne,
                      AtlasColors.oceanTeal,
                    ],
                  ),
                  boxShadow: AtlasShadows.medium,
                ),
                child: CircleAvatar(
                  backgroundColor: AtlasColors.softTeal,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : widget.initialImage != null
                          ? NetworkImage(widget.initialImage!)
                          : null,
                  child: _isPicking
                      ? const CircularProgressIndicator()
                      : _selectedImage == null &&
                              widget.initialImage == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 55,
                              color: AtlasColors.oceanTeal,
                            )
                          : null,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 5,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AtlasColors.deepTeal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Upload Profile Picture',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a clear photo of yourself',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AtlasColors.secondaryText,
              ),
        ),
      ],
    );
  }
}
