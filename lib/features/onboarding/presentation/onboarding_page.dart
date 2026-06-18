import 'package:flutter/material.dart';

/// 首次使用引导页（3 屏 onboarding）
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.waving_hand, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('欢迎使用 Tempo', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              const Text('3 屏引导流程', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () {
                  // TODO: 完成引导，跳转主页
                },
                child: const Text('开始使用'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
