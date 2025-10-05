import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

class NotificationsOverlay extends ConsumerWidget {
  const NotificationsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    return IgnorePointer(
      ignoring: items.isEmpty,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((n) => _ToastCard(n: n)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends ConsumerStatefulWidget {
  final AppNotification n;
  const _ToastCard({required this.n});

  @override
  ConsumerState<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends ConsumerState<_ToastCard>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // animate in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;
    final controller = ref.read(notificationsProvider.notifier);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(-0.1, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _visible ? 1 : 0,
        child: Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) => controller.dismiss(n.id),
          child: Material(
            color: n.bgColor(Theme.of(context)),
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: n.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(n.icon(), color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(n.message),
                              if (n.actionLabel != null && n.onAction != null) ...[
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: n.onAction,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(n.actionLabel!),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.dismiss(n.id),
                        icon: const Icon(Icons.close, color: Colors.white),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
