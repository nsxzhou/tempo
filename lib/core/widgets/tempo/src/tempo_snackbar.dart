// TempoSnackbar — 顶部黑色 Toast（Overlay 实现，避免 ScaffoldMessenger 顿挫）
// bg #0A0A0A 白字 + 可选撤销链接 + 3s 自动消失

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tempo_theme_extension.dart';

class TempoSnackbar {
  TempoSnackbar._();

  static const _defaultDuration = Duration(milliseconds: 3000);
  static OverlayEntry? _currentEntry;
  static Timer? _autoDismissTimer;
  static void Function({bool immediate})? _dismissHost;

  /// 显示一条顶部黑色 Toast。
  static void show(
    BuildContext context, {
    required String message,
    String? undoLabel,
    Future<void> Function()? onUndo,
    Duration duration = _defaultDuration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _showOverlay(
      overlay: overlay,
      context: context,
      message: message,
      undoLabel: undoLabel,
      onUndo: onUndo,
      duration: duration,
    );
  }

  /// 通过全局 Navigator Key 显示 Toast（后台任务创建等无局部 Context 场景）。
  static void showGlobal({
    required GlobalKey<NavigatorState> navigatorKey,
    BuildContext? layoutContext,
    required String message,
    String? undoLabel,
    Future<void> Function()? onUndo,
    Duration duration = _defaultDuration,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    _showOverlay(
      overlay: overlay,
      context: layoutContext ?? navContext,
      message: message,
      undoLabel: undoLabel,
      onUndo: onUndo,
      duration: duration,
    );
  }

  static void _showOverlay({
    required OverlayState overlay,
    required BuildContext context,
    required String message,
    String? undoLabel,
    Future<void> Function()? onUndo,
    required Duration duration,
  }) {
    _dismissCurrent(immediate: true);

    final media = MediaQuery.of(context);
    final top = media.padding.top + 12;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _TempoToastHost(
          top: top,
          message: message,
          undoLabel: undoLabel,
          onUndo: onUndo == null
              ? null
              : () {
                  _dismissCurrent();
                  onUndo();
                },
          onRemoved: () {
            entry.remove();
            if (_currentEntry == entry) {
              _currentEntry = null;
              _dismissHost = null;
            }
          },
          registerDismiss: (dismiss) {
            _dismissHost = dismiss;
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _autoDismissTimer = Timer(duration, () => _dismissCurrent());
  }

  static void _dismissCurrent({bool immediate = false}) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    final dismiss = _dismissHost;
    if (dismiss != null) {
      dismiss(immediate: immediate);
      return;
    }

    _currentEntry?.remove();
    _currentEntry = null;
    _dismissHost = null;
  }
}

class _TempoToastHost extends StatefulWidget {
  final double top;
  final String message;
  final String? undoLabel;
  final VoidCallback? onUndo;
  final VoidCallback onRemoved;
  final void Function(void Function({bool immediate}) dismiss) registerDismiss;

  const _TempoToastHost({
    required this.top,
    required this.message,
    required this.undoLabel,
    required this.onUndo,
    required this.onRemoved,
    required this.registerDismiss,
  });

  @override
  State<_TempoToastHost> createState() => _TempoToastHostState();
}

class _TempoToastHostState extends State<_TempoToastHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    widget.registerDismiss(_dismiss);
    _controller.forward();
  }

  void _dismiss({bool immediate = false}) {
    if (_removed) return;
    if (immediate || !_controller.isCompleted) {
      _finishRemove();
      return;
    }
    _controller.reverse().then((_) => _finishRemove());
  }

  void _finishRemove() {
    if (_removed) return;
    _removed = true;
    widget.onRemoved();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Positioned(
      top: widget.top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.fg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.35,
                        color: t.bg,
                      ),
                    ),
                  ),
                  if (widget.undoLabel != null && widget.onUndo != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onUndo,
                      child: Text(
                        widget.undoLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.bg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
