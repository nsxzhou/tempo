// ============================================================
// OnboardingPage — 3 屏引导 + 通知权限请求 + 跳转逻辑
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/onboarding_manager.dart';

/// 首次使用引导页（3 屏 PageView）。
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
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomeScreen(),
                  _FeaturesScreen(),
                  _NotificationScreen(
                    onEnableNotifications: _requestNotificationPermission,
                    onFinish: _completeOnboarding,
                  ),
                ],
              ),
            ),
            // 进度指示器 + 按钮
            _BottomBar(
              currentPage: _currentPage,
              pageController: _pageController,
              onNext: _nextPage,
              onFinish: _completeOnboarding,
            ),
          ],
        ),
      ),
    );
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

    // 保存通知开关状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotificationEnabled, true);
  }

  Future<void> _completeOnboarding() async {
    await _onboardingManager.setCompleted();
    if (!mounted) return;
    context.go(AppConstants.routeTasks);
  }
}

/// 屏 1：欢迎 + 价值主张
class _WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 100,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            '欢迎使用 Tempo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '用智能待办管理你的日常任务\n语音/文本快速创建，LLM 自动解析日期',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

/// 屏 2：核心功能演示
class _FeaturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '核心功能',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _FeatureItem(
            icon: Icons.edit_outlined,
            title: '文本/语音创建',
            description: '输入或说出任务，自动解析截止时间和优先级',
          ),
          const SizedBox(height: 16),
          _FeatureItem(
            icon: Icons.calendar_month_outlined,
            title: '日历视图',
            description: '月视图查看任务分布，周视图查看时间安排',
          ),
          const SizedBox(height: 16),
          _FeatureItem(
            icon: Icons.sync,
            title: '思源同步导入',
            description: '一键导入思源笔记中的任务块',
          ),
        ],
      ),
    );
  }
}

/// 屏 3：通知权限请求
class _NotificationScreen extends StatelessWidget {
  final VoidCallback onEnableNotifications;
  final VoidCallback onFinish;

  const _NotificationScreen({
    required this.onEnableNotifications,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '开启提醒',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '允许通知权限，任务到期前 15 分钟\n和到期时各收到一条提醒',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              onEnableNotifications();
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('开启提醒'),
          ),
        ],
      ),
    );
  }
}

/// 功能项 Widget。
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 底部导航栏（进度指示器 + 按钮）。
class _BottomBar extends StatelessWidget {
  final int currentPage;
  final PageController pageController;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.currentPage,
    required this.pageController,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 进度指示器
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == currentPage
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          // 按钮
          if (currentPage < 2)
            FilledButton(
              onPressed: onNext,
              child: const Text('下一步'),
            )
          else
            FilledButton(
              onPressed: onFinish,
              child: const Text('开始使用'),
            ),
        ],
      ),
    );
  }
}
