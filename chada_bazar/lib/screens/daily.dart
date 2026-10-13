import 'package:flutter/material.dart';

import '../baj_state.dart';
import '../daily.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'baj_screens.dart' show resultSummary;

/// Same four neighbours and the same dice for everyone, five tries a day.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});
  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  @override
  void initState() {
    super.initState();
    daily.ensureToday();
  }

  void _play(int i) {
    final a = daily.play(i);
    if (daily.run.finished) {
      app.badge('daily1');
      if (a.caught) toast('🚔 ধরা খেয়েছ! আজকের রান শেষ।');
    } else {
      toast('${a.target.emoji} ${a.roll.line}\n${resultSummary(CollectResult(target: a.target, kind: a.roll.kind, line: a.roll.line, gross: a.roll.gross, tax: a.tax, net: a.net, heatDelta: a.roll.heatDelta))}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: daily,
      builder: (_, _) {
        final run = daily.run;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CardTitle('আজকের চাঁদা #${bnInt(run.day)}',
                  tag: 'প্রতিদিন নতুন',
                  lede: 'সবার একই পাড়া, একই ভাগ্য। ৫ বারে যত পারো তোলো, তারপর বন্ধুদের সাথে স্কোর মেলাও।'),
              Row(children: [
                for (var i = 0; i < dailyAttempts; i++)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == dailyAttempts - 1 ? 0 : 8),
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < run.attempts.length ? p.paper : p.surface,
                        border: Border.all(color: i == run.attempts.length && !run.finished ? p.red : p.ink, width: i == run.attempts.length && !run.finished ? 3 : 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(i < run.attempts.length ? run.attempts[i].emoji : '', style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Text('পুলিশের নজর', style: body(13.5, w: FontWeight.w700)),
                const Spacer(),
                Text('${bnInt(run.heat)}%', style: body(13.5, w: FontWeight.w700, color: run.heat < 40 ? p.green : (run.heat < 70 ? p.yellowInk : p.red))),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: run.heat / 100, minHeight: 10, color: run.heat < 40 ? p.green : (run.heat < 70 ? p.yellow : p.red), backgroundColor: p.line),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _stat(p, '${bnInt(daily.streak)} দিন', 'টানা খেলেছ'),
                const SizedBox(width: 8),
                _stat(p, tk(daily.best), 'সেরা স্কোর'),
                const SizedBox(width: 8),
                _stat(p, tk(run.score), 'আজকের স্কোর'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          if (!run.finished) ...[
            Text('কার কাছে যাবে? ${bnInt(dailyAttempts - run.attempts.length)}টা সুযোগ বাকি', style: body(16, w: FontWeight.w700)),
            const SizedBox(height: 10),
            for (var i = 0; i < run.lineup.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _lineupCard(p, run.lineup[i], () => _play(i)),
              ),
          ] else
            _result(p, run),
        ]);
      },
    );
  }

  Widget _stat(Palette p, String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: body(18, w: FontWeight.w700))),
            Text(l, style: body(12, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _lineupCard(Palette p, Target t, VoidCallback onTap) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.surface, border: Border.all(color: p.ink, width: 1.5), borderRadius: BorderRadius.circular(4)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: body(16.5, w: FontWeight.w700, h: 1.25)),
              Text('দাবি ${tk(t.minAmt)} থেকে ${tk(t.maxAmt)}${t.complainHeat >= 30 ? ' · ঝুঁকিপূর্ণ' : ''}', style: body(13.5, color: p.muted)),
              const SizedBox(height: 8),
              BhaiButton('চাঁদা চাও', kind: BtnKind.red, onTap: onTap),
            ]),
          ),
        ]),
      );

  Widget _result(Palette p, DailyRun run) {
    final rows = <(String, String?)>[
      for (final a in run.attempts) ('${a.emoji} ${a.target.name}', a.roll.gross > 0 ? tk(a.net) : '০'),
    ];
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(run.caught ? '🚔 ধরা খেয়েছ' : 'আজকের রান শেষ', style: body(20, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(run.attempts.map((a) => a.emoji).join(' '), style: const TextStyle(fontSize: 30)),
        const SizedBox(height: 4),
        Text(tk(run.score), style: display(56, color: p.red)),
        Text('নেতা নিয়েছে ${tk(run.tax)}${run.caught ? ' · ধরা পড়ায় অর্ধেক কাটা' : ''}', style: body(14, color: p.muted)),
        const SizedBox(height: 10),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [Expanded(child: Text(r.$1, style: body(14.5))), Text(r.$2 ?? '', style: body(14.5, w: FontWeight.w700))]),
          ),
        const SizedBox(height: 8),
        Text('কাল নতুন পাড়া আসবে। স্কোরটা এখনই বন্ধুদের গ্রুপে ছাড়ো।', style: body(14, color: p.muted)),
        ShareBar(
          text: run.shareText(),
          card: ShareCardData(
            kicker: 'আজকের চাঁদা #${bnInt(run.day)}',
            title: 'আজ তুলেছি ${tk(run.score)}',
            rows: [for (final a in run.attempts) ('${a.emoji} ${a.target.name}', a.roll.gross > 0 ? tk(a.net) : null), ('নেতা নিয়েছে', tk(run.tax))],
            big: run.caught ? 'ধরা খেয়েছি, অর্ধেক গেল' : 'পাঁচ সুযোগে এটুকুই',
            stamp: run.caught ? 'ধরা' : 'রান শেষ',
          ),
        ),
      ]),
    );
  }
}
