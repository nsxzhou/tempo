import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/settings/data/siyuan_pairing_service.dart';

void main() {
  group('SiyuanBindingStatus', () {
    test('hasSynced when lastSyncAt is set', () {
      const status = SiyuanBindingStatus(
        isPaired: true,
        lastSyncAt: null,
      );
      expect(status.hasSynced, isFalse);

      final synced = status.copyWith(
        lastSyncAt: DateTime(2026, 6, 22, 15, 30),
      );
      expect(synced.hasSynced, isTrue);
    });
  });
}

extension on SiyuanBindingStatus {
  SiyuanBindingStatus copyWith({DateTime? lastSyncAt}) {
    return SiyuanBindingStatus(
      isPaired: isPaired,
      pairedAt: pairedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastImportedCount: lastImportedCount,
      pluginVersion: pluginVersion,
      pendingCode: pendingCode,
    );
  }
}
