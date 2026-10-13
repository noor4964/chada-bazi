import 'package:flutter/material.dart';

import '../season.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'khata.dart' show bnDate;

/// Festival season status plus a weekly made-up price report.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final now = DateTime.now();
    final cur = currentSeason(now);
    final nxt = nextSeason(now);
    final b = bulletinFor(now);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (cur != null) ...[
            Text('${cur.emoji} ${cur.name} চলছে', style: body(22, w: FontWeight.w700, color: p.red)),
            const SizedBox(height: 2),
            Text(cur.tagline, style: body(15.5)),
            const SizedBox(height: 8),
            Text('ভাই গেমে চাঁদার অঙ্ক ${bnDigits(cur.multiplier.toString())} গুণ, ${bnDate(cur.end)} পর্যন্ত।', style: body(14, color: p.muted)),
          ] else ...[
            Text('এখন কোনো মৌসুম নেই', style: body(20, w: FontWeight.w700)),
            if (nxt != null) ...[
              const SizedBox(height: 2),
              Text('পরের মৌসুম: ${nxt.emoji} ${nxt.name}, ${bnDate(nxt.start)} থেকে', style: body(15, color: p.muted)),
            ],
          ],
          const SizedBox(height: 6),
          Text('উৎসবের তারিখ আনুমানিক ধরা, প্রতি বছর ঠিক করা হয়।', style: body(12.5, color: p.muted)),
        ]),
      ),
      const SizedBox(height: 16),
      BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CardTitle('সাপ্তাহিক চাঁদা মুদ্রাস্ফীতি রিপোর্ট', tag: 'সপ্তাহ ${bnInt(b.week)}', lede: b.headline),
          for (final i in b.items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.name, style: body(15.5, w: FontWeight.w700, h: 1.25)),
                    Text(i.note, style: body(13, color: p.muted, h: 1.3)),
                  ]),
                ),
                const SizedBox(width: 10),
                Text(signedPercent(i.percent), style: body(17, w: FontWeight.w700, color: i.percent >= 0 ? p.red : p.green)),
              ]),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Text('ভাইদর সূচক', style: body(15, w: FontWeight.w700)),
            const Spacer(),
            Text(signedPercent(b.index), style: body(22, w: FontWeight.w700, color: b.index >= 0 ? p.red : p.green)),
          ]),
          ShareBar(
            text: '📰 চাঁদা মুদ্রাস্ফীতি রিপোর্ট, সপ্তাহ ${bnInt(b.week)}: ${b.headline}। ভাইদর সূচক ${signedPercent(b.index)}।',
            card: ShareCardData(
              kicker: 'সপ্তাহ ${bnInt(b.week)}',
              title: b.headline,
              rows: [for (final i in b.items) (i.name, signedPercent(i.percent)), ('ভাইদর সূচক', signedPercent(b.index))],
              stamp: 'খবর',
            ),
          ),
        ]),
      ),
    ]);
  }
}
