import 'package:flutter/material.dart';

/// 日历页（月视图 + 周视图）
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('日历视图', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('月视图 + 周视图', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
