import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cats = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.categories),
        actions: [
          IconButton(
            onPressed: () => _add(context, ref, s),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: cats.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = list[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: StashColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StashColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label(s.isZh),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.kind == TxType.expense ? s.expense : s.income,
                            style: const TextStyle(
                              color: StashColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!c.isSystem)
                      IconButton(
                        onPressed: () async {
                          await ref.read(databaseProvider).deleteCategory(c.id);
                          bumpData(ref);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: StashColors.coral,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final enCtrl = TextEditingController();
    final zhCtrl = TextEditingController();
    var kind = TxType.expense;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: StashColors.surface,
              title: Text(s.categories),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: enCtrl,
                    decoration: InputDecoration(labelText: s.english),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: zhCtrl,
                    decoration: InputDecoration(labelText: s.chinese),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TxType>(
                    segments: [
                      ButtonSegment(
                        value: TxType.expense,
                        label: Text(s.expense),
                      ),
                      ButtonSegment(
                        value: TxType.income,
                        label: Text(s.income),
                      ),
                    ],
                    selected: {kind},
                    onSelectionChanged: (v) => setLocal(() => kind = v.first),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(s.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || enCtrl.text.trim().isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.upsertCategory(
      Category(
        id: db.newId(),
        nameEn: enCtrl.text.trim(),
        nameZh: zhCtrl.text.trim().isEmpty
            ? enCtrl.text.trim()
            : zhCtrl.text.trim(),
        kind: kind,
      ),
    );
    bumpData(ref);
  }
}
