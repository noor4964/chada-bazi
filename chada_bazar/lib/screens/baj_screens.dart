import 'dart:math';

import 'package:flutter/material.dart';

import '../baj_state.dart';
import '../season.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

final _rng = Random();

Color _heatColor(Palette p, int heat) => heat < 40 ? p.green : (heat < 70 ? p.yellow : p.red);

/// The money line of one collection attempt, shown in the log and in the toast.
String resultSummary(CollectResult r) {
  if (r.gross > 0) return 'পেলে ${tk(r.gross)}, নেতা ${bnInt(leaderTaxPercent)}% ${tk(r.tax)} কেটে নিল, হাতে ${tk(r.net)}';
  return r.kind == Kind.complained ? 'পুলিশের নজর +${bnInt(r.heatDelta)}' : 'এবার কিছু পাওনি';
}

// ============================================================ এলাকা =======

/// The main game: ask cartoon neighbours for chada, keep the police-attention
/// meter low, and watch the leader above you take 10%.
class BeatScreen extends StatelessWidget {
  const BeatScreen({super.key});

  Future<void> _ask(BuildContext context, Target t) async {
    final wasFirst = baj.collected == 0;
    final r = baj.collect(t, _rng, seasonMult: currentSeason(DateTime.now())?.multiplier ?? 1);
    if (r.gross > 0 && wasFirst) app.badge('bajfirst');
    if (r.caught) {
      app.badge('caught1');
      await showDialog<void>(context: context, builder: (_) => _CaughtDialog(r));
    } else {
      // The event log is far down the page, so show the outcome right here too.
      toast('${r.target.emoji} ${r.line}\n${resultSummary(r)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: baj,
      builder: (_, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BhaiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('পাড়ায় বের হও', lede: 'কার কাছে কত পাও দেখো। সাবধান: পুলিশের নজর ১০০ হলে ধরা।'),
            Row(children: [
              Text('পুলিশের নজর', style: body(14, w: FontWeight.w700)),
              const Spacer(),
              Text('${bnInt(baj.heat)}%', style: body(14, w: FontWeight.w700, color: _heatColor(p, baj.heat))),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(value: baj.heat / 100, minHeight: 14, color: _heatColor(p, baj.heat), backgroundColor: p.line),
            ),
            const SizedBox(height: 12),
            BhaiButton(
              'চায়ের দোকানে আড্ডা (${tk(BajState.coolCost)}, নজর -${bnInt(BajState.coolAmount)})',
              kind: BtnKind.ghost,
              onTap: baj.canCool
                  ? () {
                      baj.coolDown();
                      toast('চা খেয়ে আড্ডা দিলে। নজর কমল।');
                    }
                  : () => toast(baj.heat == 0 ? 'নজর এমনিতেই শূন্য। কাজে নামো।' : 'চায়ের টাকাও নেই। আগে কিছু তোলো।'),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        for (final t in targets) Padding(padding: const EdgeInsets.only(bottom: 12), child: _TargetCard(t, onAsk: () => _ask(context, t))),
        if (baj.log.isNotEmpty) ...[
          const SizedBox(height: 4),
          BhaiCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('আজকের ঘটনা', style: body(20, w: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final r in baj.log) _LogRow(r),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Target t;
  final VoidCallback onAsk;
  const _TargetCard(this.t, {required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final mic = (1 + 0.2 * baj.level(UpgradeId.mic)) * (currentSeason(DateTime.now())?.multiplier ?? 1);
    final lo = ((t.minAmt * mic) / 10).round() * 10, hi = ((t.maxAmt * mic) / 10).round() * 10;
    final risky = t.complainHeat >= 30;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.surface, border: Border.all(color: p.ink, width: 1.5), borderRadius: BorderRadius.circular(4)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.emoji, style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.name, style: body(17, w: FontWeight.w700, h: 1.25)),
            Text(t.blurb, style: body(13.5, color: p.muted, h: 1.35)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('দাবি ${tk(lo)} থেকে ${tk(hi)}', style: body(13.5, w: FontWeight.w600)),
              if (risky)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: p.red, borderRadius: BorderRadius.circular(3)),
                  child: Text('ঝুঁকিপূর্ণ', style: body(11.5, w: FontWeight.w700, color: p.redInk)),
                ),
            ]),
            const SizedBox(height: 10),
            BhaiButton('চাঁদা চাও', kind: BtnKind.red, onTap: onAsk),
          ]),
        ),
      ]),
    );
  }
}

class _LogRow extends StatelessWidget {
  final CollectResult r;
  const _LogRow(this.r);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = switch (r.kind) {
      Kind.paid => p.green,
      Kind.haggled => p.yellow,
      Kind.fled => p.muted,
      Kind.complained => p.red,
    };
    final money = resultSummary(r);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(color: p.paper, border: Border(left: BorderSide(color: color, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${r.target.emoji} ${r.line}', style: body(14.5, h: 1.35)),
        Text(money, style: body(13, w: FontWeight.w700, color: r.gross > 0 ? p.green : p.muted, h: 1.35)),
      ]),
    );
  }
}

class _CaughtDialog extends StatelessWidget {
  final CollectResult r;
  const _CaughtDialog(this.r);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(side: BorderSide(color: p.ink, width: 2), borderRadius: BorderRadius.circular(4)),
      title: Text('🚔 ধরা খেয়েছ!', style: body(24, w: FontWeight.w700, color: p.red)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('পুলিশের নজর ১০০ ছুঁয়েছে। জরিমানা আর "চা-পানি" মিলিয়ে ${tk(r.fine)} গেল। নেতা বললেন, "আমি চিনি না ওকে।"', style: body(16)),
        const SizedBox(height: 10),
        Text('আসল চাঁদাবাজি অপরাধ এবং শাস্তিযোগ্য। কেউ জোর করে চাঁদা চাইলে ৯৯৯-এ জানাও।', style: body(13.5, color: p.muted)),
      ]),
      actions: [BhaiButton('আবার নামো', onTap: () => Navigator.pop(context))],
    );
  }
}

// ============================================================ দপ্তর =======

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: baj,
      builder: (_, _) {
        final idx = baj.rankIndex;
        final next = idx + 1 < ranks.length ? ranks[idx + 1] : null;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('তোমার র‍্যাঙ্ক', style: body(14, color: p.muted)),
              Text(baj.rankName, style: display(36, color: p.red)),
              const SizedBox(height: 8),
              if (next != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: ((baj.collected - ranks[idx].$1) / (next.$1 - ranks[idx].$1)).clamp(0, 1).toDouble(),
                    minHeight: 12,
                    color: p.green,
                    backgroundColor: p.line,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${next.$2} হতে আরও ${tk(next.$1 - baj.collected)} তুলতে হবে', style: body(13.5, color: p.muted)),
              ] else
                Text('সর্বোচ্চ র‍্যাঙ্ক। তবু নেতা ১০% নেয়।', style: body(14, color: p.muted)),
              const SizedBox(height: 12),
              Row(children: [
                _stat(p, tk(baj.collected), 'মোট তুলেছ'),
                const SizedBox(width: 8),
                _stat(p, tk(baj.taxPaid), 'নেতা নিয়েছে'),
                const SizedBox(width: 8),
                _stat(p, bnInt(baj.caught), 'ধরা খেয়েছ'),
              ]),
              ShareBar(
                text: '${baj.rankName}! চাঁদা বাজার খেলায় তুলেছি ${tk(baj.collected)}, তার ${tk(baj.taxPaid)} নেতা নিয়ে গেল, আর ${bnInt(baj.caught)} বার ধরা খেয়েছি 🏍️😂 তুমি কত দূর পারবে?',
                card: ShareCardData(
                  kicker: 'ভাইগিরি রিপোর্ট',
                  title: baj.rankName,
                  rows: [('মোট তুলেছি', tk(baj.collected)), ('নেতা নিয়েছে (${bnInt(leaderTaxPercent)}%)', tk(baj.taxPaid)), ('ধরা খেয়েছি', '${bnInt(baj.caught)} বার'), ('পকেটে আছে', tk(baj.cash))],
                  big: 'নেতা আগেও ১০% নিত, এখনো নেয়।',
                  stamp: 'ভাইগিরি',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CardTitle('আপগ্রেড কিনো', lede: 'পকেটে আছে ${tk(baj.cash)}'),
              for (final d in upgradeDefs) _upgrade(context, p, d),
            ]),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: BhaiButton('নতুন করে শুরু করো', kind: BtnKind.ghost, onTap: () {
              baj.reset();
              toast('সব শূন্য। ভাইগিরি আবার শুরু।');
            }),
          ),
        ]);
      },
    );
  }

  Widget _stat(Palette p, String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: body(19, w: FontWeight.w700))),
            Text(l, style: body(12, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _upgrade(BuildContext context, Palette p, UpgradeDef d) {
    final lvl = baj.level(d.id);
    final maxed = lvl >= d.maxLevel;
    final cost = upgradeCost(d, lvl);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${d.name} · লেভেল ${bnInt(lvl)}/${bnInt(d.maxLevel)}', style: body(15.5, w: FontWeight.w700, h: 1.3)),
            Text(d.effect, style: body(13, color: p.muted, h: 1.35)),
            const SizedBox(height: 8),
            BhaiButton(
              maxed ? 'সর্বোচ্চ' : 'কিনো ${tk(cost)}',
              kind: maxed ? BtnKind.ghost : BtnKind.green,
              onTap: maxed
                  ? null
                  : () {
                      if (baj.buy(d)) {
                        app.badge('upgrade1');
                        toast('${d.name} আপগ্রেড হলো।');
                      } else {
                        toast('টাকা কম। আগে আরও তোলো।');
                      }
                    },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ============================================================== মাইক ======

const _occasions = ['ঈদ', 'পূজা', 'পহেলা বৈশাখ', 'ক্লাবের বার্ষিক পিকনিক', 'পাড়ার ফুটবল টুর্নামেন্ট', 'নতুন মাইক কেনা'];
const _reasons = [
  'রাস্তার গর্ত মেরামতের (গর্তটা দেখতে পাড়ার সবাইকে আসতে হবে)',
  'চাঁদের আলো ঠিক রাখার',
  'পাড়ার কুকুরদের টিকার (কুকুররা রাজি নয়)',
  'মাইকের ব্যাটারির যা কখনো থামে না',
  'ভাইয়ের নতুন জুতার, কারণ পাড়ার ইজ্জত',
  'বর্ষার আগে ছাতা কেনার',
  'পুকুরের মাছদের গান শোনানোর',
];
const _deadlines = ['আজ সন্ধ্যা ৬টার মধ্যে', 'বৃহস্পতিবারের মধ্যে', 'পরের লোডশেডিং শুরুর আগে', 'চা ঠান্ডা হওয়ার আগে'];
const _consequences = [
  'পাড়ার মাইকে আপনার নাম তিনবার বলা হবে',
  'আপনার জন্য একটা গান বাজানো হবে, যেটা আপনি চান না',
  'পরের বছর চাঁদা দ্বিগুণ হবে',
  'ভাই আপনার বাসার সামনে দাঁড়িয়ে হাসবেন',
];

/// A jokey loudspeaker-announcement generator.
class MicScreen extends StatefulWidget {
  const MicScreen({super.key});
  @override
  State<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen> {
  late String _text = _make();

  String _make() {
    final amt = (50 + _rng.nextInt(20) * 50);
    return 'আসসালামু আলাইকুম! পাড়াবাসীর অবগতির জন্য জানানো যাচ্ছে যে ${_occasions[_rng.nextInt(_occasions.length)]} উপলক্ষে '
        '${_reasons[_rng.nextInt(_reasons.length)]} জন্য প্রতি পরিবার ${tk(amt)} করে দেবেন, ${_deadlines[_rng.nextInt(_deadlines.length)]}। '
        'না দিলে ${_consequences[_rng.nextInt(_consequences.length)]}। ধন্যবাদ।';
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('পাড়ার মাইক ঘোষণা', tag: 'বাহানা জেনারেটর', lede: 'ভাইয়ের গলায় একটা ঘোষণা তৈরি করো। কারণটা যত উদ্ভট, তত ভালো।'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.paper, border: Border(left: BorderSide(color: p.red, width: 4))),
          child: Text(_text, style: body(16.5, h: 1.6)),
        ),
        const SizedBox(height: 14),
        BhaiButton('আরেকটা ঘোষণা', kind: BtnKind.red, onTap: () => setState(() => _text = _make())),
        ShareBar(
          text: '📢 $_text',
          card: ShareCardData(kicker: 'পাড়ার মাইক', title: 'জরুরি ঘোষণা!', rows: const [], big: _text, stamp: 'মাইক'),
        ),
      ]),
    );
  }
}

// ======================================================== ভাইদের তালিকা ====

const _otherBhais = <(String, int)>[
  ('মোড়ের কালু ভাই', 62000),
  ('গলির টুনটুনি ভাই', 31500),
  ('বটতলার বদরুল ভাই', 17800),
  ('পুরোনো মার্কেটের মিঠু ভাই', 9400),
  ('নতুন পাড়ার ছোট ভাই', 3100),
];

class BajBoardScreen extends StatelessWidget {
  const BajBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: baj,
      builder: (_, _) {
        final rows = <(String, int, bool)>[
          for (final o in _otherBhais) (o.$1, o.$2, false),
          ('তুমি', baj.collected, true),
        ]..sort((a, b) => b.$2.compareTo(a.$2));
        return BhaiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('এলাকার ভাইদের তালিকা', lede: 'এলাকার সব ভাইয়ের মধ্যে তুমি কত নম্বরে। সবার ওপরে নেতা ১০% নেন।'),
            for (var i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                decoration: BoxDecoration(color: rows[i].$3 ? p.yellow : null, border: Border(bottom: BorderSide(color: p.line))),
                child: Row(children: [
                  SizedBox(width: 28, child: Text(bnInt(i + 1), style: body(15, w: FontWeight.w700, color: rows[i].$3 ? p.yellowInk : p.muted))),
                  Expanded(child: Text(rows[i].$1, style: body(15, w: rows[i].$3 ? FontWeight.w700 : FontWeight.w500, color: rows[i].$3 ? p.yellowInk : p.ink))),
                  Text(tk(rows[i].$2), style: body(15, w: FontWeight.w700, color: rows[i].$3 ? p.yellowInk : p.ink)),
                ]),
              ),
          ]),
        );
      },
    );
  }
}
