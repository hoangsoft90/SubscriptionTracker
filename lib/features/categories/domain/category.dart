/// Subscription category (spec §6).
class Category {
  const Category({
    required this.id,
    required this.name,
    this.iconEmoji,
    this.colorHex,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String? iconEmoji;
  final String? colorHex;
  final bool isDefault;

  Category copyWith({String? name, String? iconEmoji, String? colorHex}) {
    return Category(
      id: id,
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_emoji': iconEmoji,
        'color_hex': colorHex,
        'is_default': isDefault ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id']! as String,
      name: map['name']! as String,
      iconEmoji: map['icon_emoji'] as String?,
      colorHex: map['color_hex'] as String?,
      isDefault: (map['is_default'] as int) == 1,
    );
  }
}
