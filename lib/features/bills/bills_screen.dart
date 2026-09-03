import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';
import 'bill_detail_screen.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bills = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.bills),
        actions: [
          IconButton(
            onPressed: () => _showBillForm(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: bills.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.emptyBills,
                    style: const TextStyle(color: StashColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _showBillForm(context, ref),
                    child: Text(s.newBill),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = list[i];
              final pending = b.status == BillStatus.pending;
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillDetailScreen(billId: b.id),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StashColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: pending ? StashColors.amber.withValues(alpha: 0.5) : StashColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pending
                                ? StashColors.amber.withValues(alpha: 0.15)
                                : StashColors.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pending ? s.pending : s.paid,
                            style: TextStyle(
                              color: pending ? StashColors.amber : StashColors.mint,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatMoney(b.amount)} · ${b.nextDue} · ${_cycle(s, b.cycle)}',
                      style: const TextStyle(color: StashColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (pending)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => _markPaid(ref, b),
                            child: Text(s.markPaid),
                          ),
                        IconButton(
                          tooltip: s.addToCalendar,
                          onPressed: () => _addCalendar(context, b, s),
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: StashColors.mint,
                          ),
                        ),
                        IconButton(
                          tooltip: s.delete,
                          onPressed: () async {
                            await ref.read(databaseProvider).deleteBill(b.id);
                            bumpData(ref);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: StashColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }

  String _cycle(AppStrings s, BillCycle c) => switch (c) {
        BillCycle.monthly => s.cycleMonthly,
        BillCycle.quarterly => s.cycleQuarterly,
        BillCycle.yearly => s.cycleYearly,
        BillCycle.once => s.cycleOnce,
      };

  Future<void> _markPaid(WidgetRef ref, Bill b) async {
    final db = ref.read(databaseProvider);
    await db.markBillMonthPaid(bill: b, yearMonth: yearMonth(DateTime.now()));
    final now = DateTime.now().toUtc().toIso8601String();
    var next = DateTime.parse(b.nextDue);
    switch (b.cycle) {
      case BillCycle.monthly:
        next = DateTime(next.year, next.month + 1, next.day);
      case BillCycle.quarterly:
        next = DateTime(next.year, next.month + 3, next.day);
      case BillCycle.yearly:
        next = DateTime(next.year + 1, next.month, next.day);
      case BillCycle.once:
        await db.upsertBill(
          b.copyWith(status: BillStatus.paid, updatedAt: now),
        );
        bumpData(ref);
        return;
    }
    await db.upsertBill(
      b.copyWith(
        status: BillStatus.pending,
        nextDue: isoDate(next),
        updatedAt: now,
      ),
    );
    bumpData(ref);
  }

  Future<void> _addCalendar(
    BuildContext context,
    Bill b,
    AppStrings s,
  ) async {
    final due = DateTime.parse(b.nextDue);
    final event = Event(
      title: b.name,
      description: 'Stash bill · ${formatMoney(b.amount)}',
      startDate: due,
      endDate: due.add(const Duration(hours: 1)),
      allDay: true,
    );
    await Add2Calendar.addEvent2Cal(event);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.calendarAdded)),
      );
    }
  }
}

Future<void> _showBillForm(BuildContext context, WidgetRef ref) async {
  final s = ref.read(stringsProvider);
  final nameCtrl = TextEditingController(text: 'Maintenance fee');
  final amountCtrl = TextEditingController();
  var due = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  var cycle = BillCycle.monthly;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: StashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(s.newBill, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: s.name),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: s.amount),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BillCycle>(
                    // ignore: deprecated_member_use
                    value: cycle,
                    decoration: InputDecoration(labelText: s.type),
                    items: BillCycle.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(switch (c) {
                              BillCycle.monthly => s.cycleMonthly,
                              BillCycle.quarterly => s.cycleQuarterly,
                              BillCycle.yearly => s.cycleYearly,
                              BillCycle.once => s.cycleOnce,
                            }),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => cycle = v ?? cycle),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.nextDue),
                    trailing: Text(shortDate(due)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: due,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setLocal(() => due = picked);
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.save),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  final amount = double.tryParse(amountCtrl.text);
  if (ok != true || nameCtrl.text.trim().isEmpty || amount == null) return;

  final db = ref.read(databaseProvider);
  final now = DateTime.now().toUtc().toIso8601String();
  await db.upsertBill(
    Bill(
      id: db.newId(),
      name: nameCtrl.text.trim(),
      amount: amount,
      nextDue: isoDate(due),
      cycle: cycle,
      status: BillStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
  );
  bumpData(ref);
}
