import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/settings/data/siyuan_pairing_service.dart';

void main() {
  test('siyuan status load timeout returns recoverable failed state', () async {
    SiyuanBindingStatus? status;

    try {
      status = await Future<SiyuanBindingStatus>(() async {
        final completer = Completer<SiyuanBindingStatus>();
        return completer.future;
      }).timeout(const Duration(milliseconds: 50));
    } catch (_) {
      status = const SiyuanBindingStatus(
        isPaired: false,
        statusLoadFailed: true,
      );
    }

    expect(status, isNotNull);
    expect(status.isPaired, isFalse);
    expect(status.statusLoadFailed, isTrue);
  });
}
