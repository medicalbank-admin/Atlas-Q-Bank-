import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared illustrated category artwork used by Learning Resources and Exams.
/// Keep category matching centralized so both areas always show identical art.
class MedicalCategoryArtwork extends StatelessWidget {
  final String category;
  final double size;
  final String? imageUrl;

  const MedicalCategoryArtwork({
    super.key,
    required this.category,
    this.size = 64,
    this.imageUrl,
  });

  static const Map<String, String> _assets = {
    'cardiovascular': 'assets/medical_categories/cardiovascular.svg',
    'heart': 'assets/medical_categories/cardiovascular.svg',
    'circulatory': 'assets/medical_categories/cardiovascular.svg',
    'respiratory': 'assets/medical_categories/respiratory.svg',
    'lungs': 'assets/medical_categories/respiratory.svg',
    'pulmonary': 'assets/medical_categories/respiratory.svg',
    'nervous': 'assets/medical_categories/nervous.svg',
    'neurology': 'assets/medical_categories/nervous.svg',
    'neurological': 'assets/medical_categories/nervous.svg',
    'brain': 'assets/medical_categories/nervous.svg',
    'renal': 'assets/medical_categories/renal.svg',
    'urinary': 'assets/medical_categories/renal.svg',
    'kidney': 'assets/medical_categories/renal.svg',
    'gastrointestinal': 'assets/medical_categories/digestive.svg',
    'digestive': 'assets/medical_categories/digestive.svg',
    'gastro': 'assets/medical_categories/digestive.svg',
    'musculoskeletal': 'assets/medical_categories/musculoskeletal.svg',
    'skeletal': 'assets/medical_categories/musculoskeletal.svg',
    'endocrine': 'assets/medical_categories/endocrine.svg',
    'reproductive': 'assets/medical_categories/reproductive.svg',
    'anatomy': 'assets/medical_categories/anatomy.svg',
    'physiology': 'assets/medical_categories/physiology.svg',
    'biochemistry': 'assets/medical_categories/biochemistry.svg',
    'pathology': 'assets/medical_categories/pathology.svg',
    'pharmacology': 'assets/medical_categories/pharmacology.svg',
    'surgery': 'assets/medical_categories/surgery.svg',
    'microbiology': 'assets/medical_categories/microbiology.svg',
  };

  static String assetFor(String category) {
    final value = category.toLowerCase().trim();
    for (final entry in _assets.entries) {
      if (value == entry.key || value.contains(entry.key)) return entry.value;
    }
    return 'assets/medical_categories/anatomy.svg';
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return SizedBox(
      width: size,
      height: size,
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SvgPicture.asset(
                assetFor(category), fit: BoxFit.contain),
            )
          : SvgPicture.asset(assetFor(category), fit: BoxFit.contain),
    );
  }
}
