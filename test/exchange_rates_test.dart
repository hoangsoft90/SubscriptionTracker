import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/money/exchange_rates.dart';

void main() {
  group('convertMinorToPrimary (USD pivot)', () {
    // Rates: units per 1 USD. 1 USD = 25400 VND = 0.92 EUR.
    const rates = {
      'USD': 1.0,
      'VND': 25400.0,
      'EUR': 0.92,
    };

    test('same currency returns the amount unchanged', () {
      expect(
        convertMinorToPrimary(
          amountMinor: 999,
          from: 'USD',
          to: 'USD',
          rates: rates,
        ),
        999,
      );
    });

    test('USD → VND converts through the pivot', () {
      // $9.99 → 9.99 * 25400 = 253,746 VND (VND has 0 decimals).
      expect(
        convertMinorToPrimary(
          amountMinor: 999,
          from: 'USD',
          to: 'VND',
          rates: rates,
        ),
        253746,
      );
    });

    test('VND → USD converts back (rounding to 2 decimals)', () {
      // 253,746 VND → 9.9900 USD → 999 minor.
      expect(
        convertMinorToPrimary(
          amountMinor: 253746,
          from: 'VND',
          to: 'USD',
          rates: rates,
        ),
        999,
      );
    });

    test('VND → EUR converts through USD', () {
      // 25,400 VND = 1 USD = 0.92 EUR → 92 minor (EUR has 2 decimals).
      expect(
        convertMinorToPrimary(
          amountMinor: 25400,
          from: 'VND',
          to: 'EUR',
          rates: rates,
        ),
        92,
      );
    });

    test('missing or non-positive rate returns null (never invents)', () {
      expect(
        convertMinorToPrimary(
          amountMinor: 100,
          from: 'XYZ',
          to: 'USD',
          rates: rates,
        ),
        isNull,
      );
      expect(
        convertMinorToPrimary(
          amountMinor: 100,
          from: 'USD',
          to: 'XYZ',
          rates: rates,
        ),
        isNull,
      );
      expect(
        convertMinorToPrimary(
          amountMinor: 100,
          from: 'USD',
          to: 'VND',
          rates: {...rates, 'VND': 0.0},
        ),
        isNull,
      );
    });

    test('zero amount converts to zero', () {
      expect(
        convertMinorToPrimary(
          amountMinor: 0,
          from: 'USD',
          to: 'VND',
          rates: rates,
        ),
        0,
      );
    });
  });

  group('sumConvertedTo', () {
    const rates = {'USD': 1.0, 'VND': 25400.0};

    test('sums converted minor units across currencies', () {
      // $10 + 254,000 VND (= $10) → $20 → 2000 minor.
      expect(
        sumConvertedTo(
          byCurrency: {'USD': 1000, 'VND': 254000},
          to: 'USD',
          rates: rates,
        ),
        2000,
      );
    });

    test('skips currencies without a rate', () {
      expect(
        sumConvertedTo(
          byCurrency: {'USD': 1000, 'XYZ': 500},
          to: 'USD',
          rates: rates,
        ),
        1000,
      );
    });

    test('empty map sums to zero', () {
      expect(sumConvertedTo(byCurrency: const {}, to: 'USD', rates: rates), 0);
    });
  });

  group('default manual rates', () {
    test('USD pivot is 1.0 and every supported currency is present', () {
      expect(defaultManualExchangeRates['USD'], 1.0);
      for (final currency in ['VND', 'EUR', 'GBP', 'JPY', 'KRW']) {
        expect(
          defaultManualExchangeRates[currency],
          isNotNull,
          reason: 'missing default rate for $currency',
        );
        expect(defaultManualExchangeRates[currency]!, greaterThan(0));
      }
    });
  });

  group('canFetchLive', () {
    test('is false under flutter test (never hits the network)', () {
      // FLUTTER_TEST is set in the test runner — live fetch must be skipped
      // so widget/unit tests are deterministic and offline-safe.
      expect(canFetchLive, isFalse);
    });
  });
}
