// ============================================================
// SiyuanStatusDisplay — 思源绑定状态文案与 Badge 映射（纯函数，便于单测）
// ============================================================

import '../../../core/widgets/tempo/src/tempo_pill_badge.dart';
import '../data/siyuan_pairing_service.dart';

/// 设置页集成行副标题。
String siyuanIntegrationSubtitle(SiyuanBindingStatus status) {
  if (status.statusLoadFailed) {
    return '连接状态暂时不可用，点击重试';
  }
  if (status.isPaired) {
    return '已与思源插件绑定，任务通过 Supabase 同步';
  }
  if (status.hasPendingCode) {
    return '配对码已生成，请在思源插件中输入';
  }
  return '在思源插件中输入配对码完成绑定';
}

/// 设置页集成行 Badge。
({TempoBadgeKind kind, String label}) siyuanIntegrationBadge(
  SiyuanBindingStatus status,
) {
  if (status.statusLoadFailed) {
    return (kind: TempoBadgeKind.error, label: '连接异常');
  }
  if (status.isPaired) {
    return (kind: TempoBadgeKind.success, label: '已绑定');
  }
  if (status.hasPendingCode) {
    return (kind: TempoBadgeKind.neutral, label: '待配对');
  }
  return (kind: TempoBadgeKind.neutral, label: '未启用');
}

/// 管理 Sheet 顶部状态说明。
String siyuanManageSheetSubtitle(SiyuanBindingStatus status) {
  if (status.statusLoadFailed) {
    return '暂时无法读取思源连接状态，请稍后重试';
  }
  if (status.isPaired) {
    return '已与思源插件绑定，任务通过 Supabase 同步';
  }
  return '尚未与思源插件建立连接';
}
