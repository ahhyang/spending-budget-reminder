import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.templates),
        actions: [
          IconButton(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: templates.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => _create(context, ref),
                child: Text(s.createTemplate),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StashColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StashColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${t.type == TxType.expense ? s.expense : s.income} · ${formatMoney(t.amount)}',
                            style: const TextStyle(color: StashColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _apply(ref, t, s, context),
                      child: Text(s.applyTemplate),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref.read(databaseProvider).deleteTemplate(t.id);
                        bumpData(ref);
                      },
                      icon: const Icon(Icons.delete_outline, color: StashColors.coral),
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

  Future<void> _apply(
    WidgetRef ref,
    RecurringTemplate t,
    AppStrings s,
    BuildContext context,
  ) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insertTransaction(
      MoneyTx(
        id: db.newId(),
        type: t.type,
        amount: t.amount,
        date: isoDate(DateTime.now()),
        categoryId: t.categoryId,
        accountId: t.accountId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    bumpData(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.saved)),
      );
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var type = TxType.expense;
    final cats = await ref.read(databaseProvider).getCategories(kind: type);
    final accounts = await ref.read(databaseProvider).getAccounts();
    String? catId = cats.isNotEmpty ? cats.first.id : null;
    String? accId = accounts.isNotEmpty ? accounts.first.id : null;

    if (!context.mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StashColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(s.createTemplate,
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: s.name),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TxType>(
                    segments: [
                      ButtonSegment(
                          value: TxType.expense, label: Text(s.expense)),
                      ButtonSegment(
                          value: TxType.income, label: Text(s.income)),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) async {
                      type = v.first;
                      final next = await ref
                          .read(databaseProvider)
                          .getCategories(kind: type);
                      setLocal(() {
                        catId = next.isNotEmpty ? next.first.id : null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: s.amount),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.save),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final amount = double.tryParse(amountCtrl.text);
    if (ok != true || nameCtrl.text.trim().isEmpty || amount == null) return;

    final db = ref.read(databaseProvider);
    await db.upsertTemplate(
      RecurringTemplate(
        id: db.newId(),
        name: nameCtrl.text.trim(),
        type: type,
        amount: amount,
        categoryId: catId,
        accountId: accId,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    bumpData(ref);
  }
}
