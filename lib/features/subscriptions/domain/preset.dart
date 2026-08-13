/// A subscription preset for the onboarding catalog (spec §6).
///
/// Presets NEVER hard-code prices or billing cycles — they only pre-fill
/// name/category/icon and an optional validated cancellation URL, plus an
/// optional trial-duration *suggestion* labelled "Suggested, please verify".
class Preset {
  const Preset({
    required this.id,
    required this.displayNameKey,
    required this.category,
    required this.icon,
    this.cancellationUrl,
    this.trialDurationSuggestionDays,
  });

  final String id;

  /// Localization key for the display name (never a hard-coded string).
  final String displayNameKey;

  /// Category id (one of the default categories).
  final String category;

  /// Generic emoji icon — never a brand logo.
  final String icon;

  /// Optional, validated cancellation URL (region-specific packs).
  final String? cancellationUrl;

  /// Suggestion only — the UI labels it "Suggested, please verify".
  final int? trialDurationSuggestionDays;
}
