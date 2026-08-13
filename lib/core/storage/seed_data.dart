/// Shared seed data (spec §6) — consumed by both the SQLite [Seeder] and the
/// web [LocalStorageSeeder] so the two platforms seed identical defaults.
library;

import '../../features/categories/domain/category.dart';

/// Default primary currency written on first launch.
const String seedDefaultPrimaryCurrency = 'USD';

/// The 11 default categories. Names are default display strings; custom
/// localization keys can be layered on in later milestones.
const List<Category> seedDefaultCategories = [
  Category(id: 'streaming', name: 'Streaming', iconEmoji: '📺', colorHex: '#E50914', isDefault: true),
  Category(id: 'music', name: 'Music', iconEmoji: '🎵', colorHex: '#1DB954', isDefault: true),
  Category(id: 'cloud-storage', name: 'Cloud Storage', iconEmoji: '☁️', colorHex: '#4285F4', isDefault: true),
  Category(id: 'productivity', name: 'Productivity', iconEmoji: '💼', colorHex: '#6C63FF', isDefault: true),
  Category(id: 'fitness', name: 'Fitness', iconEmoji: '💪', colorHex: '#FF6B35', isDefault: true),
  Category(id: 'news', name: 'News', iconEmoji: '📰', colorHex: '#3B82F6', isDefault: true),
  Category(id: 'gaming', name: 'Gaming', iconEmoji: '🎮', colorHex: '#8B5CF6', isDefault: true),
  Category(id: 'design', name: 'Design', iconEmoji: '🎨', colorHex: '#EC4899', isDefault: true),
  Category(id: 'developer-tools', name: 'Developer Tools', iconEmoji: '🧑‍💻', colorHex: '#10B981', isDefault: true),
  Category(id: 'shopping', name: 'Shopping', iconEmoji: '🛍️', colorHex: '#F59E0B', isDefault: true),
  Category(id: 'other', name: 'Other', iconEmoji: '📦', colorHex: '#64748B', isDefault: true),
];
