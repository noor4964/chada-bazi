import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

// ======================================================= নিজের রসিদ ========

const _items = [
  'ভাই-অ্যাডেড ট্যাক্স (VAT)', 'ভালোবাসার টাকা', 'চা-সিঙ্গারা ফান্ড', 'মাইক ভাড়া (যেটা কখনো বাজেনি)',
  'ব্যানারে তোমার নাম না থাকার ফি', 'ভাইয়ের বাইকের তেল', 'ভবিষ্যৎ চাঁদার অগ্রিম', 'রসিদ ছাপানোর খরচ',
  'পাড়ার উন্নয়ন (কোন উন্নয়ন, জিজ্ঞেস করা নিষেধ)', 'দেরিতে দরজা খোলার জরিমানা', 'ভাইকে "আপনি" বলার দণ্ড',
  'চেহারায় বিরক্তি দেখানোর চার্জ', 'ভাইয়ের মোবাইল রিচার্জ', 'সার্ভিস চার্জ (সার্ভিস নেই)',
];
const _places = ['মোড়ের চায়ের দোকান', 'বাড়ির গেট', 'বিয়েবাড়ির গেট', 'অফিসের লিফট', 'বাসস্ট্যান্ড', 'নতুন ফ্ল্যাটে ওঠার দিন'];
const _occ = {
  'ঈদ': 2.2, 'পূজা': 2.0, 'পহেলা বৈশাখ': 1.5, 'ক্লাবের পিকনিক': 1.3, 'ভাইয়ের জন্মদিন': 1.8, 'কোনো কারণ নেই': 1.0,
};
const _verdicts = [
  'ভাই খুশি। আপাতত বেঁচে গেলে।', 'এটা শুধু প্রথম কিস্তি। দ্বিতীয়টা সারপ্রাইজ।',
  'ভাই বলেছে পরের সপ্তাহে আবার আসবে, ভালোবেসে।', 'রসিদ হারালে আবার পুরোটা দিতে হবে।',
  'ভাই তোমার নাম মনে রেখেছে। এটা ভালো খবর না।',
];

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _name = TextEditingController(text: 'মামুন');
  String _place = _places.first, _occasion = 'ঈদ';
  String? _err;
  late _Receipt _r;

  @override
  void initState() {
    super.initState();
    _r = _make('মামুন (উদাহরণ)');
  }

  _Receipt _make(String who) {
    final mul = _occ[_occasion]!;
    final rows = shuffled(_items).take(4).map((i) => (i, (rnd(40, 400) * mul / 10).round() * 10)).toList();
    return _Receipt(who, _place, _occasion, rnd(1000, 9999), rows, pick(_verdicts));
  }

  void _go() {
    final (n, err) = cleanName(_name.text);
    setState(() => _err = err);
    if (n == null) return;
    setState(() => _r = _make(n));
    app.pay(_r.total);
    app.badge('rosid');
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final r = _r;
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('তোমার নামে চাঁদার রসিদ',
            tag: 'ছবি বানিয়ে শেয়ার করো',
            lede: 'নাম আর জায়গা দাও। ভাই হিসাব করে দেবে কত দিতে হবে আর কেন। নিচের রসিদটা একটা উদাহরণ।'),
        TextField(controller: _name, maxLength: 20, decoration: const InputDecoration(labelText: 'তোমার ডাকনাম', counterText: '')),
        const SizedBox(height: 10),
        _Drop('কোথায় ধরা খেয়েছ', _place, _places, (v) => setState(() => _place = v)),
        const SizedBox(height: 10),
        _Drop('উপলক্ষ', _occasion, _occ.keys.toList(), (v) => setState(() => _occasion = v)),
        if (_err != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
        const SizedBox(height: 12),
        BhaiButton('রসিদ কাটো', kind: BtnKind.red, onTap: _go),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.muted)),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Text('চাঁদা রসিদ', style: display(30, color: p.red))),
              Center(child: Text('রসিদ নং ${bnDigits('${r.no}')} · ${r.occasion} · ${r.place}', style: body(12.5, color: p.muted), textAlign: TextAlign.center)),
              Divider(color: p.muted),
              _line('দাতা', r.who, bold: true),
              for (final i in r.rows) _line(i.$1, tk(i.$2)),
              Divider(color: p.ink, thickness: 2),
              _line('সর্বমোট', tk(r.total), bold: true, size: 19),
              const SizedBox(height: 8),
              Text(r.verdict, style: body(15, w: FontWeight.w700, color: p.green)),
            ]),
            Positioned(
              right: -4,
              top: -4,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: p.red, width: 2.5), borderRadius: BorderRadius.circular(6)),
                  child: Text('পরিশোধিত', style: body(14, w: FontWeight.w700, color: p.red)),
                ),
              ),
            ),
          ]),
        ),
        ShareBar(
          text: 'আজ ${r.place}-এ ধরা খেলাম 😭 ${r.occasion} উপলক্ষে ${r.who}-এর চাঁদা ${tk(r.total)}। ${r.verdict} তোমার রসিদ কত?',
          card: ShareCardData(
            kicker: 'রসিদ নং ${bnDigits('${r.no}')}',
            title: '${r.who}-এর চাঁদা রসিদ',
            rows: [for (final i in r.rows) (i.$1, tk(i.$2)), ('সর্বমোট', tk(r.total))],
            big: r.verdict,
            stamp: 'পরিশোধিত',
          ),
        ),
      ]),
    );
  }

  Widget _line(String a, String b, {bool bold = false, double size = 15}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(a, style: body(size, w: bold ? FontWeight.w700 : FontWeight.w500))),
          const SizedBox(width: 10),
          Text(b, style: body(size, w: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );
}

class _Receipt {
  final String who, place, occasion, verdict;
  final int no;
  final List<(String, int)> rows;
  _Receipt(this.who, this.place, this.occasion, this.no, this.rows, this.verdict);
  int get total => rows.fold(0, (s, r) => s + r.$2);
}

class _Drop extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _Drop(this.label, this.value, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      );
}

// ================================================== বন্ধুকে ফাঁসাও ========

const _crimes = <(String, int)>[
  ('ট্রিট দেবে বলে ৩ বছর ধরে দেয়নি', 1500), ('গ্রুপে seen করে রিপ্লাই দেয় না', 300),
  ('"৫ মিনিটে আসছি" বলে ২ ঘণ্টা লেট', 700), ('ধার নিয়ে বেমালুম ভুলে গেছে', 2000),
  ('বিয়ের দাওয়াত দেয়নি', 2500), ('সব ছবিতে নিজে সুন্দর, বাকিদের চোখ বন্ধ', 900),
  ('নতুন চাকরির খবর লুকিয়েছে', 3000), ('জন্মদিনের কেক একা খেয়েছে', 800), ('ভয়েস মেসেজ পাঠায় ৪ মিনিটের', 400),
];
const _punish = [
  'ফ্যামিলি গ্রুপে তোমার ক্লাস সেভেনের ছবি যাবে', 'পাড়ার মাইকে তোমার নাম তিনবার ঘোষণা হবে',
  'এক মাস তোমার চায়ে চিনি বন্ধ', 'তোমার ক্রাশকে সব বলে দেওয়া হবে', 'ভাই তোমার বাসার নিচে গিটার নিয়ে গান গাইবে',
  'তোমার স্ট্যাটাসে সব বন্ধু "হাহা" রিঅ্যাক্ট দেবে', 'আম্মুকে জানানো হবে তুমি রাত ৩টা পর্যন্ত অনলাইন থাকো',
];
const _deadlines = ['আজ রাত ১২টার মধ্যে', 'পরের আড্ডার আগে', 'বেতন ঢোকার ১ ঘণ্টার মধ্যে', 'এই নোটিশ পড়ার সাথে সাথে'];

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});
  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _name = TextEditingController(text: 'সাকিব');
  int _crime = 0;
  String? _err;
  late _Notice _n;

  @override
  void initState() {
    super.initState();
    _n = _make('সাকিব (উদাহরণ)');
  }

  _Notice _make(String who) {
    final c = _crimes[_crime];
    final fine = (c.$2 * (0.8 + rng.nextDouble() * 0.8) / 10).round() * 10;
    return _Notice(who, c.$1, fine, pick(_punish), pick(_deadlines), 'চাঁ/${bnDigits('${rnd(100, 999)}')}/২০২৬');
  }

  void _go() {
    final (n, err) = cleanName(_name.text);
    setState(() => _err = err);
    if (n == null) return;
    setState(() => _n = _make(n));
    app.badge('notice');
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = _n;
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('বন্ধুকে চাঁদার নোটিশ পাঠাও',
            tag: 'ট্যাগ করো',
            lede: 'যে বন্ধু ট্রিট দেয়নি, তার নামে অফিশিয়াল নোটিশ। শুধু ডাকনাম দাও, আসল নেতা বা পরিচিত মানুষের নাম চলবে না।'),
        TextField(controller: _name, maxLength: 20, decoration: const InputDecoration(labelText: 'বন্ধুর ডাকনাম', counterText: '')),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'অপরাধ'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _crime,
              isDense: true,
              isExpanded: true,
              items: [for (var i = 0; i < _crimes.length; i++) DropdownMenuItem(value: i, child: Text(_crimes[i].$1, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _crime = v ?? 0),
            ),
          ),
        ),
        if (_err != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
        const SizedBox(height: 12),
        BhaiButton('নোটিশ জারি করো', kind: BtnKind.red, onTap: _go),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.red, width: 3)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text('চূড়ান্ত চাঁদা নোটিশ', style: body(21, w: FontWeight.w700, color: p.red))),
            Center(child: Text('স্মারক ${n.no} · পাড়া চাঁদা আদালত', style: body(12.5, color: p.muted), textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            _row(p, 'অভিযুক্ত', n.who),
            _row(p, 'অপরাধ', n.crime),
            _row(p, 'জরিমানা', tk(n.fine), bold: true),
            _row(p, 'শেষ সময়', n.deadline),
            _row(p, 'না দিলে', n.punish),
            _row(p, 'আপিল', 'গ্রহণযোগ্য নয়। আপিল ফি ${tk(n.fine * 2)}।'),
          ]),
        ),
        ShareBar(
          text: '🚨 @${n.who} তোমার নামে চাঁদা নোটিশ জারি হয়েছে! অপরাধ: ${n.crime}। জরিমানা ${tk(n.fine)}, ${n.deadline}। না দিলে ${n.punish}। 😈',
          card: ShareCardData(
            kicker: 'স্মারক ${n.no}',
            title: '${n.who}, তোমার নামে নোটিশ!',
            rows: [('অপরাধ: ${n.crime}', null), ('জরিমানা', tk(n.fine)), ('শেষ সময়: ${n.deadline}', null)],
            big: 'না দিলে: ${n.punish}',
            stamp: 'জরুরি',
          ),
        ),
      ]),
    );
  }

  Widget _row(Palette p, String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 78, child: Text(k, style: body(14, w: FontWeight.w700, color: p.muted))),
          Expanded(child: Text(v, style: body(15.5, w: bold ? FontWeight.w700 : FontWeight.w500))),
        ]),
      );
}

class _Notice {
  final String who, crime, punish, deadline, no;
  final int fine;
  _Notice(this.who, this.crime, this.fine, this.punish, this.deadline, this.no);
}

// ===================================================== ভিকটিম কুইজ ========

const _types = {
  'd': ('দানবীর হাতেম তাই', 'পাড়ার সবচেয়ে প্রিয় ATM তুমি। ভাইয়েরা তোমার ছবি দিয়ে ক্যালেন্ডার বানিয়েছে।'),
  'e': ('অদৃশ্য মানব', 'তোমাকে শেষ দেখা গেছে চায়ের দোকানের পেছনে। ভাইয়েরা এখনো খুঁজছে।'),
  'h': ('দরকষাকষি চ্যাম্পিয়ন', 'একবার ভাইয়ের কাছ থেকেই উল্টো ৳২০ চাঁদা নিয়ে এসেছিলে।'),
  'x': ('বাহানা বিশেষজ্ঞ', 'তোমার দাদি এই বছর ৭ বার অসুস্থ হয়েছেন। ভাইয়েরা ফুল পাঠাতে চায়।'),
};
const _qs = <(String, List<(String, String)>)>[
  ('পাড়ার ভাই দরজায় নক করলে তুমি কী করো?', [('মানিব্যাগ বের করি', 'd'), ('খাটের নিচে লুকাই', 'e'), ('বলি, ভাই ২০ টাকায় হয় না?', 'h'), ('বলি, আম্মু বাসায় নেই, পরে আসেন', 'x')]),
  ('ঈদের আগে ভাইয়ের কল এলে?', [('প্রথম রিং-এ ধরি', 'd'), ('ফোন এয়ারপ্লেন মোডে', 'e'), ('ধরেই ডিসকাউন্ট কোড চাই', 'h'), ('বলি নেটওয়ার্ক খারাপ, হ্যালো… হ্যালো…', 'x')]),
  ('রসিদ চাইলে ভাই রেগে গেল। তুমি?', [('সরি বলে ডাবল দিই', 'd'), ('পেছনের দরজা দিয়ে হাওয়া', 'e'), ('বলি, রসিদ ছাড়া ১০% ছাড় দেন', 'h'), ('বলি, বাসায় মেহমান, কাল আসেন', 'x')]),
  ('তোমার মানিব্যাগে সাধারণত কী থাকে?', [('ভাইয়ের জন্য আলাদা খাম', 'd'), ('কিছুই না, ওটাই কৌশল', 'e'), ('খুচরা পয়সা, দরদামের জন্য', 'h'), ('পুরোনো রসিদ, প্রমাণ হিসেবে', 'x')]),
  ('ভাই বললো, "এইবারই শেষ, আর চাইব না।" তুমি?', [('বিশ্বাস করি', 'd'), ('হাসি থামাতে পারি না', 'e'), ('লিখিত চুক্তি চাই', 'h'), ('বলি, আমিও কাল বিদেশ চলে যাচ্ছি', 'x')]),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0;
  Map<String, int> _score = {};
  late List<List<(String, String)>> _order;

  @override
  void initState() {
    super.initState();
    _order = [for (final q in _qs) shuffled(q.$2)];
    if (app.quiz.isNotEmpty) {
      _score = Map.of(app.quiz);
      _i = _qs.length;
    }
  }

  void _answer(String t) {
    setState(() {
      _score[t] = (_score[t] ?? 0) + 1;
      _i++;
    });
    if (_i >= _qs.length) {
      app.update(() => app.quiz = Map.of(_score));
      app.badge('quiz');
    }
  }

  void _again() => setState(() {
        _i = 0;
        _score = {};
        _order = [for (final q in _qs) shuffled(q.$2)];
      });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('তুমি কোন টাইপের চাঁদা-ভিকটিম?', tag: '৫টা প্রশ্ন', lede: 'সৎ উত্তর দাও। ভাই সব দেখছে।'),
        if (_i < _qs.length) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _i / _qs.length, minHeight: 8, color: p.red, backgroundColor: p.line),
          ),
          const SizedBox(height: 12),
          Text('${bnDigits('${_i + 1}')}. ${_qs[_i].$1}', style: body(19, w: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final o in _order[_i])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _answer(o.$2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.ink, width: 1.5), borderRadius: BorderRadius.circular(4)),
                  child: Text(o.$1, style: body(16)),
                ),
              ),
            ),
          const ShareBar(text: 'তুমি কোন টাইপের চাঁদা-ভিকটিম? আমি বের করে ফেলেছি 😂 তুমিও খেলো:'),
        ] else
          _result(p),
      ]),
    );
  }

  Widget _result(Palette p) {
    final total = _score.values.fold(0, (a, b) => a + b);
    int pct(String k) => total == 0 ? 0 : ((_score[k] ?? 0) / total * 100).round();
    final keys = _types.keys.toList()..sort((a, b) => (_score[b] ?? 0).compareTo(_score[a] ?? 0));
    final top = keys.first;
    final t = _types[top]!;
    return Column(children: [
      Text('তুমি হলে…', style: body(16)),
      Text(t.$1, style: display(40, color: p.red), textAlign: TextAlign.center),
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t.$2, style: body(16), textAlign: TextAlign.center)),
      for (final k in _types.keys)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 118, child: Text(_types[k]!.$1, style: body(13.5), overflow: TextOverflow.ellipsis)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: pct(k) / 100, minHeight: 10, color: p.green, backgroundColor: p.line),
              ),
            ),
            SizedBox(width: 44, child: Text('${bnDigits('${pct(k)}')}%', textAlign: TextAlign.right, style: body(13.5))),
          ]),
        ),
      const SizedBox(height: 12),
      BhaiButton('আবার খেলো', kind: BtnKind.ghost, onTap: _again),
      Align(
        alignment: Alignment.centerLeft,
        child: ShareBar(
          text: 'আমি ${bnDigits('${pct(top)}')}% "${t.$1}" 😭 ${t.$2} তুমি কোন টাইপের চাঁদা-ভিকটিম? বন্ধুদের ট্যাগ করো 👇',
          card: ShareCardData(
            kicker: 'ভিকটিম কুইজ',
            title: 'আমি ${bnDigits('${pct(top)}')}% ${t.$1}',
            rows: [for (final k in _types.keys) (_types[k]!.$1, '${bnDigits('${pct(k)}')}%')],
            big: t.$2,
          ),
        ),
      ),
    ]);
  }
}
