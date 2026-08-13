import 'package:flutter/material.dart';

import '../../core/money/money.dart';

/// Renders a [Money] value formatted for the active locale (intl) — the
/// single currency-formatting boundary; widgets never touch raw ints. The
/// underlying stored minor units are never altered by formatting (spec §4.2).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.currencyCode = false,
    this.maxLines,
    this.overflow,
  });

  final Money money;
  final TextStyle? style;

  /// When true, appends the ISO code (e.g. "$9.99 USD").
  final bool currencyCode;

  /// Optional line cap — prevents right-overflow of long amounts (e.g. VND)
  /// inside narrow ListTile trailing areas.
  final int? maxLines;

  final TextOverflow? overflow;

  /// Formats [money] for [locale] with its currency code — usable outside a
  /// widget tree (e.g. inline text composition in cards).
  static String renderMoney(
    Money money, {
    String locale = 'en_US',
    bool currencyCode = false,
  }) {
    final formatted = money.format(locale: locale);
    return currencyCode ? '$formatted ${money.currency}' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = money.format(locale: locale);
    final text = currencyCode ? '$formatted ${money.currency}' : formatted;
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.bodyLarge,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
