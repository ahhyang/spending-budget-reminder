import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

Future<void> showGoalFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Goal? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: StashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => GoalFormSheet(existing: existing),
  );
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing});
  final Goal? existing;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _note;
  late GoalType _type;
  DateTime? _deadline;
  late bool showTarget;
  late bool showSaved;
  late bool showDeadline;
  late bool showMonthlySuggest;
  late bool showPercent;
  late bool showNote;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _target = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '',
    );
    _note = TextEditingController(text: g?.note ?? '');
    _type = g?.type ?? GoalType.travel;
    _deadline = g?.deadline != null ? DateTime.tryParse(g!.deadline!) : null;
    showTarget = g?.showTarget ?? true;
    showSaved = g?.showSaved ?? true;
    showDeadline = g?.showDeadline ?? true;
    showMonthlySuggest = g?.showMonthlySuggest ?? false;
    showPercent = g?.showPercent ?? true;
    showNote = g?.showNote ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? s.newGoal : s.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.name),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalType>(
              // ignore: deprecated_member_use
              value: _type,
              decoration: InputDecoration(labelText: s.type),
              items: GoalType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_label(s, t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.targetAmount),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.deadline),
              trailing: Text(
                _deadline == null ? '—' : shortDate(_deadline!),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: s.note),
            ),
            const SizedBox(height: 8),
            Text(s.displayFields, style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.targetAmount),
              value: showTarget,
              onChanged: (v) => setState(() => showTarget = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.savedAmount),
              value: showSaved,
              onChanged: (v) => setState(() => showSaved = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.deadline),
              value: showDeadline,
              onChanged: (v) => setState(() => showDeadline = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.monthlySuggest),
              value: showMonthlySuggest,
              onChanged: (v) => setState(() => showMonthlySuggest = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('%'),
              value: showPercent,
              onChanged: (v) => setState(() => showPercent = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.note),
              value: showNote,
              onChanged: (v) => setState(() => showNote = v),
            ),
            FilledButton(
              onPressed: () => _save(s),
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppStrings s, GoalType t) => switch (t) {
        GoalType.travel => s.travel,
        GoalType.emergency => s.emergency,
        GoalType.downPayment => s.downPayment,
        GoalType.custom => s.custom,
      };

  Future<void> _save(AppStrings s) async {
    final target = double.tryParse(_target.text);
    if (_name.text.trim().isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.required)),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = widget.existing;
    final goal = Goal(
      id: existing?.id ?? db.newId(),
      name: _name.text.trim(),
      type: _type,
      targetAmount: target,
      savedAmount: existing?.savedAmount ?? 0,
      deadline: _deadline != null ? isoDate(_deadline!) : null,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      showTarget: showTarget,
      showSaved: showSaved,
      showDeadline: showDeadline,
      showMonthlySuggest: showMonthlySuggest,
      showPercent: showPercent,
      showNote: showNote,
      status: existing?.status ?? GoalStatus.active,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await db.upsertGoal(goal);
    bumpData(ref);
    if (mounted) Navigator.of(context).pop();
  }
}
