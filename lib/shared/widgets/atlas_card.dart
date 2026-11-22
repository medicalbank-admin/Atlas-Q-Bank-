
import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';
import '../../theme/atlas_spacing.dart';

class AtlasCard extends StatelessWidget {
  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(21),
    this.margin,
    this.backgroundColor,
    this.borderRadius = 22,
    this.showShadow = true,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: const Color(0xFFE0EAF5),
              width: 0.9,
            ),
        boxShadow: showShadow
            ? AtlasShadows.soft
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AtlasGradientCard extends StatelessWidget {
  const AtlasGradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = AtlasRadius.xl,
    this.height,
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ??
              const [
                AtlasColors.deepTeal,
                AtlasColors.oceanTeal,
              ],
        ),
        boxShadow: AtlasShadows.medium,
      ),
      child: child,
    );
  }
}

class AtlasStatCard extends StatelessWidget {
  const AtlasStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.iconBackground,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBackground;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      padding: const EdgeInsets.all(19),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground ??
                  AtlasColors.softTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor ??
                  AtlasColors.oceanTeal,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: AtlasColors.secondaryText,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class AtlasInteractiveCard extends StatelessWidget {
  const AtlasInteractiveCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.description,
    this.trailing,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? description;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AtlasColors.softTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor ??
                  AtlasColors.deepTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AtlasColors.secondaryText,
                        ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AtlasColors.secondaryText,
              ),
        ],
      ),
    );
  }
}

class AtlasSectionHeader extends StatelessWidget {
  const AtlasSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: AtlasColors.secondaryText,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
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
