import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType {
  success,
  delete,
  info,
  warning,
  error,
}

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _anim.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    final (Color accentColor, IconData iconData, String defaultTitle) =
        switch (widget.type) {
      ToastType.success => (
        const Color(0xFFB6FF3B),
        Icons.check_circle_rounded,
        'Saved',
      ),
      ToastType.delete => (
        const Color(0xFFFF4D4D),
        Icons.delete_outline_rounded,
        'Deleted',
      ),
      ToastType.info => (
        const Color(0xFF00D4FF),
        Icons.info_outline_rounded,
        'Notice',
      ),
      ToastType.warning => (
        const Color(0xFFFFB800),
        Icons.warning_amber_rounded,
        'Warning',
      ),
      ToastType.error => (
        const Color(0xFFFF4D4D),
        Icons.error_outline_rounded,
        'Error',
      ),
    };

    final displayTitle = widget.title ?? defaultTitle;

    return Positioned(
      top: safeTop + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Dismissible(
            key: const Key('app_toast_dismissible'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _handleDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.4),
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
