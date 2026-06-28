// ============================================================
// TaskTile — 任务列表项
// 紧凑单行：标题 + 右对齐分类；左滑删除；44px 勾选热区
// 完成：删除线 → 高度折叠 + 淡出至 0.6 → 移入已完成区
// 删除：左滑 + 淡出
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';
import '../../domain/task.dart';
import 'task_background_image.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;
  final bool showDelete;
  final String? backgroundImagePath;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
    this.showDelete = false,
    this.backgroundImagePath,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  static const double _tileHeight = 52;
  static const double _checkboxHitSize = 44;
  static const double _deleteActionExtentRatio = 0.14;

  bool _localCompleted = false;
  bool _isCollapsing = false;
  bool _isDeleting = false;
  double _contentOpacity = 1;

  @override
  void initState() {
    super.initState();
    _localCompleted = widget.task.isCompleted;
    _contentOpacity = widget.task.isCompleted ? 0.6 : 1;
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id) {
      _localCompleted = widget.task.isCompleted;
      _isCollapsing = false;
      _isDeleting = false;
      _contentOpacity = widget.task.isCompleted ? 0.6 : 1;
      return;
    }
    if (!oldWidget.task.isCompleted &&
        widget.task.isCompleted &&
        !_isCollapsing) {
      _localCompleted = true;
      _contentOpacity = 0.6;
    } else if (widget.task.isCompleted != _localCompleted &&
        !widget.task.isCompleted) {
      _localCompleted = false;
      _contentOpacity = 1;
    }
  }

  String? get _categoryLabel {
    if (widget.task.tag == AppConstants.tagWork) return '@工作';
    if (widget.task.tag == AppConstants.tagLife) return '@生活';
    return null;
  }

  Widget _wrapGlassShell({required bool completed, required Widget child}) {
    final backgroundPath = widget.backgroundImagePath;
    if (backgroundPath != null) {
      return _wrapImageShell(
        completed: completed,
        imagePath: backgroundPath,
        child: child,
      );
    }

    final tokens = context.tokens;
    final cardColor = tokens.taskCardBackground;
    return TempoGlassSurface(
      blur: false,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      fillColor: cardColor,
      borderColor: completed ? tokens.borderSubtle : tokens.borderStrong,
      showShadow: !completed,
      child: child,
    );
  }

  Widget _wrapImageShell({
    required bool completed,
    required String imagePath,
    required Widget child,
  }) {
    final tokens = context.tokens;
    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);
    final borderColor = completed ? tokens.borderSubtle : tokens.borderStrong;
    final overlayAlpha = completed ? 0.58 : 0.24;
    final gradientAlpha = completed ? 0.06 : 0.05;

    return RepaintBoundary(
      child: SizedBox(
        height: _tileHeight,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: completed ? null : AppTheme.shadowSm,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: TaskBackgroundImage(
                    path: imagePath,
                    errorColor: tokens.taskCardBackground,
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: tokens.bg.withValues(alpha: overlayAlpha),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.fg.withValues(alpha: gradientAlpha),
                          tokens.bg.withValues(alpha: 0),
                          tokens.bg.withValues(alpha: gradientAlpha),
                        ],
                        stops: const [0, 0.52, 1],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleToggle() async {
    if (_localCompleted) {
      widget.onToggleComplete?.call();
      return;
    }

    setState(() => _localCompleted = true);

    await Future<void>.delayed(AppTheme.durationFast);
    if (!mounted) return;

    setState(() {
      _isCollapsing = true;
      _contentOpacity = 0.6;
    });

    await Future<void>.delayed(AppTheme.durationMedium);
    if (!mounted) return;

    widget.onToggleComplete?.call();
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    await Future<void>.delayed(AppTheme.durationFast);
    if (!mounted) return;
    widget.onDelete?.call();
  }

  Widget _buildRowContent() {
    final t = context.tokens;
    final category = _categoryLabel;
    final completed = _localCompleted;

    return Row(
      children: [
        SizedBox(
          width: _checkboxHitSize,
          height: _checkboxHitSize,
          child: Center(
            child: TempoCheckbox(
              value: completed,
              onChanged: (_) => _handleToggle(),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.only(right: category != null ? 8 : 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: AppTheme.durationFast,
                        curve: AppTheme.curveOrganic,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: completed ? t.fgMuted : t.fg,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        child: Text(
                          widget.task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (category != null)
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: t.fgMuted,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedShell({required Widget child}) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: _isDeleting ? 0 : _contentOpacity,
        duration: AppTheme.durationFast,
        curve: Curves.easeInCubic,
        child: AnimatedSlide(
          offset: _isDeleting ? const Offset(-0.15, 0) : Offset.zero,
          duration: AppTheme.durationFast,
          curve: Curves.easeInCubic,
          child: AnimatedSize(
            duration: AppTheme.durationMedium,
            curve: AppTheme.curveOrganic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: _isCollapsing
                ? const SizedBox(width: double.infinity, height: 0)
                : SizedBox(
                    height: _tileHeight,
                    width: double.infinity,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandaloneCard() {
    return Material(
      color: Colors.transparent,
      child: _wrapGlassShell(
        completed: _localCompleted,
        child: _buildAnimatedShell(child: _buildRowContent()),
      ),
    );
  }

  Widget _buildSlidableShell() {
    final t = context.tokens;
    return _wrapGlassShell(
      completed: _localCompleted,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Slidable(
          key: ValueKey('task-slidable-${widget.task.id}'),
          closeOnScroll: true,
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: _deleteActionExtentRatio,
            dragDismissible: false,
            children: [
              CustomSlidableAction(
                onPressed: (_) => _handleDelete(),
                backgroundColor: AppTheme.priorityP0,
                foregroundColor: t.bg,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.zero,
                child: Semantics(
                  button: true,
                  label: '删除',
                  child: Center(
                    child: Icon(LucideIcons.trash_2, size: 16, color: t.bg),
                  ),
                ),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: _buildAnimatedShell(child: _buildRowContent()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSwipeDelete = widget.showDelete && widget.onDelete != null;
    if (!canSwipeDelete) {
      return _buildStandaloneCard();
    }
    return _buildSlidableShell();
  }
}
