import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
      (ref) => NotificationsController(),
    );

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super(const []);
  int _counter = 0;
  final Map<String, Timer> _timers = {};

  String _nextId() => (++_counter).toString();

  void _scheduleAutoDismiss(AppNotification n) {
    _timers[n.id]?.cancel();
    _timers[n.id] = Timer(n.duration, () => dismiss(n.id));
  }

  void show({
    required String title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final n = AppNotification(
      id: _nextId(),
      title: title,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    state = [n, ...state].take(5).toList(); // keep top 5
    _scheduleAutoDismiss(n);
  }

  // convenience
  void info(String t, String m) =>
      show(title: t, message: m, type: AppNotificationType.info);
  void success(String t, String m) =>
      show(title: t, message: m, type: AppNotificationType.success);
  void warning(String t, String m) =>
      show(title: t, message: m, type: AppNotificationType.warning);
  void error(String t, String m) => show(
    title: t,
    message: m,
    type: AppNotificationType.error,
    duration: const Duration(seconds: 5),
  );

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    state = state.where((e) => e.id != id).toList();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
