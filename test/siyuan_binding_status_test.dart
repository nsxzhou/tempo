import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_pill_badge.dart';
import 'package:tempo/features/settings/data/siyuan_pairing_service.dart';
import 'package:tempo/features/settings/presentation/siyuan_status_display.dart';

void main() {
  group('SiyuanBindingStatus', () {
    test('hasSynced when lastSyncAt is set', () {
      const status = SiyuanBindingStatus(isPaired: true, lastSyncAt: null);
      expect(status.hasSynced, isFalse);

      final synced = status.copyWith(lastSyncAt: DateTime(2026, 6, 22, 15, 30));
      expect(synced.hasSynced, isTrue);
    });
  });

  group('siyuanIntegrationBadge', () {
    test('paired without sync shows 待连通', () {
      const status = SiyuanBindingStatus(isPaired: true);
      final badge = siyuanIntegrationBadge(status);

      expect(badge.label, '待连通');
      expect(badge.kind, TempoBadgeKind.neutral);
    });

    test('paired with sync shows 已连通', () {
      final status = SiyuanBindingStatus(
        isPaired: true,
        lastSyncAt: DateTime(2026, 6, 22, 15, 30),
      );
      final badge = siyuanIntegrationBadge(status);

      expect(badge.label, '已连通');
      expect(badge.kind, TempoBadgeKind.success);
    });

    test('pending code shows 待配对', () {
      final status = SiyuanBindingStatus(
        isPaired: false,
        pendingCode: PairingCode(
          code: '123456',
          userId: 'user-id',
          userEmail: 'test@example.com',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          createdAt: DateTime.now(),
        ),
      );
      final badge = siyuanIntegrationBadge(status);

      expect(badge.label, '待配对');
    });

    test('unpaired shows 未启用', () {
      const status = SiyuanBindingStatus(isPaired: false);
      final badge = siyuanIntegrationBadge(status);

      expect(badge.label, '未启用');
    });

    test('status load failure shows 连接异常', () {
      const status = SiyuanBindingStatus(
        isPaired: false,
        statusLoadFailed: true,
      );
      final badge = siyuanIntegrationBadge(status);

      expect(badge.label, '连接异常');
      expect(badge.kind, TempoBadgeKind.error);
    });
  });

  group('siyuanIntegrationSubtitle', () {
    test('paired without sync explains plugin pairing', () {
      const status = SiyuanBindingStatus(isPaired: true);
      expect(siyuanIntegrationSubtitle(status), '云端已记录绑定 · 请在思源插件输入配对码');
    });

    test('status load failure asks user to retry', () {
      const status = SiyuanBindingStatus(
        isPaired: false,
        statusLoadFailed: true,
      );
      expect(siyuanIntegrationSubtitle(status), contains('点击重试'));
    });

    test('paired with sync shows last sync summary', () {
      final status = SiyuanBindingStatus(
        isPaired: true,
        lastSyncAt: DateTime(2026, 6, 22, 15, 30),
        lastImportedCount: 3,
      );
      expect(siyuanIntegrationSubtitle(status), contains('最近同步'));
      expect(siyuanIntegrationSubtitle(status), contains('导入 3 项'));
    });
  });

  group('siyuanManageSheetSubtitle', () {
    test('paired without sync guides plugin input', () {
      const status = SiyuanBindingStatus(isPaired: true);
      expect(siyuanManageSheetSubtitle(status), contains('请在思源插件输入配对码'));
    });
  });
}

extension on SiyuanBindingStatus {
  SiyuanBindingStatus copyWith({DateTime? lastSyncAt}) {
    return SiyuanBindingStatus(
      isPaired: isPaired,
      statusLoadFailed: statusLoadFailed,
      pairedAt: pairedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastImportedCount: lastImportedCount,
      pluginVersion: pluginVersion,
      pendingCode: pendingCode,
    );
  }
}
