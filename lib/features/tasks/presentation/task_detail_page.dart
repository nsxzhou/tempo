import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/widgets/tempo/tempo.dart';
import '../domain/recurrence_models.dart';
import '../domain/task.dart';
import 'task_detail_actions.dart';
import 'widgets/task_detail_sections.dart';
import 'widgets/task_detail_top_bar.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  Task? _task;
  String? _listName;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingDesc = false;
  late final TextEditingController _descController;
  late final TaskDetailActions _actions;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _loadTask();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actions = TaskDetailActions(
      ref: ref,
      context: context,
      onTaskChanged: (task) => setState(() => _task = task),
      onSavingChanged: (saving) => setState(() => _isSaving = saving),
      getTask: () => _task,
      setLastDeletedTask: (_) {},
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    final cached = ref.read(taskByIdProvider(widget.taskId));
    if (cached != null && mounted) {
      setState(() {
        _task = cached;
        _descController.text = cached.description ?? '';
        _isLoading = false;
      });
    }

    final repository = ref.read(taskRepositoryProvider);
    final db = ref.read(databaseProvider);
    final task = await repository.getTaskById(widget.taskId);
    if (!mounted) return;
    if (task == null) {
      setState(() => _isLoading = false);
      TempoSnackbar.show(context, message: '任务不存在');
      context.pop();
      return;
    }
    final taskList = await db.getTaskListById(task.listId);
    if (!mounted) return;
    setState(() {
      _task = task;
      _listName = _resolveListName(task.listId, taskList?.name);
      _descController.text = task.description ?? '';
      _isLoading = false;
    });
  }

  String _resolveListName(String listId, String? dbName) {
    if (dbName != null && dbName.isNotEmpty) return dbName;
    if (listId == 'local-inbox') return AppConstants.defaultListName;
    return listId;
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = ref.watch(scaffoldBackgroundProvider);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task!;
    final background = ref
        .watch(taskBackgroundByTaskIdProvider(task.id))
        .valueOrNull;

    // 重复任务的「当前展示 occurrence」：从 displayOccurrenceListProvider 取，
    // 它已经按 nextOccurrence 算好了 state 与 occurrenceDate。
    // 单次任务直接用 series task 本身。
    final TaskOccurrenceView? recurringView = task.isRecurring
        ? ref
              .watch(displayOccurrenceListProvider)
              .where((v) => v.seriesTask.id == task.id)
              .firstOrNull
        : null;
    final displayTask = recurringView?.displayTask ?? task;
    final displayOccurrenceDate = recurringView?.occurrence.occurrenceDate;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          TaskDetailTopBar(
            onBack: () => context.pop(),
            onEdit: _actions.openEditSheet,
            onMore: _actions.showMoreMenu,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TaskDetailTitleBlock(task: task, background: background),
                  const SizedBox(height: 16),
                  TaskDetailProperties(task: task, listName: _listName),
                  if (task.isRecurring) ...[
                    const SizedBox(height: 16),
                    TaskDetailRecurrenceSection(task: task),
                  ],
                  const SizedBox(height: 16),
                  TaskDetailDescription(
                    task: task,
                    controller: _descController,
                    isEditing: _isEditingDesc,
                    onStartEdit: () => setState(() => _isEditingDesc = true),
                    onCancelEdit: () => setState(() {
                      _isEditingDesc = false;
                      _descController.text = task.description ?? '';
                    }),
                    onSave: () {
                      setState(() => _isEditingDesc = false);
                      _actions.saveDescription(_descController.text.trim());
                    },
                  ),
                  if (task.siyuanBlockId != null) ...[
                    const SizedBox(height: 16),
                    TaskDetailSiyuanCard(task: task),
                  ],
                  const SizedBox(height: 16),
                  TaskDetailReadOnlyInfo(task: task),
                  const SizedBox(height: 24),
                  if (!task.isRecurring ||
                      !task.isRecurrenceEnded(DateTime.now()))
                    TaskDetailCompleteButton(
                      task: displayTask,
                      isSaving: _isSaving,
                      onPressed: () {
                        // 重复任务用 displayTask（含 occurrence 状态），
                        // 这样 toggleComplete 才能正确判断 complete=!isCompleted。
                        _actions.toggleComplete(
                          displayTask,
                          occurrenceDate: displayOccurrenceDate,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
