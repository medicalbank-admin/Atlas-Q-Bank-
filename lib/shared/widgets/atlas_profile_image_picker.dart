
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/atlas_academy_app.dart';

class AtlasProfileImagePicker extends StatefulWidget {
  const AtlasProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.initialImageUrl,
  });

  final ValueChanged<XFile?> onImageSelected;
  final String? initialImageUrl;

  @override
  State<AtlasProfileImagePicker> createState() =>
      _AtlasProfileImagePickerState();
}

class _AtlasProfileImagePickerState
    extends State<AtlasProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isPicking = false;

  Future<void> _chooseImage(ImageSource source) async {
    try {
      setState(() => _isPicking = true);

      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });

      widget.onImageSelected(image);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select this image. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: AtlasColors.oceanTeal,
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _chooseImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: AtlasColors.oceanTeal,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _chooseImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: const Text('Remove Selected Picture'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _imageBytes = null;
                      });
                      widget.onImageSelected(null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: 112,
        height: 112,
      );
    }

    if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return Image.network(
        widget.initialImageUrl!,
        fit: BoxFit.cover,
        width: 112,
        height: 112,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 112,
      height: 112,
      color: AtlasColors.softTeal,
      child: const Icon(
        Icons.person_rounded,
        size: 52,
        color: AtlasColors.oceanTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AtlasColors.champagne,
                  width: 2,
                ),
              ),
              child: ClipOval(child: _buildPreview()),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AtlasColors.deepTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isPicking ? null : _showImageOptions,
          child: Text(
            _isPicking
                ? 'Selecting image...'
                : _selectedImage == null
                    ? 'Upload Profile Picture *'
                    : 'Change Profile Picture',
            style: const TextStyle(
              color: AtlasColors.oceanTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
