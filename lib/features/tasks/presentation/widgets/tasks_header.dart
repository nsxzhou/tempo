import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';

class TasksPageHeader extends StatelessWidget {
  final bool showSearch;
  final VoidCallback onSearchToggle;

  const TasksPageHeader({
    super.key,
    required this.showSearch,
    required this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat('M 月 d 日 · EEEE', 'zh_CN').format(now);
    final tokens = context.tokens;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODO',
                    style: tokens.sansSemibold(
                      size: 32,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateText,
                    style: tokens.mono(
                      size: 12,
                      color: tokens.fgMuted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSearchToggle,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: showSearch ? tokens.bgSubtle : tokens.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: showSearch ? tokens.fg : tokens.borderStrong,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  LucideIcons.search,
                  size: 14,
                  color: tokens.fgSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksSearchBar extends StatelessWidget {
  final bool visible;
  final ValueChanged<String> onChanged;

  const TasksSearchBar({
    super.key,
    required this.visible,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedSize(
      duration: AppTheme.durationMedium,
      curve: AppTheme.curveOrganic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: AnimatedOpacity(
        duration: AppTheme.durationMedium,
        curve: AppTheme.curveOrganic,
        opacity: visible ? 1 : 0,
        child: visible
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bgMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, size: 14, color: t.fgSubtle),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: onChanged,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: '检索日常任务或内容…',
                            hintStyle: t.mono(size: 12, color: t.fgSubtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }
}
