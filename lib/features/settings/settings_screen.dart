import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../accounts/accounts_screen.dart';
import '../budget/budget_screen.dart';
import '../import/import_inbox_screen.dart';
import '../reports/reports_screen.dart';
import 'categories_screen.dart';
import 'templates_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(s.language),
            subtitle: Text(locale == 'zh' ? s.chinese : s.english),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(s.english)),
                ButtonSegment(value: 'zh', label: Text(s.chinese)),
              ],
              selected: {locale},
              onSelectionChanged: (v) {
                ref.read(localeProvider.notifier).setLocale(v.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(s.manageAccounts),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: Text(s.setBudgets),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(s.templates),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplatesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(s.viewReports),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(s.categories),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(s.bankImport),
            subtitle: Text(s.autoListenHint),
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportInboxScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(s.privacy),
            subtitle: Text(s.privacyBody),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            subtitle: Text(s.aboutBody),
            isThreeLine: true,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Stash v1.1.0 · MYR · Phase 2 import',
              style: TextStyle(color: StashColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
