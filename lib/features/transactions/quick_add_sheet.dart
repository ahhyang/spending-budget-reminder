import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

Future<void> showQuickAddSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: StashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const QuickAddSheet(),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  TxType _type = TxType.expense;
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _accountId;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cats = ref.watch(categoriesProvider(_type));
    final accounts = ref.watch(accountsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: StashColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.quickAdd, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<TxType>(
              segments: [
                ButtonSegment(value: TxType.expense, label: Text(s.expense)),
                ButtonSegment(value: TxType.income, label: Text(s.income)),
              ],
              selected: {_type},
              onSelectionChanged: (v) {
                setState(() {
                  _type = v.first;
                  _categoryId = null;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: s.amount,
                prefixText: 'RM ',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.date),
              trailing: Text(shortDate(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 4),
            Text(s.category, style: const TextStyle(color: StashColors.textMuted)),
            const SizedBox(height: 8),
            cats.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (list) {
                _categoryId ??= list.isNotEmpty ? list.first.id : null;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map((c) {
                    final selected = c.id == _categoryId;
                    return ChoiceChip(
                      label: Text(c.label(s.isZh)),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                      selectedColor: StashColors.mintDim,
                      labelStyle: TextStyle(
                        color: selected ? StashColors.text : StashColors.textMuted,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            accounts.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('$e'),
              data: (list) {
                _accountId ??= list.isNotEmpty ? list.first.id : null;
                if (list.isEmpty) {
                  return Text(
                    s.emptyAccounts,
                    style: const TextStyle(color: StashColors.textMuted),
                  );
                }
                return DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _accountId,
                  decoration: InputDecoration(labelText: s.account),
                  items: list
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : () => _save(s),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AppStrings s) async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0 || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.required)),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().toUtc().toIso8601String();
    final db = ref.read(databaseProvider);
    await db.insertTransaction(
      MoneyTx(
        id: db.newId(),
        type: _type,
        amount: amount,
        date: isoDate(_date),
        categoryId: _categoryId,
        accountId: _accountId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    bumpData(ref);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.saved)),
      );
    }
  }
}
