import '../core/utils/format.dart';
import 'models.dart';

enum BankSource { hongLeong, tng, generic, unknown }

class ParsedBankTx {
  ParsedBankTx({
    required this.amount,
    required this.type,
    required this.source,
    this.merchant,
    this.date,
    this.raw,
    this.suggestedCategoryId,
  });

  final double amount;
  final TxType type;
  final BankSource source;
  final String? merchant;
  final DateTime? date;
  final String? raw;
  final String? suggestedCategoryId;
}

/// Parses Hong Leong / Touch 'n Go / generic MYR payment notification text.
class BankTxParser {
  static final _amountRe = RegExp(
    r'(?:RM|MYR)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _debitHints = RegExp(
    r'debit|debited|spent|paid|payment|purchase|withdraw|txn|transaction|扣除|付款|消费',
    caseSensitive: false,
  );

  static final _creditHints = RegExp(
    r'credit|credited|received|deposit|refund|top[\s-]?up|转入|入账|收款',
    caseSensitive: false,
  );

  static BankSource detectSource(String text, {String? packageOrTitle}) {
    final blob = '${packageOrTitle ?? ''} $text'.toLowerCase();
    if (blob.contains('hong leong') ||
        blob.contains('hongleong') ||
        blob.contains('hlb') ||
        blob.contains('com.hongleong')) {
      return BankSource.hongLeong;
    }
    if (blob.contains("touch 'n go") ||
        blob.contains('touch n go') ||
        blob.contains('tng') ||
        blob.contains('touchngo') ||
        blob.contains('my.com.tngdigital')) {
      return BankSource.tng;
    }
    if (_amountRe.hasMatch(text)) return BankSource.generic;
    return BankSource.unknown;
  }

  static ParsedBankTx? parse(String raw, {String? packageOrTitle}) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final source = detectSource(text, packageOrTitle: packageOrTitle);
    if (source == BankSource.unknown && !_amountRe.hasMatch(text)) {
      return null;
    }

    final amountMatch = _amountRe.firstMatch(text);
    if (amountMatch == null) return null;
    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    var type = TxType.expense;
    if (_creditHints.hasMatch(text) && !_debitHints.hasMatch(text)) {
      type = TxType.income;
    } else if (_debitHints.hasMatch(text)) {
      type = TxType.expense;
    } else if (source == BankSource.tng) {
      type = TxType.expense;
    }

    final merchant = _extractMerchant(text, source);
    final date = _extractDate(text) ?? DateTime.now();
    final categoryId = suggestCategoryId(merchant, type);

    return ParsedBankTx(
      amount: amount,
      type: type,
      source: source,
      merchant: merchant,
      date: date,
      raw: text,
      suggestedCategoryId: categoryId,
    );
  }

  static String? _extractMerchant(String text, BankSource source) {
    final patterns = <RegExp>[
      RegExp(r'(?:at|to|with|via)\s+([A-Za-z0-9 &.\-]{2,40})', caseSensitive: false),
      RegExp(r'(?:paid to|payment to)\s+([A-Za-z0-9 &.\-]{2,40})', caseSensitive: false),
      RegExp(r'(?:商家|商户)[:：\s]*([^\s，。]{2,30})'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m != null) {
        var name = m.group(1)!.trim();
        name = name.replaceAll(RegExp(r'\s+on\s+\d.*$', caseSensitive: false), '');
        name = name.replaceAll(RegExp(r'[.。].*$'), '');
        if (name.length >= 2) return name;
      }
    }
    return switch (source) {
      BankSource.hongLeong => 'Hong Leong',
      BankSource.tng => "Touch 'n Go",
      _ => null,
    };
  }

  static DateTime? _extractDate(String text) {
    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    final dmy = RegExp(
      r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})',
    ).firstMatch(text);
    if (dmy != null) {
      var y = int.parse(dmy.group(3)!);
      if (y < 100) y += 2000;
      return DateTime(y, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    final mon = RegExp(
      r'(\d{1,2})[\-\s](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\-\s](\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (mon != null) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final m = months[mon.group(2)!.substring(0, 3).toLowerCase()]!;
      var y = int.parse(mon.group(3)!);
      if (y < 100) y += 2000;
      return DateTime(y, m, int.parse(mon.group(1)!));
    }
    return null;
  }

  static String? suggestCategoryId(String? merchant, TxType type) {
    if (type == TxType.income) return 'c_other_inc';
    final m = (merchant ?? '').toLowerCase();
    if (m.contains('grab') ||
        m.contains('food') ||
        m.contains('mcdonald') ||
        m.contains('starbucks') ||
        m.contains('restaurant') ||
        m.contains('cafe')) {
      return 'c_food';
    }
    if (m.contains('grab') ||
        m.contains('tng') ||
        m.contains('petronas') ||
        m.contains('shell') ||
        m.contains('touch')) {
      // grab food already caught; transport fuels
      if (m.contains('grabcar') ||
          m.contains('petronas') ||
          m.contains('shell') ||
          m.contains('touch')) {
        return 'c_transport';
      }
    }
    if (m.contains('lazada') ||
        m.contains('shopee') ||
        m.contains('shop') ||
        m.contains('aeon')) {
      return 'c_shopping';
    }
    if (m.contains('tnb') ||
        m.contains('unifi') ||
        m.contains('maxis') ||
        m.contains('digi') ||
        m.contains('bill') ||
        m.contains('maintenance')) {
      return 'c_bills';
    }
    return 'c_other_exp';
  }

  static String sourceLabel(BankSource s, {required bool isZh}) => switch (s) {
        BankSource.hongLeong => isZh ? '丰隆银行' : 'Hong Leong',
        BankSource.tng => isZh ? "Touch 'n Go" : "Touch 'n Go",
        BankSource.generic => isZh ? '通用' : 'Generic',
        BankSource.unknown => isZh ? '未知' : 'Unknown',
      };

  static String formatPreview(ParsedBankTx p) {
    final when = p.date != null ? isoDate(p.date!) : '—';
    return '${formatMoney(p.amount)} · ${p.merchant ?? '—'} · $when';
  }
}
