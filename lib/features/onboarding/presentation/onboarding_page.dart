// ============================================================
// OnboardingPage — 3 屏引导(对应 prototype App.tsx onboarding overlay)
// 全屏黑色 overlay + Instrument Serif italic 标题 + mono badge + 进度条
// 逻辑保留:_currentPage / OnboardingManager / 通知权限请求 / 跳转
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/onboarding_manager.dart';

// Onboarding 暗色专用色阶(原型 zinc 系列,light theme token 不适用)
const Color _kZinc300 = Color(0xFFD4D4D8);
const Color _kZinc400 = Color(0xFFA1A1AA);
const Color _kZinc500 = Color(0xFF71717A);
const Color _kZinc700 = Color(0xFF3F3F46);
const Color _kZinc800 = Color(0xFF27272A);
const Color _kEmerald500 = Color(0xFF10B981);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  final _onboardingManager = OnboardingManager();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF20A0A0A), // #0A0A0A 95%
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) =>
                      setState(() => _currentPage = page),
                  children: const [
                    _OnboardingStep(
                      step: 0,
                      title: '🔌 思源中文笔记单向导入',
                      description:
                          'Tempo MVP 2.0 聚焦解决个人知识和行动系统的分裂。您可以在思源笔记中撰写任务列表,然后一键同步拉取,无需在工具间手动搬运数据。',
                    ),
                    _OnboardingStep(
                      step: 1,
                      title: '🌅 脑电波动与精力分配',
                      description:
                          '结合在设置页中点击微调的脑力精力曲线,Tempo 让每个习惯代办得到黄金专注带的妥协和舒展。智能排期(计划页)旨在验证高优承载 H1 与 H3。',
                    ),
                    _OnboardingStep(
                      step: 2,
                      title: '🧪 致命假设前置验证反馈',
                      description:
                          '遵循 OPC MVP 实验方法论,我们致力于先收集真实的采纳比。您可以随意在使用待办或重新排期后,对 LLM 方案质量评分打 1-5 星并递交评语!',
                    ),
                  ],
                ),
              ),
              _OnboardingFooter(
                currentPage: _currentPage,
                onBack: _prevPage,
                onNext: _nextPage,
                onSkip: _completeOnboarding,
                onFinish: _finishWithPermission,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotificationEnabled, true);
  }

  Future<void> _completeOnboarding() async {
    await _onboardingManager.setCompleted();
    if (!mounted) return;
    context.go(AppConstants.routeTasks);
  }

  Future<void> _finishWithPermission() async {
    await _requestNotificationPermission();
    await _completeOnboarding();
  }
}

/// 单屏内容:mono badge + N/3 + serif italic 标题 + 白色短下划线 + 正文
class _OnboardingStep extends StatelessWidget {
  final int step;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // badge + N/3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kZinc800.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'TEMPO MVP 指南',
                  style: AppTheme.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    color: _kZinc400,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                '${step + 1} / 3',
                style: AppTheme.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _kZinc500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // serif italic 标题
          Text(
            title,
            style: AppTheme.italicSerif(
              size: 20,
              color: AppTheme.bg,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // 白色短下划线
          Container(width: 48, height: 1.5, color: AppTheme.bg),
          const SizedBox(height: 18),
          // 正文
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: _kZinc300,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部:3 段进度条 + 按钮行 + 页脚 micro-label
class _OnboardingFooter extends StatelessWidget {
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  const _OnboardingFooter({
    required this.currentPage,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == 2;
    return Column(
      children: [
        // 进度条 3 段
        Row(
          children: List.generate(3, (index) {
            final active = index == currentPage;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                height: 1.5,
                decoration: BoxDecoration(
                  color: active ? AppTheme.bg : _kZinc800,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // 按钮行
        Row(
          children: [
            Expanded(
              child: _OnboardingButton(
                label: currentPage == 0 ? '跳过' : '上一步',
                onTap: currentPage == 0 ? onSkip : onBack,
                foreground: currentPage == 0 ? _kZinc500 : _kZinc300,
                border: currentPage == 0 ? _kZinc800 : _kZinc700,
                background: Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLast
                  ? _OnboardingButton(
                      label: '开始同步体验',
                      onTap: onFinish,
                      foreground: AppTheme.bg,
                      background: _kEmerald500,
                      border: _kEmerald500,
                    )
                  : _OnboardingButton(
                      label: '下一步',
                      onTap: onNext,
                      foreground: AppTheme.fg,
                      background: AppTheme.bg,
                      border: AppTheme.bg,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 页脚
        Text(
          'TEMPO EXPERIMENT CORP · GOMVP DESIGN',
          style: AppTheme.mono(size: 9, color: _kZinc500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color foreground;
  final Color background;
  final Color border;

  const _OnboardingButton({
    required this.label,
    required this.onTap,
    required this.foreground,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
