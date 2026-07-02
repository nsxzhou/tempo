import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/utils/date_utils.dart';

void main() {
  test('formatOccurrenceDateQuery and parseOccurrenceDateQuery roundtrip', () {
    final day = DateTime(2026, 6, 30);
    final query = formatOccurrenceDateQuery(day);
    expect(query, '2026-06-30');
    expect(parseOccurrenceDateQuery(query), DateTime(2026, 6, 30));
  });

  test('parseOccurrenceDateQuery rejects invalid values', () {
    expect(parseOccurrenceDateQuery(null), isNull);
    expect(parseOccurrenceDateQuery(''), isNull);
    expect(parseOccurrenceDateQuery('2026/06/30'), isNull);
    expect(parseOccurrenceDateQuery('bad-date'), isNull);
  });
}
