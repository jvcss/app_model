import 'package:flutter/material.dart';

enum AppNotificationType { info, success, warning, error }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  Color bgColor(ThemeData theme) {
    switch (type) {
      case AppNotificationType.success: return Colors.green.shade600;
      case AppNotificationType.warning: return Colors.orange.shade700;
      case AppNotificationType.error:   return Colors.red.shade700;
      case AppNotificationType.info:    return theme.colorScheme.primary;
    }
  }

  IconData icon() {
    switch (type) {
      case AppNotificationType.success: return Icons.check_circle_rounded;
      case AppNotificationType.warning: return Icons.warning_amber_rounded;
      case AppNotificationType.error:   return Icons.error_rounded;
      case AppNotificationType.info:    return Icons.info_rounded;
    }
  }
}
