import 'package:flutter/material.dart';

/// AI 日计划页（Phase 2）
class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 计划')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('AI 日计划', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phase 2 实现', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
