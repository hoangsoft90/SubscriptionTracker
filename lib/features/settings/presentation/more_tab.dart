import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/more/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.backupTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/more/backup'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              l10n.aboutPrivacyLine,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
