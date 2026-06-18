// ============================================================
// InlineTaskInput — 顶部 inline 输入框组件
// 输入标题 + 回车创建任务，集成 LLM 日期解析 + 离线降级 DatePicker
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';
import '../../data/voice_task_parse_result.dart';

/// inline 任务输入框组件。
///
/// 输入标题回车后：
/// 1. 调用 TextParseService 尝试解析日期/优先级
/// 2. 网络不可用/解析失败 → 弹出 DatePicker 降级
/// 3. 解析成功 → 直接创建任务
class InlineTaskInput extends ConsumerStatefulWidget {
  final void Function(Task? createdTask)? onTaskCreated;

  const InlineTaskInput({
    super.key,
    this.onTaskCreated,
  });

  @override
  ConsumerState<InlineTaskInput> createState() => _InlineTaskInputState();
}

class _InlineTaskInputState extends ConsumerState<InlineTaskInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isParsing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '输入任务标题，回车创建...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.add, size: 20),
                suffixIcon: _isParsing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: _showDatePickerAndCreate,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理回车提交：先尝试 LLM 解析，失败降级 DatePicker。
  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isParsing = true);

    try {
      final parseService = ref.read(textParseServiceProvider);
      final result = await parseService.parseText(text);

      if (!mounted) return;

      if (result != null) {
        // LLM 解析成功 → 直接创建
        await _createTask(
          title: result.title.isNotEmpty ? result.title : text,
          dueDate: result.dueDate,
          priority: result.priority,
        );
      } else {
        // 降级：弹出 DatePicker 手动选择
        await _showDatePickerAndCreate(initialTitle: text);
      }
    } catch (error) {
      if (!mounted) return;
      // 出错时仍然创建任务（不带日期）
      await _createTask(title: text);
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  /// 弹出 DatePicker 手动选择日期后创建任务。
  Future<void> _showDatePickerAndCreate({
    String? initialTitle,
  }) async {
    final title = initialTitle ?? _controller.text.trim();
    if (title.isEmpty) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || pickedDate == null) {
      // 用户跳过日期选择，直接创建不带日期的任务
      if (title.isNotEmpty) {
        await _createTask(title: title);
      }
      return;
    }

    // 选择时间
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(pickedDate),
    );

    DateTime? dueDate;
    if (pickedTime != null) {
      dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    } else {
      dueDate = pickedDate;
    }

    if (!mounted) return;
    await _createTask(title: title, dueDate: dueDate);
  }

  /// 创建任务并清空输入框。
  Future<void> _createTask({
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.none,
  }) async {
    final repository = ref.read(taskRepositoryProvider);
    final task = await repository.createTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
    );

    // 调度通知
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleTaskReminder(task);

    if (!mounted) return;

    _controller.clear();
    _focusNode.requestFocus();
    widget.onTaskCreated?.call(task);
  }
}
