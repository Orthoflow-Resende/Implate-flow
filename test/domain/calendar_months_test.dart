import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('addCalendarMonths uses calendar months, not 30-day multiples', () {
    expect(addCalendarMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addCalendarMonths(DateTime(2026, 1, 15), 3), DateTime(2026, 4, 15));
    expect(addCalendarMonths(DateTime(2026, 10, 15), 6), DateTime(2027, 4, 15));
  });
}
