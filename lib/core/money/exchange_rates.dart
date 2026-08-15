/// Exchange-rate support for the multi-currency Home report.
///
/// Rates are expressed as *units of each currency per 1 USD* (the pivot), so
/// any currency can be converted to any other through USD without storing
/// pairwise tables. Conversion is for REPORTING ONLY — stored amounts keep
/// their own currency and are never mutated.
///
/// Source precedence: live rates fetched from a free public API win when the
/// device is online; the manual rates below (editable in Settings) are the
/// offline fallback. Widget tests never hit the network (see [canFetchLive]).
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'money.dart';

/// Fallback manual rates (units per 1 USD) — approximate, used only when the
/// live fetch fails (offline / API unreachable). Editable in Settings.
const Map<String, double> defaultManualExchangeRates = {
  'USD': 1.0,
  'VND': 25400.0,
  'EUR': 0.92,
  'GBP': 0.79,
  'JPY': 156.0,
  'KRW': 1380.0,
};

/// True when a live fetch may run: not in widget tests (no network / no real
/// http in the fake-async zone) and not on web (CORS + unreliable for a
/// reporting fallback — manual rates keep web deterministic).
bool get canFetchLive =>
    !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

/// Converts [amountMinor] from [from] currency to [primary] currency through
/// the USD pivot, returning minor units of the target (rounded). Returns null
/// when either rate is missing — the caller then falls back to per-currency
/// display for that amount (never invents a rate).
///
/// Math: amount → units (÷ 10^decimals) → USD (÷ rate[from]) → target units
/// (× rate[to]) → target minor (× 10^decimals, rounded).
int? convertMinorToPrimary({
  required int amountMinor,
  required String from,
  required String to,
  required Map<String, double> rates,
}) {
  if (from == to) return amountMinor;
  final rateFrom = rates[from];
  final rateTo = rates[to];
  if (rateFrom == null || rateTo == null || rateFrom <= 0 || rateTo <= 0) {
    return null;
  }
  final decimalsFrom = Money.currencyDecimals[from] ?? 2;
  final decimalsTo = Money.currencyDecimals[to] ?? 2;
  final units = amountMinor / _pow10(decimalsFrom);
  final usd = units / rateFrom;
  final targetUnits = usd * rateTo;
  return (targetUnits * _pow10(decimalsTo)).round();
}

/// Converts every value in [byCurrency] (minor units) to [to] currency.
/// Values whose rate is missing are skipped — returns the sum of the
/// convertible ones. Used for savings maps (per-currency projections).
int sumConvertedTo({
  required Map<String, int> byCurrency,
  required String to,
  required Map<String, double> rates,
}) {
  var total = 0;
  for (final entry in byCurrency.entries) {
    final converted = convertMinorToPrimary(
      amountMinor: entry.value,
      from: entry.key,
      to: to,
      rates: rates,
    );
    if (converted != null) total += converted;
  }
  return total;
}

/// Fetches live rates (units per 1 USD) from a free public API
/// (open.er-api.com, no key, ~24h refresh). Returns the raw `rates` map, or
/// an empty map on any failure (caller keeps the manual fallback).
///
/// [client] is injectable for tests; when null a short-lived client is used.
Future<Map<String, double>> fetchLiveRates({http.Client? client}) async {
  final http.Client effective = client ?? http.Client();
  try {
    final response = await effective
        .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return const {};
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success') return const {};
    final rawRates = body['rates'] as Map<String, dynamic>? ?? const {};
    return {
      for (final entry in rawRates.entries)
        entry.key: (entry.value as num).toDouble(),
    };
  } catch (_) {
    return const {};
  } finally {
    if (client == null) effective.close();
  }
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}
