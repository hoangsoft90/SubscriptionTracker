import 'package:intl/intl.dart';

/// Exact monetary value: integer minor units + ISO 4217 currency code.
///
/// All arithmetic happens on [amountMinor] (int) — never on floating-point
/// `double` — so sums and projections are exact. Formatting to a display
/// string happens only at the UI boundary via [format].
class Money {
  const Money(this.amountMinor, this.currency);

  /// Integer minor units: $9.99 → 999, ₫79.000 → 79000, €12.50 → 1250.
  final int amountMinor;

  /// ISO 4217 currency code, e.g. USD, VND, EUR.
  final String currency;

  /// Decimal places per supported currency (spec §2.1).
  static const Map<String, int> currencyDecimals = {
    'USD': 2,
    'EUR': 2,
    'GBP': 2,
    'VND': 0,
    'JPY': 0,
    'KRW': 0,
  };

  /// Decimal places for this currency; defaults to 2 for unknown codes.
  int get decimals => currencyDecimals[currency] ?? 2;

  /// Parses a user-entered decimal string into exact minor units.
  ///
  /// Accepts thousand separators (`,` or `.`) and a decimal point for
  /// multi-decimal currencies. For 0-decimal currencies all separators are
  /// stripped. Throws [FormatException] on non-numeric input and on negative
  /// amounts (subscription prices are non-negative).
  factory Money.parse(String input, String currency) {
    final decimals = currencyDecimals[currency] ?? 2;
    var cleaned = input.trim().replaceAll(RegExp(r'\s'), '');

    if (decimals == 0) {
      cleaned = cleaned.replaceAll(RegExp(r'[.,]'), '');
      final minor = int.tryParse(cleaned);
      if (minor == null) {
        throw FormatException('Invalid amount for $currency: "$input"');
      }
      if (minor < 0) {
        throw FormatException('Amount must be non-negative: "$input"');
      }
      return Money(minor, currency);
    }

    // Multi-decimal currency: strip thousands separators, keep the last '.'
    // as the decimal point.
    cleaned = cleaned.replaceAll(',', '');
    final dot = cleaned.lastIndexOf('.');
    if (dot == -1) {
      final minor = int.tryParse(cleaned);
      if (minor == null) {
        throw FormatException('Invalid amount for $currency: "$input"');
      }
      if (minor < 0) {
        throw FormatException('Amount must be non-negative: "$input"');
      }
      return Money(minor * _pow10(decimals), currency);
    }

    var intPart = cleaned.substring(0, dot);
    var fracPart = cleaned.substring(dot + 1);
    if (intPart.isEmpty) intPart = '0';
    // Explicitly truncate excess fraction digits (documented behavior), e.g.
    // 12.345 → 12.34 for a 2-decimal currency.
    if (fracPart.length > decimals) {
      fracPart = fracPart.substring(0, decimals);
    }
    while (fracPart.length < decimals) {
      fracPart += '0';
    }
    final minor = int.tryParse(intPart + fracPart);
    if (minor == null) {
      throw FormatException('Invalid amount for $currency: "$input"');
    }
    if (minor < 0) {
      throw FormatException('Amount must be non-negative: "$input"');
    }
    return Money(minor, currency);
  }

  /// Adds another [Money] with the same currency, exactly (int arithmetic).
  ///
  /// Throws [ArgumentError] when currencies differ — the caller must group by
  /// currency first (see [sumByCurrency]).
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot add ${other.currency} to $currency; group by currency first',
      );
    }
    return Money(amountMinor + other.amountMinor, currency);
  }

  /// Formats as a display string using [locale] and this currency's decimals.
  ///
  /// Example: Money(1250, 'EUR') → "12.50"; Money(1250, 'VND') with
  /// locale `vi_VN` → "1.250".
  String format({String locale = 'en_US'}) {
    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    final formatter = NumberFormat(pattern, locale);
    return formatter.format(amountMinor / _pow10(decimals));
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amountMinor == amountMinor && other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => 'Money($amountMinor $currency)';
}

/// Groups a collection of [Money] by currency, summing minor units exactly
/// within each group. Never mixes currencies.
Map<String, int> sumByCurrency(Iterable<Money> amounts) {
  final totals = <String, int>{};
  for (final money in amounts) {
    totals[money.currency] = (totals[money.currency] ?? 0) + money.amountMinor;
  }
  return totals;
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}
