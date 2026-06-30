import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';

class TaskDetailTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const TaskDetailTopBar({
    super.key,
    required this.onBack,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(LucideIcons.chevron_left, size: 16),
              label: const Text('返回'),
              style: TextButton.styleFrom(foregroundColor: t.fgSecondary),
            ),
            const Spacer(),
            TaskDetailIconBtn(icon: LucideIcons.pencil, onTap: onEdit),
            const SizedBox(width: 6),
            TaskDetailIconBtn(icon: LucideIcons.ellipsis, onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class TaskDetailIconBtn extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onTap;

  const TaskDetailIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cardColor = ref.watch(taskCardBackgroundProvider);
    return TempoGlassSurface(
      blur: false,
      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      fillColor: cardColor,
      showShadow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 14, color: t.fgSecondary),
          ),
        ),
      ),
    );
  }
}
