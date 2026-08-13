import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../categories/application/category_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../subscriptions/application/subscription_list_controller.dart';
import '../backup_models.dart';
import '../export_service.dart';
import '../import_service.dart';

/// Backup & Transfer (spec §2.6): export via share sheet; import with a
/// preview step and an explicit Merge / Replace All choice.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _export() async {
    // Capture UI handles before any await (lint: no context across async gaps).
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _exporting = true);
    try {
      final exportService = BackupExportService(
        subscriptions: await ref.read(subscriptionRepositoryProvider.future),
        categories: await ref.read(categoryRepositoryProvider.future),
        settings: await ref.read(settingsRepositoryProvider.future),
      );
      final file = await exportService.buildFile();
      await exportService.share(file);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.backupExported)));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.backupErrorInvalidFile)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;

    final String raw;
    try {
      raw = await File(path).readAsString();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupErrorInvalidFile)),
      );
      return;
    }
    await _showImportFlow(raw);
  }

  Future<void> _showImportFlow(String raw) async {
    // Capture UI handles before any await (lint: no context across async gaps).
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _importing = true);
    final importService = BackupImportService(
      subscriptions: await ref.read(subscriptionRepositoryProvider.future),
      categories: await ref.read(categoryRepositoryProvider.future),
      settings: await ref.read(settingsRepositoryProvider.future),
    );

    final BackupFile file;
    try {
      file = BackupFile.decode(raw);
    } on BackupValidationException catch (e) {
      setState(() => _importing = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isFutureVersion
                ? l10n.backupErrorFutureSchema
                : l10n.backupErrorInvalidFile,
          ),
        ),
      );
      return;
    }
    setState(() => _importing = false);

    if (!mounted) return;
    final strategy = await _chooseStrategy(file);
    if (strategy == null || !mounted) return;

    // A structurally-valid backup can still fail to apply: a row missing a
    // required field (e.g. hand-edited / truncated file) throws inside
    // fromMap()/enum parsing. That must never crash the app — surface a
    // clear error and keep the current data untouched.
    try {
      await importService.apply(file, strategy: strategy);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.backupErrorInvalidFile)),
        );
      }
      return;
    }
    // Imported data changed the schedule — reconcile so stale reminders for
    // replaced/removed rows are cancelled and new ones are scheduled (fix:
    // previously old notifications stayed pending until the next app open).
    // Best-effort: a scheduling failure (e.g. platform plugin unavailable)
    // must never block the import success flow — the next app open / data
    // change reconciles anyway.
    try {
      await ref.read(notificationCoordinatorProvider).onSubscriptionsChanged();
    } catch (_) {
      // Swallow: housekeeping only.
    }
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImported)));
      // Refresh consumers so the UI reflects the imported data.
      ref.invalidate(subscriptionListControllerProvider);
      ref.invalidate(categoryControllerProvider);
      ref.invalidate(settingsControllerProvider);
      ref.invalidate(dashboardControllerProvider);
    }
  }

  /// Opens the Merge / Replace All preview dialog. Called with the State
  /// context; only invoked after a [mounted] guard (see caller).
  Future<ImportStrategy?> _chooseStrategy(BackupFile file) {
    return showDialog<ImportStrategy>(
      context: context,
      builder: (context) => _ImportPreviewDialog(file: file),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupExport,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.backupExportBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.backupExport),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupImport,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.backupImportBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _importing ? null : _pickAndImport,
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(l10n.backupImport),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportPreviewDialog extends StatelessWidget {
  const _ImportPreviewDialog({required this.file});

  final BackupFile file;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = file.settings['primaryCurrency'];
    return AlertDialog(
      title: Text(l10n.backupImport),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupPreview(file.subscriptionCount, file.categoryCount)),
          if (currency != null) ...[
            const SizedBox(height: 8),
            Text(l10n.backupSettingsSummary(currency)),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.backupMergeBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ImportStrategy.merge),
          child: Text(l10n.backupMerge),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _confirmReplace(context),
          child: Text(l10n.backupReplace),
        ),
      ],
    );
  }

  Future<void> _confirmReplace(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupReplaceConfirmTitle),
        content: Text(l10n.backupReplaceConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.backupReplace),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context, ImportStrategy.replaceAll);
    }
  }
}
