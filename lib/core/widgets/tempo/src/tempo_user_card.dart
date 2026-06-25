// TempoUserCard — 设置页用户卡(Option A: 极简纯文字)
// mono 邮箱 + 灰色注销文字链接

import 'package:flutter/material.dart';

import '../../../theme/tempo_theme_extension.dart';
import 'tempo_glass_surface.dart';

class TempoUserCard extends StatelessWidget {
  final String email;
  final String signOutLabel;
  final VoidCallback? onSignOut;

  const TempoUserCard({
    super.key,
    required this.email,
    this.signOutLabel = '注销',
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TempoGlassSurface(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              email,
              style: tokens.mono(
                size: 12,
                color: tokens.fg,
                letterSpacing: -0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSignOut,
            child: Text(
              signOutLabel,
              style: tokens.mono(
                size: 11,
                color: tokens.fgMuted,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
