// ============================================================
// RebuildObserver — 开发期 provider 重建计数观测
// 仅 kDebugMode 生效，集中 debugPrint，不污染 Release。
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 监听指定 provider 的重建次数，开发期 debugPrint。
///
/// 仅观测 [watchedProviders] 中列出的 provider name，避免全量噪音。
class RebuildObserver extends ProviderObserver {
  final Set<String> watchedProviders;

  final Map<String, int> _counts = {};

  RebuildObserver(this.watchedProviders);

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _record(provider);
  }

  @override
  void didAddProvider(
    ProviderBase<dynamic> provider,
    Object? value,
    ProviderContainer container,
  ) {
    _record(provider);
  }

  void _record(ProviderBase<dynamic> provider) {
    final name = provider.name;
    if (name == null || !watchedProviders.contains(name)) return;
    final next = (_counts[name] ?? 0) + 1;
    _counts[name] = next;
    debugPrint('[RebuildObserver] $name rebuilt: $next');
  }
}
