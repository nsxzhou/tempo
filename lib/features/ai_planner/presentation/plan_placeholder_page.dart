// ============================================================
// PlanPlaceholderPage — AI 计划页占位（业务未接入）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/widgets/feature_unavailable_page.dart';

/// AI 计划 Tab 占位页。
class PlanPlaceholderPage extends StatelessWidget {
  const PlanPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureUnavailablePage(
      icon: LucideIcons.sparkles,
      title: 'AI 计划即将上线',
      subtitle: '智能排期与精力曲线功能开发中',
    );
  }
}
