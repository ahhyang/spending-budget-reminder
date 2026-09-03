import 'package:flutter_test/flutter_test.dart';
import 'package:stash/data/bank_parser.dart';
import 'package:stash/data/models.dart';

void main() {
  group('BankTxParser', () {
    test('parses Hong Leong debit', () {
      const raw =
          'Your HLB account **1234 was debited RM50.00 on 03/09/2026 at GRAB FOOD. Balance: RM1,234.56';
      final p = BankTxParser.parse(raw);
      expect(p, isNotNull);
      expect(p!.amount, 50);
      expect(p.type, TxType.expense);
      expect(p.source, BankSource.hongLeong);
      expect(p.merchant?.toLowerCase(), contains('grab'));
    });

    test('parses Touch n Go payment', () {
      const raw =
          "You have successfully paid RM12.50 to SHELL via Touch 'n Go eWallet.";
      final p = BankTxParser.parse(raw);
      expect(p, isNotNull);
      expect(p!.amount, 12.5);
      expect(p.type, TxType.expense);
      expect(p.source, BankSource.tng);
    });

    test('parses credit / refund', () {
      const raw = 'HLB: RM 200.00 credited to your account on 01-Sep-2026.';
      final p = BankTxParser.parse(raw);
      expect(p, isNotNull);
      expect(p!.amount, 200);
      expect(p.type, TxType.income);
    });

    test('returns null without amount', () {
      expect(BankTxParser.parse('Hello from bank'), isNull);
    });
  });
}
