import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';

/// Tasks 页单一 FAB：点击扇形展开「文字创建」「语音输入」。
class CreateActionFanFab extends StatefulWidget {
  final VoidCallback onTextCreate;
  final VoidCallback onVoiceInput;

  const CreateActionFanFab({
    super.key,
    required this.onTextCreate,
    required this.onVoiceInput,
  });

  @override
  State<CreateActionFanFab> createState() => _CreateActionFanFabState();
}

class _CreateActionFanFabState extends State<CreateActionFanFab>
    with SingleTickerProviderStateMixin {
  static const double _fabSize = 48;
  static const double _fanRadius = 56;
  static const double _actionSize = 44;

  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandCurve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
    _controller.reverse();
  }

  void _select(VoidCallback action) {
    _collapse();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return SizedBox(
      width: _fabSize + _fanRadius + _actionSize,
      height: _fabSize + _fanRadius + _actionSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          if (_expanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _collapse,
              ),
            ),
          ..._buildFanActions(t),
          _buildMainFab(t),
        ],
      ),
    );
  }

  List<Widget> _buildFanActions(TempoTokens t) {
    if (_controller.value <= 0 && !_expanded) {
      return const [];
    }

    const actions = [
      (_FanAction.voice, LucideIcons.mic, '语音输入'),
      (_FanAction.text, LucideIcons.pencil, '文字创建'),
    ];

    return List.generate(actions.length, (index) {
      final (kind, icon, label) = actions[index];
      final angle = math.pi * (0.5 + index * 0.35);
      final offsetX = math.cos(angle) * _fanRadius;
      final offsetY = math.sin(angle) * _fanRadius;

      return AnimatedBuilder(
        animation: _expandCurve,
        builder: (context, child) {
          final progress = _expandCurve.value;
          return Positioned(
            right: _fabSize / 2 - _actionSize / 2 - offsetX * progress,
            bottom: _fabSize / 2 - _actionSize / 2 + offsetY * progress,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.85 + 0.15 * progress,
                child: child,
              ),
            ),
          );
        },
        child: _FanActionButton(
          key: kind == _FanAction.voice
              ? const Key('fan_action_voice')
              : const Key('fan_action_text'),
          icon: icon,
          label: label,
          tokens: t,
          onTap: () {
            switch (kind) {
              case _FanAction.voice:
                _select(widget.onVoiceInput);
              case _FanAction.text:
                _select(widget.onTextCreate);
            }
          },
        ),
      );
    });
  }

  Widget _buildMainFab(TempoTokens t) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Material(
        color: t.fg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: t.fg, width: 0.8),
        ),
        elevation: 0,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: SizedBox(
            width: _fabSize,
            height: _fabSize,
            child: AnimatedBuilder(
              animation: _expandCurve,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandCurve.value * math.pi / 4,
                  child: child,
                );
              },
              child: Icon(LucideIcons.plus, size: 22, color: t.bg),
            ),
          ),
        ),
      ),
    );
  }
}

enum _FanAction { voice, text }

class _FanActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final TempoTokens tokens;
  final VoidCallback onTap;

  const _FanActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: tokens.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: tokens.borderStrong, width: 0.8),
          ),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: tokens.mono(
            size: 9,
            weight: FontWeight.w600,
            color: tokens.fgMuted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
