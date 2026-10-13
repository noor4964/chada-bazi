import 'package:flutter/material.dart';

import '../ledger.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// One deduction from the collected money.
class Cut {
  final String name;
  final int percent;
  final int amount;
  const Cut(this.name, this.percent, this.amount);
}

/// Fixed side deductions, always taken after the leader's share.
const _sideCuts = <(String, int)>[
  ('চা-সিঙ্গারা ফান্ড', 2),
  ('মাইক ভাড়া (যেটা বাজেনি)', 3),
  ('রসিদ ছাপানো', 1),
  ('ভাইয়ের ভাতিজার "সার্ভিস"', 2),
];

/// Splits [total] into the leader's cut, the side cuts and what is left for
/// the real work. Cuts are rounded; the remainder is whatever is left, so the
/// parts always add up to [total].
({List<Cut> cuts, int remaining}) splitCuts(int total, int leaderPercent) {
  final cuts = <Cut>[
    Cut('নেতার ভাগ', leaderPercent, (total * leaderPercent / 100).round()),
    for (final s in _sideCuts) Cut(s.$1, s.$2, (total * s.$2 / 100).round()),
  ];
  final taken = cuts.fold<int>(0, (s, c) => s + c.amount);
  return (cuts: cuts, remaining: total - taken);
}

String _verdict(int remainingPercent) {
  if (remainingPercent >= 85) return 'প্রায় সবটাই কাজে যাচ্ছে। এত ভালো হিসাব সন্দেহজনক।';
  if (remainingPercent >= 70) return 'বেশিরভাগ কাজে গেল। বাকিটা "পরিচালনা খরচ"।';
  if (remainingPercent >= 50) return 'আসল কাজে অর্ধেকের একটু বেশি। বাকিটা ভাইয়েরা সামলে নিয়েছে।';
  return 'আসল কাজে অর্ধেকের কম। রাস্তা হবে, তবে শুধু ছবিতে।';
}

class BhagScreen extends StatefulWidget {
  /// True when viewed from the collector's side (wording only).
  final bool collector;
  const BhagScreen({super.key, this.collector = false});
  @override
  State<BhagScreen> createState() => _BhagScreenState();
}

class _BhagScreenState extends State<BhagScreen> {
  final _amount = TextEditingController(text: '10000');
  int _leader = 10;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final total = firstNumber(_amount.text) ?? 0;
    final r = splitCuts(total, _leader);
    final cutsPercent = _leader + _sideCuts.fold<int>(0, (s, c) => s + c.$2);
    final remPercent = 100 - cutsPercent;
    final leaderAmt = r.cuts.first.amount;
    final colors = [p.red, p.muted, p.yellow, p.line, p.ink];
    final year = DateTime.now().year;

    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardTitle('নেতার ভাগ ক্যালকুলেটর',
            lede: widget.collector
                ? 'ভাই হলেও ওপরে একজন নেতা থাকেন। যা তুললে তার থেকে নেতার ভাগ কাটো, তারপর দেখো তোমার হাতে কত থাকে। নেতার নাম নেই, দল নেই।'
                : 'যত টাকা উঠল, তার থেকে নেতার ভাগ কেটে দেখো আসল কাজে কত যায়। পাড়ার একজন নেতা, নাম নেই, দল নেই।'),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'মোট কত টাকা উঠেছে', prefixText: '৳ '),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in [5000, 10000, 50000, 100000])
            ActionChip(
              label: Text(tk(v), style: body(14)),
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5),
              onPressed: () => setState(() => _amount.text = '$v'),
            ),
          if (ledger.yearTotal(year) > 0)
            ActionChip(
              label: Text('আমার ${bnDigits('$year')} সালের খাতা: ${tk(ledger.yearTotal(year))}', style: body(14, w: FontWeight.w700, color: p.yellowInk)),
              backgroundColor: p.yellow,
              side: BorderSide(color: p.ink, width: 1.5),
              onPressed: () => setState(() => _amount.text = '${ledger.yearTotal(year)}'),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text('নেতার ভাগ: ', style: body(16, w: FontWeight.w600)),
          Text('${bnInt(_leader)}%', style: body(20, w: FontWeight.w700, color: p.red)),
        ]),
        Slider(
          value: _leader.toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          activeColor: p.red,
          inactiveColor: p.line,
          label: '${bnInt(_leader)}%',
          onChanged: (v) => setState(() => _leader = v.round()),
        ),
        const SizedBox(height: 4),
        // One bar showing where the money goes.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 22,
            child: total <= 0
                ? Container(color: p.line)
                : Row(children: [
                    for (var i = 0; i < r.cuts.length; i++)
                      if (r.cuts[i].amount > 0) Expanded(flex: r.cuts[i].amount, child: Container(color: colors[i % colors.length])),
                    if (r.remaining > 0) Expanded(flex: r.remaining, child: Container(color: p.green)),
                  ]),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < r.cuts.length; i++) _row(p, colors[i % colors.length], r.cuts[i].name, '${bnInt(r.cuts[i].percent)}%', tk(r.cuts[i].amount), bold: i == 0),
        Divider(color: p.ink, thickness: 2),
        _row(p, p.green, 'আসল কাজে যাচ্ছে', '${bnInt(remPercent)}%', tk(r.remaining), bold: true, size: 18),
        OutBox(child: Text(_verdict(remPercent), style: body(15, w: FontWeight.w600))),
        ShareBar(
          text: '${tk(total)} চাঁদা উঠল। নেতার ${bnInt(_leader)}% ভাগ ${tk(leaderAmt)}। আসল কাজে গেল মাত্র ${tk(r.remaining)} 🤡 তোমার পাড়ায় কত যায়?',
          card: ShareCardData(
            kicker: 'নেতার ভাগ',
            title: '${tk(total)} উঠল, কাজে গেল ${tk(r.remaining)}',
            rows: [for (final c in r.cuts) (c.name, tk(c.amount)), ('আসল কাজে', tk(r.remaining))],
            big: _verdict(remPercent),
            stamp: 'হিসাব শেষ',
          ),
        ),
      ]),
    );
  }

  Widget _row(Palette p, Color dot, String name, String pct, String amt, {bool bold = false, double size = 15}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(3), border: Border.all(color: p.ink))),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: body(size, w: bold ? FontWeight.w700 : FontWeight.w500))),
          Text(pct, style: body(size - 1, color: p.muted)),
          const SizedBox(width: 12),
          SizedBox(width: 84, child: Text(amt, textAlign: TextAlign.right, style: body(size, w: FontWeight.w700))),
        ]),
      );
}
