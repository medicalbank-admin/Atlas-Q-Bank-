import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/atlas_academy_app.dart';

/// Displays the official wide Atlas Academy wordmark.
class AtlasLogo extends StatelessWidget {
  final double size;
  const AtlasLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/IMG_20261123_044528.png',
    width: size * 2.85,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => SizedBox(
      width: size * 2.85,
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logo/atlas_academy_logo.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => Icon(
              Icons.school_rounded,
              size: size * .7,
              color: AtlasColors.royalBlue,
            ),
          ),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'The Atlas Academy',
              maxLines: 2,
              style: TextStyle(
                color: AtlasColors.navy,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
