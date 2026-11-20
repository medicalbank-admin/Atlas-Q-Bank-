
import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';
import '../../theme/atlas_spacing.dart';

class AtlasFeedback {
  AtlasFeedback._();

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _showMessage(
      context,
      message: message,
      title: title ?? 'Success',
      icon: Icons.check_circle_rounded,
      color: AtlasColors.success,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _showMessage(
      context,
      message: message,
      title: title ?? 'Something went wrong',
      icon: Icons.error_rounded,
      color: AtlasColors.error,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _showMessage(
      context,
      message: message,
      title: title ?? 'Information',
      icon: Icons.info_rounded,
      color: AtlasColors.info,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _showMessage(
      context,
      message: message,
      title: title ?? 'Please note',
      icon: Icons.warning_rounded,
      color: AtlasColors.gold,
    );
  }

  static void _showMessage(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).cardTheme.color,
          elevation: 8,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: AtlasRadius.large,
            side: BorderSide(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Continue',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    Color? accentColor,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? AtlasColors.error
        : accentColor ?? AtlasColors.oceanTeal;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            26,
            24,
            12,
          ),
          title: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 29,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AtlasColors.secondaryText,
                  height: 1.5,
                ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            22,
          ),
          actions: [
            SizedBox(
              width: 105,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(cancelText),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 125,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(confirmText),
              ),
            ),
          ],
        );
      },
    );
  }
}
