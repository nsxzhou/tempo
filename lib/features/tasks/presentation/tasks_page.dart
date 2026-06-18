import 'package:flutter/material.dart';

/// 任务列表页（Phase 1 核心页面）
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tempo')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('任务列表', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phase 1 实现', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 新建任务
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
