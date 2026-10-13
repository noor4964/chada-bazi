import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

const _excuses = [
  'স্যার চা খেতে গেছেন', 'স্যার মিটিংয়ে, মিটিংটা কোথায় কেউ জানে না', 'সার্ভার ডাউন, ২০১৯ থেকে',
  'ফাইলে সই আছে, সিল নেই', 'সিল আছে, যিনি সিল দেন তিনি ছুটিতে', 'নামের বানানে একটা "ি" বেশি',
  'ফাইল পাশের টেবিলে, পাশের টেবিল অন্য বিল্ডিংয়ে',
];
const _winners = [
  'ভাইয়ের শালার কোম্পানি (আবারো)', 'গতকাল খোলা "মেসার্স সব পারি এন্টারপ্রাইজ"',
  'একমাত্র আবেদনকারী, যিনি বিজয়ীও', 'যে কোম্পানির অফিস একটা মোবাইল নম্বর',
];
const _works = ['৩০০ মিটার রাস্তা', 'একটা যাত্রী ছাউনি', 'ড্রেনের ঢাকনা ১২টা', 'পার্কের একটা বেঞ্চ'];
const _vip = [
  'রাস্তা বন্ধ সকাল ৮টা থেকে ভিআইপি আসা পর্যন্ত। ভিআইপি এখনো ঘুমাচ্ছেন।',
  'ভিআইপি চলে গেছেন ২ ঘণ্টা আগে। রাস্তা খোলার অর্ডার এখনো আসেনি।',
  'আজ রাস্তা খোলা! কারণ রাস্তাটাই খুঁড়ে রাখা হয়েছে।',
  'বিকল্প রাস্তা: হেঁটে যান। হাঁটার রাস্তাও বন্ধ।',
];

class GovtScreen extends StatefulWidget {
  const GovtScreen({super.key});
  @override
  State<GovtScreen> createState() => _GovtScreenState();
}

class _GovtScreenState extends State<GovtScreen> {
  final _file = TextEditingController(text: 'জন্ম নিবন্ধন সংশোধন');
  _FileResult? _f;
  bool _bulbOn = false;
  String _bulb = '';
  String? _tender, _road;
  String _shareTxt = 'সরকারি অফিসে না গিয়েও ঝামেলা উপভোগ করো 🙃';
  ShareCardData? _card;

  void _track() {
    final name = _file.text.trim().isEmpty ? 'ফাইল' : _file.text.trim();
    final pr = (rng.nextDouble() * 3);
    final r = _FileResult(name, rnd(3, 47), pick(_excuses), rnd(2, 9), pr, rnd(200, 2000));
    setState(() {
      _f = r;
      _shareTxt = 'আমার "$name" ফাইল এখন টেবিল নং ${bnInt(r.table)}-এ। কারণ: ${r.excuse}। আনুমানিক সময় ${bnInt(r.years)} বছর 🙃';
      _card = ShareCardData(
        kicker: 'ফাইল ট্র্যাকার',
        title: '"$name" এখন কোথায়?',
        rows: [('অবস্থান', 'টেবিল ${bnInt(r.table)}'), ('কারণ: ${r.excuse}', null), ('অগ্রগতি', '${bnDigits(r.pct.toStringAsFixed(1))}%'), ('আনুমানিক সময়', '${bnInt(r.years)} বছর')],
        stamp: 'বিবেচনাধীন',
      );
    });
    app.badge('file');
  }

  void _bulbCheck() {
    final on = rng.nextDouble() < .22;
    if (!on) app.update(() => app.outages++);
    setState(() {
      _bulbOn = on;
      _bulb = on
          ? 'আছে! জলদি মোবাইল চার্জ দাও, ৩ মিনিট সময়।'
          : '${pick(['নেই। ট্রান্সফরমার বিশ্রামে আছে।', 'নেই। লোড ম্যানেজমেন্ট চলছে, ম্যানেজ করছে তোমাকে।', 'নেই। বিল কিন্তু ঠিকই আসবে।'])} আজ পর্যন্ত লোডশেডিং: ${bnInt(app.outages)} বার';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final h = body(22, w: FontWeight.w700, color: p.green, h: 1.25);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ফাইল ট্র্যাকার', style: h),
          const SizedBox(height: 4),
          Text('তোমার ফাইল এখন কোথায় ঘুমাচ্ছে দেখো।', style: body(15, color: p.muted)),
          const SizedBox(height: 12),
          TextField(controller: _file, maxLength: 40, decoration: const InputDecoration(labelText: 'ফাইলের নাম', counterText: '')),
          const SizedBox(height: 10),
          BhaiButton('খোঁজো', kind: BtnKind.green, onTap: _track),
          if (_f != null)
            OutBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ফাইল: ${_f!.name}', style: body(16, w: FontWeight.w700)),
                Text('অবস্থান: টেবিল নং ${bnInt(_f!.table)}', style: body(15)),
                Text('কারণ: ${_f!.excuse}', style: body(15)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: _f!.pct / 100, minHeight: 14, color: p.green, backgroundColor: p.line)),
                const SizedBox(height: 6),
                Text('অগ্রগতি ${bnDigits(_f!.pct.toStringAsFixed(1))}% · আনুমানিক সময় ${bnInt(_f!.years)} বছর', style: body(15)),
                Text('দ্রুত করতে চাইলে "স্পিড মানি" ${tk(_f!.speed)}', style: body(15)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('বিদ্যুৎ আছে?', style: h),
          const SizedBox(height: 4),
          Text('চেক করার জন্যও বিদ্যুৎ লাগে।', style: body(15, color: p.muted)),
          const SizedBox(height: 12),
          Row(children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _bulbOn ? 1 : .3,
              child: const Text('💡', style: TextStyle(fontSize: 54)),
            ),
            const SizedBox(width: 16),
            BhaiButton('চেক করো', kind: BtnKind.green, onTap: _bulbCheck),
          ]),
          OutBox(child: Text(_bulb.isEmpty ? 'আজ লোডশেডিং: ${bnInt(app.outages)} বার' : _bulb, style: body(15))),
        ]),
      ),
      const SizedBox(height: 16),
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('টেন্ডার লটারি', style: h),
          const SizedBox(height: 4),
          Text('স্বচ্ছ প্রক্রিয়ায় বিজয়ী নির্বাচন। ফলাফল আগে থেকেই জানা।', style: body(15, color: p.muted)),
          const SizedBox(height: 12),
          BhaiButton('লটারি টানো', kind: BtnKind.green, onTap: () {
            final r = rnd(2, 4);
            setState(() => _tender = 'কাজ: ${pick(_works)}\nবাজেট: ${bnInt(rnd(5, 90))} কোটি টাকা\nবিজয়ী: ${pick(_winners)}\nসময়সীমা: ${bnInt(r)} মাস, সম্ভাব্য বাস্তব সময়: ${bnInt(r * 7)} মাস');
          }),
          if (_tender != null) OutBox(child: Text(_tender!, style: body(15))),
        ]),
      ),
      const SizedBox(height: 16),
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ভিআইপি রোড আপডেট', style: h),
          const SizedBox(height: 4),
          Text('আজকের রাস্তা কখন খুলবে জেনে নাও।', style: body(15, color: p.muted)),
          const SizedBox(height: 12),
          BhaiButton('আপডেট দেখো', kind: BtnKind.green, onTap: () => setState(() => _road = '${pick(_vip)} আনুমানিক অপেক্ষা: ${bnInt(rnd(1, 5))} ঘণ্টা ${bnInt(rnd(1, 59))} মিনিট।')),
          if (_road != null) OutBox(child: Text(_road!, style: body(15))),
          ShareBar(text: _shareTxt, card: _card),
        ]),
      ),
    ]);
  }
}

class _FileResult {
  final String name, excuse;
  final int table, years, speed;
  final double pct;
  _FileResult(this.name, this.table, this.excuse, this.years, this.pct, this.speed);
}

// ============================================================= board ====

const _areas = <(String, int)>[
  ('গলি নং ৪২', 18450), ('পুরোনো পানির ট্যাংকের মোড়', 15200), ('তিনতলা মার্কেটের পেছন', 11980),
  ('নতুন রাস্তার শেষ মাথা', 8300), ('ক্লাবঘরের পাশের বাড়ি', 5120), ('বটতলা', 2740),
];

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final rows = <(String, int, bool)>[
          for (final a in _areas) (a.$1, a.$2, false),
          ('তুমি', app.paid, true),
        ]..sort((a, b) => b.$2.compareTo(a.$2));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('সাপ্তাহিক ভিকটিম লিডারবোর্ড', lede: 'বিভিন্ন পাড়ার সাথে তোমার তুলনা। তোমার সারি তোমার ডিভাইসের হিসাব থেকে।'),
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: rows[i].$3 ? p.yellow : null,
                    border: Border(bottom: BorderSide(color: p.line)),
                  ),
                  child: Row(children: [
                    SizedBox(width: 30, child: Text(bnInt(i + 1), style: body(15, w: FontWeight.w700, color: rows[i].$3 ? p.yellowInk : p.muted))),
                    Expanded(child: Text(rows[i].$1, style: body(15, w: rows[i].$3 ? FontWeight.w700 : FontWeight.w500, color: rows[i].$3 ? p.yellowInk : p.ink))),
                    Text(tk(rows[i].$2), style: body(15, w: FontWeight.w700, color: rows[i].$3 ? p.yellowInk : p.ink)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('তোমার ব্যাজ', lede: 'যত ঠকবে, তত ব্যাজ।'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final e in badgeDefs.entries)
                  Opacity(
                    opacity: app.badges.contains(e.key) ? 1 : .4,
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: app.badges.contains(e.key) ? p.yellow : p.paper,
                        border: Border.all(color: app.badges.contains(e.key) ? p.ink : p.line, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(children: [
                        Text(e.value.$1, style: const TextStyle(fontSize: 26)),
                        Text(e.value.$2, style: body(13.5, color: app.badges.contains(e.key) ? p.yellowInk : p.ink), textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
        ]);
      },
    );
  }
}
