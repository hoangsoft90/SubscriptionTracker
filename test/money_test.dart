import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:subtrack/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('parses 2-decimal currency (USD)', () {
      final money = Money.parse('9.99', 'USD');
      expect(money.amountMinor, 999);
      expect(money.currency, 'USD');
    });

    test('parses 2-decimal currency with thousands separator', () {
      final money = Money.parse('1,250.50', 'USD');
      expect(money.amountMinor, 125050);
    });

    test('parses 0-decimal currency (VND)', () {
      final money = Money.parse('79000', 'VND');
      expect(money.amountMinor, 79000);
      expect(money.currency, 'VND');
    });

    test('parses 0-decimal currency with dot thousands separator', () {
      final money = Money.parse('1.250', 'VND');
      expect(money.amountMinor, 1250);
    });

    test('parses 0-decimal currency with comma thousands separator', () {
      final money = Money.parse('79,000', 'VND');
      expect(money.amountMinor, 79000);
    });

    test('parses euro with 2 decimals', () {
      final money = Money.parse('12.50', 'EUR');
      expect(money.amountMinor, 1250);
    });

    test('rejects non-numeric input', () {
      expect(() => Money.parse('abc', 'USD'), throwsFormatException);
      expect(() => Money.parse('', 'USD'), throwsFormatException);
    });

    test('rejects negative amounts', () {
      expect(() => Money.parse('-9.99', 'USD'), throwsFormatException);
      expect(() => Money.parse('-5000', 'VND'), throwsFormatException);
    });

    test('truncates excess fraction digits (documented)', () {
      expect(Money.parse('12.345', 'USD').amountMinor, 1234);
      expect(Money.parse('0.999', 'USD').amountMinor, 99);
    });
  });

  group('Money.format', () {
    test('formats 2-decimal currency', () {
      expect(const Money(1250, 'EUR').format(), '12.50');
      expect(const Money(999, 'USD').format(), '9.99');
    });

    test('formats 0-decimal currency with en_US locale', () {
      expect(const Money(1250, 'VND').format(), '1,250');
    });

    test('formats 0-decimal currency with vi_VN locale', () async {
      await initializeDateFormatting('vi_VN', null);
      expect(const Money(1250, 'VND').format(locale: 'vi_VN'), '1.250');
      expect(const Money(79000, 'VND').format(locale: 'vi_VN'), '79.000');
    });
  });

  group('Money arithmetic', () {
    test('sum is exact with no floating-point drift', () {
      const a = Money(999, 'USD');
      const b = Money(1299, 'USD');
      const c = Money(499, 'USD');
      expect((a + b + c).amountMinor, 2797);
    });

    test('addition rejects mixed currencies', () {
      const usd = Money(100, 'USD');
      const vnd = Money(100, 'VND');
      expect(() => usd + vnd, throwsArgumentError);
    });

    test('sumByCurrency groups and never mixes', () {
      final amounts = [
        const Money(1000, 'USD'),
        const Money(500, 'USD'),
        const Money(20000, 'VND'),
      ];
      final totals = sumByCurrency(amounts);
      expect(totals['USD'], 1500);
      expect(totals['VND'], 20000);
      expect(totals.keys, containsAll(['USD', 'VND']));
    });

    test('sumByCurrency handles empty input', () {
      expect(sumByCurrency(const []), isEmpty);
    });
  });
}
