import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Convenience accessor: `context.l10n.xxx` instead of
/// `AppLocalizations.of(context)!.xxx`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Resolves a preset's display name by its stable key (`preset.*`), localized
/// through ARB. Keys never change; values are per-locale. Unknown keys fall
/// back to the key itself (defensive; catalog and ARB stay in sync).
String presetDisplayName(BuildContext context, String displayNameKey) {
  final l10n = context.l10n;
  return presetDisplayNames(l10n)[displayNameKey] ?? displayNameKey;
}

/// Key → localized value map (keys match `Preset.displayNameKey`).
Map<String, String> presetDisplayNames(AppLocalizations l10n) => {
      'preset.netflix': l10n.presetNetflix,
      'preset.spotify': l10n.presetSpotify,
      'preset.youtubePremium': l10n.presetYoutubePremium,
      'preset.appleMusic': l10n.presetAppleMusic,
      'preset.icloudPlus': l10n.presetIcloudPlus,
      'preset.googleOne': l10n.presetGoogleOne,
      'preset.amazonPrime': l10n.presetAmazonPrime,
      'preset.disneyPlus': l10n.presetDisneyPlus,
      'preset.chatgptPlus': l10n.presetChatgptPlus,
      'preset.adobeCc': l10n.presetAdobeCc,
      'preset.notion': l10n.presetNotion,
      'preset.githubPro': l10n.presetGithubPro,
      'preset.fptPlay': l10n.presetFptPlay,
      'preset.galaxyPlay': l10n.presetGalaxyPlay,
      'preset.vieon': l10n.presetVieon,
      'preset.zingMp3': l10n.presetZingMp3,
      'preset.nhaccuatui': l10n.presetNhaccuatui,
      'preset.kg': l10n.presetKg,
    };
