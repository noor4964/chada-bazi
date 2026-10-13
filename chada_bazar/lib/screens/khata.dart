import 'package:flutter/material.dart';

import '../ledger.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

const _months = bnMonthNames;

String bnDate(DateTime d) => '${bnInt(d.day)} ${_months[d.month - 1]} ${bnDigits('${d.year}')}';

const _punish = [
  'ফ্যামিলি গ্রুপে তোমার ক্লাস সেভেনের ছবি যাবে',
  'পাড়ার মাইকে তোমার নাম তিনবার ঘোষণা হবে',
  'ভাই তোমার বাসার নিচে গিটার নিয়ে গান গাইবে',
  'তোমার স্ট্যাটাসে সব বন্ধু "হাহা" রিঅ্যাক্ট দেবে',
];

/// The real, useful part: a private on-device ledger for informal money.
class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});
  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: ledger,
      builder: (_, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _summary(p),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: p.surface,
              foregroundColor: p.ink,
              selectedBackgroundColor: p.yellow,
              selectedForegroundColor: p.yellowInk,
              side: BorderSide(color: p.ink, width: 1.5),
            ),
            segments: [
              ButtonSegment(value: 0, label: Text('চাঁদা খাতা', style: body(15, w: FontWeight.w700)), icon: const Icon(Icons.volunteer_activism_rounded)),
              ButtonSegment(value: 1, label: Text('ধার খাতা', style: body(15, w: FontWeight.w700)), icon: const Icon(Icons.swap_horiz_rounded)),
            ],
            selected: {_seg},
            onSelectionChanged: (s) => setState(() => _seg = s.first),
          ),
        ),
        const SizedBox(height: 16),
        // Not const on purpose: a const child would not rebuild when the ledger changes.
        if (_seg == 0) _Contributions() else _Loans(),
      ]),
    );
  }

  Widget _summary(Palette p) {
    final now = DateTime.now();
    final overdue = ledger.overdueCount(now);
    Widget cell(String v, String l, {Color? color}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: body(21, w: FontWeight.w700, color: color, h: 1.2))),
            Text(l, style: body(12.5, color: p.muted), maxLines: 2),
          ]),
        );
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cell(tk(ledger.monthTotal(now)), '${_months[now.month - 1]} মাসে চাঁদা'),
          const SizedBox(width: 10),
          cell(tk(ledger.owedToMe), 'আমি পাব', color: p.green),
          const SizedBox(width: 10),
          cell(tk(ledger.iOwe), 'আমি দেব', color: p.red),
        ]),
        if (overdue > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: p.red, borderRadius: BorderRadius.circular(4)),
            child: Text('${bnInt(overdue)}টা ধারের সময় পার হয়ে গেছে', style: body(14, w: FontWeight.w700, color: p.redInk)),
          ),
        ],
        const SizedBox(height: 8),
        Text('এই খাতা শুধু তোমার ফোনে থাকে। কোথাও পাঠানো হয় না।', style: body(12.5, color: p.muted)),
      ]),
    );
  }
}

// ======================================================= চাঁদা খাতা =======

class _Contributions extends StatelessWidget {
  const _Contributions();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final list = ledger.contributions;
    final year = DateTime.now().year;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: BhaiButton('+ চাঁদা লিখো', kind: BtnKind.red, onTap: () => _openContribForm(context)),
      ),
      const SizedBox(height: 16),
      if (list.isEmpty)
        BhaiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('এখনো কিছু লেখা হয়নি', lede: 'পূজার চাঁদা, ক্লাবের টাকা, চা-পানি, পার্কিং। যা দিয়েছ লিখে রাখো, বছর শেষে দেখো টাকা কোথায় গেল।'),
            BhaiButton('প্রথম চাঁদাটা লিখো', onTap: () => _openContribForm(context)),
          ]),
        )
      else ...[
        _breakdown(context, p, year),
        const SizedBox(height: 16),
        BhaiCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('সব চাঁদা', style: body(20, w: FontWeight.w700)),
            Text('বাঁ দিকে টেনে মুছে ফেলা যায়।', style: body(13, color: p.muted)),
            const SizedBox(height: 8),
            ..._rows(context, p, list),
          ]),
        ),
      ],
    ]);
  }

  List<Widget> _rows(BuildContext context, Palette p, List<Contribution> list) {
    final out = <Widget>[];
    String? month;
    for (final c in list) {
      final m = '${_months[c.date.month - 1]} ${bnDigits('${c.date.year}')}';
      if (m != month) {
        month = m;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(children: [
            Expanded(child: Text(m, style: body(14, w: FontWeight.w700, color: p.muted))),
            Text(tk(ledger.monthTotal(c.date)), style: body(14, w: FontWeight.w700, color: p.muted)),
          ]),
        ));
      }
      out.add(Dismissible(
        key: ValueKey(c.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: p.red,
          child: Icon(Icons.delete_rounded, color: p.redInk),
        ),
        onDismissed: (_) {
          ledger.removeContribution(c.id);
          final m = messengerKey.currentState!;
          m.hideCurrentSnackBar();
          m.showSnackBar(SnackBar(
            content: Text('মুছে ফেলেছি। ভাই খুশি।', style: body(15, w: FontWeight.w600)),
            action: SnackBarAction(label: 'ফিরিয়ে আনো', onPressed: () => ledger.restoreContribution(c)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: p.surface, border: Border(bottom: BorderSide(color: p.line))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.to.isEmpty ? c.category : '${c.category} · ${c.to}', style: body(15.5, w: FontWeight.w600, h: 1.3)),
                Text('${bnDate(c.date)}${c.note.isEmpty ? '' : ' · ${c.note}'}', style: body(12.5, color: p.muted, h: 1.3)),
              ]),
            ),
            const SizedBox(width: 10),
            Text(tk(c.amount), style: body(16, w: FontWeight.w700)),
          ]),
        ),
      ));
    }
    return out;
  }

  Widget _breakdown(BuildContext context, Palette p, int year) {
    final by = ledger.byCategory(year);
    final total = ledger.yearTotal(year);
    final sorted = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${bnDigits('$year')} সালে মোট চাঁদা', style: body(15, color: p.muted)),
        Text(tk(total), style: body(30, w: FontWeight.w700, color: p.red, h: 1.2)),
        const SizedBox(height: 8),
        if (total == 0)
          Text('এই বছরে এখনো কিছু লেখা নেই।', style: body(14, color: p.muted))
        else
          for (final e in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 120, child: Text(e.key, style: body(13.5), overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(value: e.value / total, minHeight: 10, color: p.green, backgroundColor: p.line),
                  ),
                ),
                SizedBox(width: 74, child: Text(tk(e.value), textAlign: TextAlign.right, style: body(13.5, w: FontWeight.w700))),
              ]),
            ),
        if (total > 0)
          ShareBar(
            text: 'এ বছর ${tk(total)} চাঁদা দিয়েছি 😭 সব হিসাব রাখছি চাঁদা বাজার খাতায়। তুমি কত দিয়েছ?',
            card: ShareCardData(
              kicker: 'বার্ষিক চাঁদা রিপোর্ট',
              title: '${bnDigits('$year')} সালে আমি চাঁদা দিয়েছি ${tk(total)}',
              rows: [for (final e in sorted.take(5)) (e.key, tk(e.value))],
              big: 'সবচেয়ে বেশি গেছে: ${sorted.first.key}',
              stamp: 'হিসাব শেষ',
            ),
          ),
      ]),
    );
  }
}

void _openContribForm(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.of(context).paper,
    showDragHandle: true,
    builder: (_) => const _ContribForm(),
  );
}

class _ContribForm extends StatefulWidget {
  const _ContribForm();
  @override
  State<_ContribForm> createState() => _ContribFormState();
}

class _ContribFormState extends State<_ContribForm> {
  final _amount = TextEditingController();
  final _to = TextEditingController();
  final _note = TextEditingController();
  String _cat = categories.first;
  DateTime _date = dayOnly(DateTime.now());
  String? _err;

  void _save() {
    final n = firstNumber(_amount.text);
    if (n == null || n <= 0) {
      setState(() => _err = 'কত টাকা দিয়েছ, সংখ্যায় লেখো।');
      return;
    }
    final first = ledger.contributions.isEmpty;
    ledger.addContribution(amount: n, category: _cat, to: _to.text.trim(), date: _date, note: _note.text.trim());
    if (first) app.badge('khata1');
    Navigator.pop(context);
    toast('লেখা হয়েছে: ${tk(n)}, $_cat');
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime.now());
    if (d != null) setState(() => _date = dayOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final today = dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('চাঁদা লিখো', style: body(20, w: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'কত টাকা', prefixText: '৳ '),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text(c, style: body(14, color: _cat == c ? p.yellowInk : p.ink)),
                  selected: _cat == c,
                  selectedColor: p.yellow,
                  backgroundColor: p.surface,
                  side: BorderSide(color: p.ink, width: 1.5),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _cat = c),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _to, maxLength: 30, decoration: const InputDecoration(labelText: 'কাকে / কোথায় (ইচ্ছা হলে)', counterText: '')),
            const SizedBox(height: 10),
            TextField(controller: _note, maxLength: 60, decoration: const InputDecoration(labelText: 'নোট (ইচ্ছা হলে)', counterText: '')),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _dateChip(p, 'আজ', _date == today, () => setState(() => _date = today)),
              _dateChip(p, 'গতকাল', _date == yesterday, () => setState(() => _date = yesterday)),
              _dateChip(p, _date == today || _date == yesterday ? 'তারিখ বাছো' : bnDate(_date), !(_date == today || _date == yesterday), _pickDate),
            ]),
            if (_err != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
            const SizedBox(height: 14),
            BhaiButton('সেভ করো', kind: BtnKind.red, onTap: _save),
          ]),
        ),
      ),
    );
  }

  Widget _dateChip(Palette p, String label, bool on, VoidCallback onTap) => ActionChip(
        label: Text(label, style: body(14, color: on ? p.yellowInk : p.ink)),
        backgroundColor: on ? p.yellow : p.surface,
        side: BorderSide(color: p.ink, width: 1.5),
        onPressed: onTap,
      );
}

// ========================================================= ধার খাতা =======

class _Loans extends StatelessWidget {
  const _Loans();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final now = DateTime.now();
    final open = ledger.loans.where((l) => !l.settled).toList()
      ..sort((a, b) {
        final ao = a.isOverdue(now), bo = b.isOverdue(now);
        if (ao != bo) return ao ? -1 : 1;
        return (a.due ?? DateTime(9999)).compareTo(b.due ?? DateTime(9999));
      });
    final done = ledger.loans.where((l) => l.settled).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerLeft, child: BhaiButton('+ ধার লিখো', kind: BtnKind.red, onTap: () => _openLoanForm(context))),
      const SizedBox(height: 16),
      if (ledger.loans.isEmpty)
        BhaiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('কেউ কিছু ধার নেয়নি?', lede: 'কাকে কত দিয়েছ বা কার কাছে কত নিয়েছ লিখে রাখো। সময় পার হলে ভাই নিজেই নোটিশ বানিয়ে দেবে।'),
            BhaiButton('প্রথম ধারটা লিখো', onTap: () => _openLoanForm(context)),
          ]),
        )
      else ...[
        for (final l in open) Padding(padding: const EdgeInsets.only(bottom: 12), child: _LoanTile(l)),
        if (done.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text('শোধ হয়ে গেছে', style: body(14, w: FontWeight.w700, color: p.muted)),
          ),
          for (final l in done) Padding(padding: const EdgeInsets.only(bottom: 10), child: _LoanTile(l)),
        ],
      ],
    ]);
  }
}

class _LoanTile extends StatelessWidget {
  final Loan l;
  const _LoanTile(this.l);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final over = l.isOverdue(DateTime.now());
    final color = l.settled ? p.muted : (l.lent ? p.green : p.red);
    return InkWell(
      onTap: () => _openLoanDetail(context, l.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: over ? p.red : p.ink, width: over ? 3 : 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.person, style: body(17, w: FontWeight.w700, h: 1.25)),
              const SizedBox(height: 2),
              Text(
                l.settled
                    ? (l.lent ? 'পুরো ফেরত পেয়েছি' : 'পুরো শোধ করেছি')
                    : '${l.lent ? 'আমি দিয়েছি' : 'আমি নিয়েছি'} ${tk(l.amount)}${l.repaid > 0 ? ' · ফেরত ${tk(l.repaid)}' : ''}',
                style: body(13, color: p.muted, h: 1.3),
              ),
              if (!l.settled && l.due != null)
                Text(
                  over ? 'সময় পার: ${bnDate(l.due!)}' : 'শেষ তারিখ: ${bnDate(l.due!)}',
                  style: body(13, w: over ? FontWeight.w700 : FontWeight.w500, color: over ? p.red : p.muted, h: 1.3),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l.settled ? '✓' : tk(l.remaining), style: body(19, w: FontWeight.w700, color: color)),
            if (!l.settled) Text(l.lent ? 'পাব' : 'দেব', style: body(12.5, color: color)),
          ]),
        ]),
      ),
    );
  }
}

void _openLoanForm(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.of(context).paper,
    showDragHandle: true,
    builder: (_) => const _LoanForm(),
  );
}

class _LoanForm extends StatefulWidget {
  const _LoanForm();
  @override
  State<_LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<_LoanForm> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _lent = true;
  DateTime? _due;
  String? _err;

  void _save() {
    final (name, nameErr) = cleanName(_person.text);
    final n = firstNumber(_amount.text);
    if (name == null) return setState(() => _err = nameErr);
    if (n == null || n <= 0) return setState(() => _err = 'কত টাকা, সংখ্যায় লেখো।');
    ledger.addLoan(person: name, amount: n, lent: _lent, due: _due, note: _note.text.trim());
    Navigator.pop(context);
    toast(_lent ? '$name-কে ${tk(n)} ধার দেওয়া লেখা হলো' : '$name-এর কাছ থেকে ${tk(n)} নেওয়া লেখা হলো');
  }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d != null) setState(() => _due = dayOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final today = dayOnly(DateTime.now());
    ActionChip chip(String label, bool on, VoidCallback f) => ActionChip(
          label: Text(label, style: body(14, color: on ? p.yellowInk : p.ink)),
          backgroundColor: on ? p.yellow : p.surface,
          side: BorderSide(color: p.ink, width: 1.5),
          onPressed: f,
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ধার লিখো', style: body(20, w: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(selectedBackgroundColor: p.yellow, selectedForegroundColor: p.yellowInk, side: BorderSide(color: p.ink, width: 1.5)),
                segments: [
                  ButtonSegment(value: true, label: Text('আমি দিয়েছি', style: body(15, w: FontWeight.w700))),
                  ButtonSegment(value: false, label: Text('আমি নিয়েছি', style: body(15, w: FontWeight.w700))),
                ],
                selected: {_lent},
                onSelectionChanged: (s) => setState(() => _lent = s.first),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _person, maxLength: 20, decoration: InputDecoration(labelText: _lent ? 'কাকে দিয়েছ (ডাকনাম)' : 'কার কাছ থেকে নিয়েছ (ডাকনাম)', counterText: '')),
            const SizedBox(height: 10),
            TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'কত টাকা', prefixText: '৳ ')),
            const SizedBox(height: 10),
            TextField(controller: _note, maxLength: 60, decoration: const InputDecoration(labelText: 'নোট (ইচ্ছা হলে)', counterText: '')),
            const SizedBox(height: 10),
            Text('ফেরতের শেষ তারিখ', style: body(13, color: p.muted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              chip('নির্দিষ্ট নেই', _due == null, () => setState(() => _due = null)),
              chip('৭ দিন', _due == today.add(const Duration(days: 7)), () => setState(() => _due = today.add(const Duration(days: 7)))),
              chip('১৫ দিন', _due == today.add(const Duration(days: 15)), () => setState(() => _due = today.add(const Duration(days: 15)))),
              chip('১ মাস', _due == today.add(const Duration(days: 30)), () => setState(() => _due = today.add(const Duration(days: 30)))),
              chip(_due == null ? 'তারিখ বাছো' : bnDate(_due!), false, _pick),
            ]),
            if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
            const SizedBox(height: 14),
            BhaiButton('সেভ করো', kind: BtnKind.red, onTap: _save),
          ]),
        ),
      ),
    );
  }
}

void _openLoanDetail(BuildContext context, String id) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.of(context).paper,
    showDragHandle: true,
    builder: (_) => _LoanDetail(id),
  );
}

class _LoanDetail extends StatefulWidget {
  final String id;
  const _LoanDetail(this.id);
  @override
  State<_LoanDetail> createState() => _LoanDetailState();
}

class _LoanDetailState extends State<_LoanDetail> {
  final _amount = TextEditingController();
  bool _confirmDelete = false;
  String? _err;

  void _repay(Loan l) {
    final n = firstNumber(_amount.text);
    if (n == null || n <= 0) return setState(() => _err = 'কত টাকা, সংখ্যায় লেখো।');
    ledger.addRepayment(l.id, n);
    _amount.clear();
    setState(() => _err = null);
    toast(l.remaining == 0 ? 'পুরো শোধ। এবার শান্তি।' : 'লেখা হয়েছে। বাকি ${tk(l.remaining)}');
  }

  void _notice(Loan l) {
    final fine = ((l.remaining * 0.1) / 10).round() * 10;
    final punish = pick(_punish);
    final text =
        '🚨 @${l.person} তোমার নামে চাঁদা নোটিশ জারি হয়েছে! ধার ${tk(l.remaining)} ফেরত দেওয়ার সময় পার। দেরির জরিমানা ${tk(fine)}। না দিলে $punish। 😈';
    Navigator.pop(context);
    showShareCard(
      context,
      ShareCardData(
        kicker: 'ধার ফেরত নোটিশ',
        title: '${l.person}, তোমার নামে নোটিশ!',
        rows: [('বাকি ধার', tk(l.remaining)), ('দেরির জরিমানা', tk(fine)), if (l.due != null) ('শেষ তারিখ ছিল', bnDate(l.due!))],
        big: 'না দিলে: $punish',
        stamp: 'জরুরি',
      ),
      text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: ledger,
      builder: (ctx, _) {
        final idx = ledger.loans.indexWhere((x) => x.id == widget.id);
        if (idx < 0) return const SizedBox(height: 80);
        final l = ledger.loans[idx];
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.person, style: body(22, w: FontWeight.w700)),
                Text('${l.lent ? 'আমি দিয়েছি' : 'আমি নিয়েছি'} ${tk(l.amount)} · ${bnDate(l.created)}${l.note.isEmpty ? '' : '\n${l.note}'}', style: body(14, color: p.muted)),
                const SizedBox(height: 10),
                Text(l.settled ? 'শোধ হয়ে গেছে ✓' : 'বাকি ${tk(l.remaining)}', style: body(24, w: FontWeight.w700, color: l.settled ? p.green : (l.lent ? p.green : p.red))),
                if (l.due != null && !l.settled)
                  Text(l.isOverdue(DateTime.now()) ? 'সময় পার: ${bnDate(l.due!)}' : 'শেষ তারিখ: ${bnDate(l.due!)}', style: body(14, w: FontWeight.w600, color: l.isOverdue(DateTime.now()) ? p.red : p.muted)),
                if (l.repayments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('ফেরতের হিসাব', style: body(14, w: FontWeight.w700, color: p.muted)),
                  for (final r in l.repayments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [Expanded(child: Text(bnDate(r.date), style: body(14))), Text(tk(r.amount), style: body(14, w: FontWeight.w700))]),
                    ),
                ],
                if (!l.settled) ...[
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.lent ? 'কত ফেরত পেলে' : 'কত শোধ করলে', prefixText: '৳ '),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BhaiButton('লিখো', onTap: () => _repay(l)),
                  ]),
                  if (_err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    BhaiButton('পুরোটা শোধ', kind: BtnKind.green, onTap: () {
                      ledger.addRepayment(l.id, l.remaining);
                      toast('পুরো শোধ। এবার শান্তি।');
                    }),
                    if (l.lent) BhaiButton('নোটিশ পাঠাও', kind: BtnKind.red, onTap: () => _notice(l)),
                  ]),
                ],
                const SizedBox(height: 16),
                BhaiButton(_confirmDelete ? 'নিশ্চিত? আবার চাপো' : 'এই ধার মুছে ফেলো', kind: BtnKind.ghost, onTap: () {
                  if (_confirmDelete) {
                    ledger.removeLoan(l.id);
                    Navigator.pop(ctx);
                  } else {
                    setState(() => _confirmDelete = true);
                  }
                }),
              ]),
            ),
          ),
        );
      },
    );
  }
}
