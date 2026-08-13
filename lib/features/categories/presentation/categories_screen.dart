import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n.dart';
import '../application/category_controller.dart';
import '../domain/category.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  /// Tapped category id — toggles a visual highlight (no navigation).
  String? _selectedId;

  Future<void> _addCategory() async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => const _CategoryDialog(),
    );
    if (result != null) {
      await ref.read(categoryControllerProvider.notifier).add(result);
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
    if (result != null) {
      await ref
          .read(categoryControllerProvider.notifier)
          .updateCategory(result);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.categoryDeleteDefaultBlocked)),
      );
      return;
    }
    await ref.read(categoryControllerProvider.notifier).delete(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        tooltip: context.l10n.categoriesAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: categories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) => ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final category = list[index];
              final theme = Theme.of(context);
              final selected = _selectedId == category.id;
              return ListTile(
                selected: selected,
                selectedTileColor: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
                leading: CircleAvatar(
                  backgroundColor: _parseColor(category.colorHex),
                  child: Text(category.iconEmoji ?? '🏷️'),
                ),
                title: Text(
                  category.name,
                  style: selected
                      ? TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
                subtitle: category.isDefault
                    ? Text(context.l10n.defaultLabel)
                    : null,
                trailing: category.isDefault
                    ? (selected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: context.l10n.tooltipEdit,
                            onPressed: () => _editCategory(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.l10n.delete,
                            onPressed: () => _deleteCategory(category),
                          ),
                        ],
                      ),
                onTap: () => setState(() {
                  _selectedId = selected ? null : category.id;
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return Colors.grey;
    return Color(0xFF000000 | value);
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _icon;
  late String _color;

  static const _icons = [
    '📺',
    '🎵',
    '☁️',
    '💼',
    '💪',
    '📰',
    '🎮',
    '🎨',
    '🛍️',
    '📦',
    '🏷️',
  ];
  static const _colors = [
    '#E50914',
    '#1DB954',
    '#4285F4',
    '#6C63FF',
    '#FF6B35',
    '#10B981',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.iconEmoji ?? '🏷️';
    _color = widget.category?.colorHex ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.category == null ? l10n.categoriesAdd : l10n.editCategory,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.categoryName),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final icon in _icons)
                  ChoiceChip(
                    label: Text(icon),
                    selected: _icon == icon,
                    onSelected: (_) => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final color in _colors)
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: _parse(color),
                      child: _color == color
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final base = widget.category;
            Navigator.pop(
              context,
              Category(
                id: base?.id ?? const Uuid().v4(),
                name: _nameController.text.trim(),
                iconEmoji: _icon,
                colorHex: _color,
                isDefault: base?.isDefault ?? false,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  static Color _parse(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(0xFF000000 | int.parse(cleaned, radix: 16));
  }
}
