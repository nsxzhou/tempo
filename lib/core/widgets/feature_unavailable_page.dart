// ============================================================
// FeatureUnavailablePage — 功能未上线占位页
// Scaffold + SafeArea + EmptyState，底部预留 TabBar 空间
// ============================================================

import 'package:flutter/material.dart';

import '../debug/agent_debug_log.dart';
import '../theme/app_theme.dart';
import 'empty_state.dart';

/// 功能暂未实现的占位页。
class FeatureUnavailablePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const FeatureUnavailablePage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // #region agent log
    agentDebugLog(
      location: 'feature_unavailable_page.dart:build',
      message: 'FeatureUnavailablePage built',
      hypothesisId: 'H3',
      data: {'title': title, 'hasSubtitle': subtitle != null},
    );
    // #endregion
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: EmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}
