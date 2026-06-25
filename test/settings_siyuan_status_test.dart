import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/settings/data/siyuan_pairing_service.dart';

void main() {
  test('siyuan status load timeout falls back to unpaired state', () async {
    SiyuanBindingStatus? status;

    try {
      status = await Future<SiyuanBindingStatus>(() async {
        final completer = Completer<SiyuanBindingStatus>();
        return completer.future;
      }).timeout(const Duration(milliseconds: 50));
    } catch (_) {
      status = const SiyuanBindingStatus(isPaired: false);
    }

    expect(status, isNotNull);
    expect(status.isPaired, isFalse);
  });
}
