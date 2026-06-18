import 'package:flutter/material.dart';

/// 设置页
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('设置', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('账户 · 思源同步 · 通知 · 关于', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
