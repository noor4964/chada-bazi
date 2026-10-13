import 'package:flutter/material.dart';

import '../duel.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Two people, one phone: one is the ভাই, the other haggles.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});
  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final _bhaiName = TextEditingController(text: 'রফিক');
  final _payerName = TextEditingController(text: 'নিলয়');
  int _start = 500;
  String? _err;
  DuelGame? _g;
  double _offer = 100, _counter = 400;

  @override
  void dispose() {
    _bhaiName.dispose();
    _payerName.dispose();
    super.dispose();
  }

  void _begin() {
    final (b, e1) = cleanName(_bhaiName.text);
    final (p, e2) = cleanName(_payerName.text);
    setState(() => _err = e1 ?? e2);
    if (b == null || p == null) return;
    setState(() {
      _g = DuelGame(bhai: b, payer: p, startDemand: _start);
      _offer = (_start * 0.2 / 10).round() * 10.0;
      _counter = _start.toDouble() - 10;
    });
  }

  void _after() {
    final g = _g!;
    if (g.finished) {
      app.badge('duel1');
    } else if (g.status == DuelStatus.payerTurn) {
      _offer = _offer.clamp(0, (g.demand - 10).toDouble());
    } else if (g.canCounter) {
      _counter = _counter.clamp((g.lastOffer + 10).toDouble(), (g.demand - 10).toDouble());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final g = _g;
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('ফোন পাস দরকষাকষি', tag: 'দুজনের খেলা', lede: 'একজন ভাই, আরেকজন চাঁদাদাতা। ফোনটা হাতবদল করে করে দাম কষো। শেষে কে জিতল, স্ক্রিনশট নাও।'),
        if (g == null) ..._setup(p) else ..._play(p, g),
      ]),
    );
  }

  List<Widget> _setup(Palette p) => [
        TextField(controller: _bhaiName, maxLength: 20, decoration: const InputDecoration(labelText: 'ভাইয়ের ডাকনাম', counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: _payerName, maxLength: 20, decoration: const InputDecoration(labelText: 'চাঁদাদাতার ডাকনাম', counterText: '')),
        const SizedBox(height: 12),
        Text('শুরুর দাবি', style: body(13.5, color: p.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in [300, 500, 800, 1000])
            ChoiceChip(
              label: Text(tk(v), style: body(15, w: FontWeight.w700, color: _start == v ? p.yellowInk : p.ink)),
              selected: _start == v,
              selectedColor: p.yellow,
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5),
              showCheckmark: false,
              onSelected: (_) => setState(() => _start = v),
            ),
        ]),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
        const SizedBox(height: 14),
        BhaiButton('শুরু করো', kind: BtnKind.red, onTap: _begin),
      ];

  Widget _bubble(Palette p, DuelMessage m) => Align(
        alignment: m.fromBhai ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: m.fromBhai ? p.red : p.green,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(m.fromBhai ? 2 : 12),
              bottomRight: Radius.circular(m.fromBhai ? 12 : 2),
            ),
          ),
          child: Text(m.text, style: body(15.5, color: m.fromBhai ? p.redInk : p.greenInk)),
        ),
      );

  List<Widget> _play(Palette p, DuelGame g) {
    final chat = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${g.bhai} (ভাই) বনাম ${g.payer}', style: body(13, w: FontWeight.w700, color: p.muted)),
        const SizedBox(height: 8),
        for (final m in g.log) _bubble(p, m),
      ]),
    );

    if (g.finished) {
      final transcript = [for (final m in g.log) ('${m.fromBhai ? g.bhai : g.payer}: ${m.text}', null)];
      return [
        chat,
        const SizedBox(height: 12),
        Text(g.verdict, style: body(19, w: FontWeight.w700, color: p.green)),
        Text('শেষ দাম ${tk(g.finalAmount ?? 0)} (শুরুতে ${tk(g.startDemand)})', style: body(14.5, color: p.muted)),
        const SizedBox(height: 12),
        BhaiButton('আবার খেলো', kind: BtnKind.ghost, onTap: () => setState(() => _g = null)),
        ShareBar(
          text: '${g.bhai} ভাই ${tk(g.startDemand)} চেয়েছিল, ${g.payer} শেষে দিল ${tk(g.finalAmount ?? 0)}। ${g.verdict} 🤝😂',
          card: ShareCardData(
            kicker: 'ফোন পাস দরকষাকষি',
            title: g.winner == 'draw' ? 'ড্র! ${tk(g.finalAmount ?? 0)}-এ রফা' : '${g.winnerName} জিতেছে',
            rows: transcript.take(7).toList(),
            big: 'শেষ দাম ${tk(g.finalAmount ?? 0)}',
            stamp: g.winner == 'draw' ? 'ড্র' : 'জয়',
          ),
        ),
      ];
    }

    final payerTurn = g.status == DuelStatus.payerTurn;
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: p.yellow, borderRadius: BorderRadius.circular(4), border: Border.all(color: p.ink, width: 2)),
        child: Text(
          payerTurn ? '📱 ফোন এখন ${g.payer}-এর হাতে। অফার দাও (রাউন্ড ${bnInt(g.round)}/${bnInt(duelMaxRounds)})' : '📱 ফোন এখন ${g.bhai}-এর হাতে। মেনে নেবে, না নতুন দাবি?',
          style: body(15, w: FontWeight.w700, color: p.yellowInk),
        ),
      ),
      const SizedBox(height: 12),
      chat,
      const SizedBox(height: 12),
      if (payerTurn) ...[
        Text('তোমার অফার: ${tk(_offer.round())}   (দাবি ${tk(g.demand)})', style: body(16, w: FontWeight.w700)),
        Slider(
          value: _offer.clamp(0, (g.demand - 10).toDouble()),
          min: 0,
          max: (g.demand - 10).toDouble(),
          divisions: ((g.demand - 10) / 10).round().clamp(1, 1000),
          activeColor: p.green,
          inactiveColor: p.line,
          label: tk(_offer.round()),
          onChanged: (v) => setState(() => _offer = (v / 10).round() * 10.0),
        ),
        BhaiButton('অফার দাও', kind: BtnKind.green, onTap: () {
          g.payerOffer(_offer.round());
          _after();
        }),
      ] else ...[
        Text('${g.payer} দিতে চায় ${tk(g.lastOffer)}', style: body(16, w: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          BhaiButton('মেনে নাও ${tk(g.lastOffer)}', kind: BtnKind.green, onTap: () {
            g.bhaiAccept();
            _after();
          }),
          BhaiButton('রেগে যাও', kind: BtnKind.red, onTap: () {
            g.bhaiAngry();
            _after();
          }),
        ]),
        if (g.canCounter) ...[
          const SizedBox(height: 14),
          Text('নতুন দাবি: ${tk(_counter.round())}', style: body(16, w: FontWeight.w700)),
          Slider(
            value: _counter.clamp((g.lastOffer + 10).toDouble(), (g.demand - 10).toDouble()),
            min: (g.lastOffer + 10).toDouble(),
            max: (g.demand - 10).toDouble(),
            divisions: (((g.demand - 10) - (g.lastOffer + 10)) / 10).round().clamp(1, 1000),
            activeColor: p.red,
            inactiveColor: p.line,
            label: tk(_counter.round()),
            onChanged: (v) => setState(() => _counter = (v / 10).round() * 10.0),
          ),
          BhaiButton('নতুন দাবি দাও', onTap: () {
            g.bhaiCounter(_counter.round());
            _after();
          }),
        ] else
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('এটা শেষ রাউন্ড। মেনে নাও, নয়তো রেগে যাও।', style: body(13.5, color: p.muted))),
      ],
    ];
  }
}
