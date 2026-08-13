import '../domain/preset.dart';

/// Onboarding preset catalog (spec §6): global + VN packs.
///
/// Display names are localization keys (`preset.` prefix). No prices or
/// billing cycles are stored — markets change.
class PresetCatalog {
  PresetCatalog._();

  /// Every preset across both packs (global + VN), for pre-fill lookups.
  static const List<Preset> all = [...global, ...vietnam];

  static const global = <Preset>[
    Preset(
      id: 'netflix',
      displayNameKey: 'preset.netflix',
      category: 'streaming',
      icon: '🎬',
      cancellationUrl: 'https://www.netflix.com/account/cancelmembership',
    ),
    Preset(
      id: 'spotify',
      displayNameKey: 'preset.spotify',
      category: 'music',
      icon: '🎵',
      cancellationUrl: 'https://www.spotify.com/account/subscription/',
    ),
    Preset(
      id: 'youtube-premium',
      displayNameKey: 'preset.youtubePremium',
      category: 'streaming',
      icon: '▶️',
      cancellationUrl: 'https://www.youtube.com/premium',
    ),
    Preset(
      id: 'apple-music',
      displayNameKey: 'preset.appleMusic',
      category: 'music',
      icon: '🍎',
      cancellationUrl: 'https://support.apple.com/HT203984',
    ),
    Preset(
      id: 'icloud-plus',
      displayNameKey: 'preset.icloudPlus',
      category: 'cloud-storage',
      icon: '☁️',
    ),
    Preset(
      id: 'google-one',
      displayNameKey: 'preset.googleOne',
      category: 'cloud-storage',
      icon: '🗄️',
    ),
    Preset(
      id: 'amazon-prime',
      displayNameKey: 'preset.amazonPrime',
      category: 'shopping',
      icon: '📦',
      cancellationUrl: 'https://www.amazon.com/gp/help/customer/display.html?nodeId=GZ3KJLQYY4YGY2GB',
    ),
    Preset(
      id: 'disney-plus',
      displayNameKey: 'preset.disneyPlus',
      category: 'streaming',
      icon: '✨',
      cancellationUrl: 'https://www.disneyplus.com/account',
    ),
    Preset(
      id: 'chatgpt-plus',
      displayNameKey: 'preset.chatgptPlus',
      category: 'productivity',
      icon: '🤖',
      trialDurationSuggestionDays: 30,
    ),
    Preset(
      id: 'adobe-cc',
      displayNameKey: 'preset.adobeCc',
      category: 'design',
      icon: '🎨',
    ),
    Preset(
      id: 'notion',
      displayNameKey: 'preset.notion',
      category: 'productivity',
      icon: '📝',
    ),
    Preset(
      id: 'github-pro',
      displayNameKey: 'preset.githubPro',
      category: 'developer-tools',
      icon: '🐙',
    ),
  ];

  static const vietnam = <Preset>[
    Preset(
      id: 'fpt-play',
      displayNameKey: 'preset.fptPlay',
      category: 'streaming',
      icon: '📺',
    ),
    Preset(
      id: 'galaxy-play',
      displayNameKey: 'preset.galaxyPlay',
      category: 'streaming',
      icon: '🌟',
    ),
    Preset(
      id: 'vieon',
      displayNameKey: 'preset.vieon',
      category: 'streaming',
      icon: '📱',
    ),
    Preset(
      id: 'zing-mp3',
      displayNameKey: 'preset.zingMp3',
      category: 'music',
      icon: '🎧',
    ),
    Preset(
      id: 'nhaccuatui',
      displayNameKey: 'preset.nhaccuatui',
      category: 'music',
      icon: '🎼',
    ),
    Preset(
      id: 'kg',
      displayNameKey: 'preset.kg',
      category: 'gaming',
      icon: '🕹️',
    ),
  ];
}
