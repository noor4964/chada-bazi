import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

// ======================================================= ভাইয়ের কল ========

const _callLines = [
  ['হ্যালো, চিনছো? আমি পাড়ার ভাই।', 'তোমার নাম লিস্টে উপরে আছে। অভিনন্দন।', 'এবার একটু বেশি লাগবে, ডলারের দাম বেড়েছে।', 'বিকাশে না, হাতে হাতে। রসিদ? কিসের রসিদ?'],
  ['কী খবর? শুনলাম নতুন জুতা কিনছো।', 'জুতা কিনতে পারো, চাঁদা দিতে পারো না?', 'আজ সন্ধ্যায় চায়ের দোকানে আসো।', 'না আসলে আমি তোমার বাসায় চা খেতে আসব।'],
  ['ভাই বলছি। ফোন কেটে দিও না, আবার দিব।', 'তোমার ফেসবুকে দেখলাম কক্সবাজার গেছিলা।', 'সমুদ্র দেখার ট্যাক্স বাকি আছে।', 'টাকা রেডি রাখো, না হলে পরের ট্যুরে আমিও যাব।'],
];
const _smsList = [
  'ফোন ধরো না কেন? নেটওয়ার্ক খারাপ হলে টাওয়ারের চাঁদাও তুমি দিবা।',
  'কল কাটার জন্য ৳৫০ যোগ হলো। আরেকবার কাটো, দেখি।',
  'আমি জানি তুমি অনলাইনে আছো। সবুজ বাতি জ্বলছে।',
  'ঠিক আছে, ধরতে হবে না। আমি বাসার নিচেই আছি।',
  'তোমার আম্মুর নম্বর আমার কাছে আছে, মনে রেখো।',
  'এত কল কাটলে আমি তো ভাবব তুমি আমাকে ভালোবাসো না।',
];

/// Builds a looping two-tone ring as a 16-bit mono WAV, so no asset file is needed.
Uint8List _ringtoneWav() {
  const rate = 8000;
  final samples = <int>[];
  void tone(double hz, double sec) {
    for (var i = 0; i < (rate * sec).round(); i++) {
      final env = math.min(1.0, math.min(i, (rate * sec).round() - i) / 200);
      samples.add((math.sin(2 * math.pi * hz * i / rate) * 9000 * env).round());
    }
  }

  void gap(double sec) => samples.addAll(List.filled((rate * sec).round(), 0));
  tone(523, .18); tone(659, .18); gap(.1); tone(523, .18); tone(659, .18); gap(1.1);
  final data = ByteData(44 + samples.length * 2);
  void s(int o, String t) { for (var i = 0; i < t.length; i++) { data.setUint8(o + i, t.codeUnitAt(i)); } }
  s(0, 'RIFF'); data.setUint32(4, 36 + samples.length * 2, Endian.little); s(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little); data.setUint16(20, 1, Endian.little); data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little); data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little); data.setUint16(34, 16, Endian.little);
  s(36, 'data'); data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) { data.setInt16(44 + i * 2, samples[i], Endian.little); }
  return data.buffer.asUint8List();
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  String _sms = 'ফোন ধরো না কেন? নেটওয়ার্ক খারাপ হলে টাওয়ারের চাঁদাও তুমি দিবা।';
  bool _pending = false;

  Future<void> _start() async {
    if (!mounted) return;
    final res = await Navigator.of(context, rootNavigator: true).push<String>(
      PageRouteBuilder(opaque: true, pageBuilder: (_, _, _) => const _CallPage()),
    );
    if (res == 'no') {
      app.update(() {
        app.missed++;
        app.fine += 50 * app.missed;
      });
      app.pay(50 * app.missed);
      setState(() => _sms = _smsList[math.min(app.missed - 1, _smsList.length - 1)]);
      toast('কল কেটেছ। জরিমানা ${tk(50 * app.missed)} যোগ হলো।');
      if (app.missed >= 5) app.badge('call5');
      if (app.missed % 3 == 0) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          toast('ভাই আবার কল দিচ্ছে…');
          Future.delayed(const Duration(milliseconds: 1200), _start);
        });
      }
    } else if (res == 'yes') {
      app.update(() => app.taken++);
      app.badge('answered');
    }
  }

  void _prank() {
    if (_pending) return;
    setState(() => _pending = true);
    toast('৫ সেকেন্ড পরে কল আসবে। ফোনটা বন্ধুর হাতে দাও 😈');
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _pending = false);
      _start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) => BhaiCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('ভাই কল করছে…',
              tag: 'সাউন্ড অন করো',
              lede: 'ধরলে চাঁদা, না ধরলে ডাবল চাঁদা। কতবার কাটতে পারো দেখি। বন্ধুর সামনে চালিয়ে মজা নাও।'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            BhaiButton('কল আসতে দাও', kind: BtnKind.red, onTap: _start),
            BhaiButton(_pending ? 'কল আসছে…' : '৫ সেকেন্ড পরে কল (বন্ধুকে ভয় দেখাও)', kind: BtnKind.ghost, onTap: _prank),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _stat(p, bnInt(app.missed), 'কল কেটেছ'),
            const SizedBox(width: 8),
            _stat(p, bnInt(app.taken), 'কল ধরেছ'),
            const SizedBox(width: 8),
            _stat(p, tk(app.fine), 'জরিমানা'),
          ]),
          OutBox(
            accent: p.red,
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'ভাই: ', style: body(15, w: FontWeight.w700)),
              TextSpan(text: _sms, style: body(15)),
            ])),
          ),
          ShareBar(
            text: 'ভাইয়ের ${bnInt(app.missed)}টা কল কেটেছি, জরিমানা জমেছে ${tk(app.fine)} 📵😂 তুমি কয়টা কাটতে পারো?',
            card: ShareCardData(
              kicker: 'মিসড কল রিপোর্ট',
              title: 'ভাইয়ের ${bnInt(app.missed)}টা কল কেটেছি',
              rows: [('কল ধরেছি', '${bnInt(app.taken)}টা'), ('না ধরার জরিমানা', tk(app.fine))],
              big: 'ভাই: $_sms',
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(Palette p, String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: body(20, w: FontWeight.w700))),
            Text(l, style: body(12, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

class _CallPage extends StatefulWidget {
  const _CallPage();
  @override
  State<_CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<_CallPage> with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  final _shown = <String>[];
  Timer? _buzz, _step;
  bool _answered = false;
  String _status = 'মোবাইল কল…';

  @override
  void initState() {
    super.initState();
    if (app.missed > 0) _status = 'মোবাইল কল… (${bnInt(app.missed)}টা মিসড কল)';
    _ring();
  }

  Future<void> _ring() async {
    HapticFeedback.heavyImpact();
    _buzz = Timer.periodic(const Duration(milliseconds: 1400), (_) => HapticFeedback.heavyImpact());
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(_ringtoneWav(), mimeType: 'audio/wav'));
    } catch (_) {}
  }

  Future<void> _stopRing() async {
    _buzz?.cancel();
    try { await _player.stop(); } catch (_) {}
  }

  Future<void> _decline() async {
    await _stopRing();
    if (mounted) Navigator.pop(context, 'no');
  }

  Future<void> _accept() async {
    await _stopRing();
    final lines = pick(_callLines);
    setState(() { _answered = true; _status = 'কল চলছে'; });
    var i = 0;
    _step = Timer.periodic(const Duration(milliseconds: 1700), (t) {
      if (!mounted) return t.cancel();
      if (i < lines.length) {
        setState(() => _shown.add('“${lines[i++]}”'));
      } else {
        t.cancel();
        final amt = rnd(5, 30) * 100;
        app.pay(amt);
        setState(() => _shown.add('কল শেষ। দাবি: ${tk(amt)}'));
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) Navigator.pop(context, 'yes');
        });
      }
    });
  }

  @override
  void dispose() {
    _buzz?.cancel();
    _step?.cancel();
    _pulse.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF06180F),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B3D27), Color(0xFF06180F)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 36),
              child: Column(children: [
                Text(_status, style: body(15, color: const Color(0xBFF2ECD9))),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8102E),
                      shape: BoxShape.circle,
                      boxShadow: _answered
                          ? null
                          : [BoxShadow(color: const Color(0xFFF7C600).withValues(alpha: .6 * (1 - _pulse.value)), spreadRadius: 28 * _pulse.value)],
                    ),
                    alignment: Alignment.center,
                    child: child,
                  ),
                  child: Text('ভা', style: display(58, color: const Color(0xFFF7C600))),
                ),
                const SizedBox(height: 16),
                Text('পাড়ার ভাই 🔥', style: body(30, w: FontWeight.w700, color: const Color(0xFFF2ECD9))),
                Text('+৮৮০ ১৭XX-চাঁদা-০০', style: body(14, color: const Color(0xBFF2ECD9))),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      for (final l in _shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(l, textAlign: TextAlign.center, style: body(19, w: FontWeight.w600, color: l.startsWith('কল শেষ') ? const Color(0xFFF7C600) : const Color(0xFFF2ECD9))),
                        ),
                    ]),
                  ),
                ),
                if (!_answered)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _round(const Color(0xFFE5383B), Icons.call_end, 'কাটো', _decline),
                    _round(const Color(0xFF2BB673), Icons.call, 'ধরো', _accept),
                  ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _round(Color c, IconData icon, String label, VoidCallback onTap) => Column(children: [
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: body(13, color: const Color(0xFFF2ECD9))),
      ]);
}

// ====================================================== দরকষাকষি ========

class HaggleScreen extends StatefulWidget {
  const HaggleScreen({super.key});
  @override
  State<HaggleScreen> createState() => _HaggleScreenState();
}

class _HaggleScreenState extends State<HaggleScreen> {
  int _rate = 500;
  final _msgs = <(bool, String)>[(false, 'ঈদের চাঁদা ৳৫০০। দরদাম চলবে, তবে আমার দিকে।')];
  final _in = TextEditingController();
  final _scroll = ScrollController();

  int _up(double f) => (_rate * f / 10).round() * 10;

  String _reply(String t) {
    final n = firstNumber(t);
    String r;
    if (n != null) {
      if (n >= _rate) {
        _rate = _up(1.5);
        r = 'এত সহজে রাজি? তাহলে নিশ্চয়ই আরো আছে। এখন ${tk(_rate)}।';
      } else if (n < _rate * .3) {
        _rate = _up(1.25);
        r = pick(['${tk(n)}? এটা দিয়ে আমার চা-ও হয় না। অপমান ট্যাক্সসহ এখন ${tk(_rate)}।', 'ভাই হাসলো। হাসির চার্জসহ ${tk(_rate)}।', 'এই অফার শুনে ভাইয়ের বাইক বন্ধ হয়ে গেছে। মেরামতসহ ${tk(_rate)}।']);
      } else {
        _rate = _up(1.08);
        r = pick(['কাছাকাছি আসছো। তাই ${tk(_rate)}।', 'ভালো চেষ্টা। চেষ্টার জন্য ${tk(_rate)}।']);
      }
    } else if (RegExp('না|no', caseSensitive: false).hasMatch(t)) {
      _rate = _up(1.3);
      r = '"না" শব্দটা ভাইয়ের ডিকশনারিতে নেই। ${tk(_rate)}।';
    } else if (t.contains('রসিদ')) {
      _rate += 100;
      r = 'রসিদ চাইলা? রসিদ প্রিন্টের খরচ ৳১০০ যোগ। ${tk(_rate)}।';
    } else if (t.contains('পরে') || t.contains('কাল')) {
      _rate = _up(1.2);
      r = 'পরে দিলে সুদ লাগবে। দৈনিক ২০%। ${tk(_rate)}।';
    } else if (t.contains('প্লিজ') || t.contains('ভাই') || t.toLowerCase().contains('please')) {
      _rate += 50;
      r = 'আবেগে চিঁড়া ভেজে না। আবেগ চার্জ ৳৫০। ${tk(_rate)}।';
    } else {
      _rate += 30;
      r = pick(['বুঝলাম না। না বোঝার চার্জ ৳৩০। ${tk(_rate)}।', 'এত কথা বলো কেন? কথার বিল ${tk(_rate)}।']);
    }
    return r;
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });

  void _talk(String t) {
    t = t.trim();
    if (t.isEmpty) return;
    setState(() => _msgs.add((true, t)));
    _in.clear();
    _scrollDown();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _msgs.add((false, _reply(t))));
      _scrollDown();
    });
  }

  ShareCardData? _card;
  String _shareTxt = 'ভাইয়ের সাথে দরকষাকষি করতে গিয়েছিলাম। ভুল করেছিলাম। তুমিও চেষ্টা করো:';

  void _giveUp() {
    final paid = _rate, loss = _rate - 500;
    setState(() {
      _msgs.add((false, 'লক্ষ্মী নাগরিক। ${tk(paid)} বুঝে নিলাম। আগামী সপ্তাহে আবার দেখা হবে।'));
      _card = ShareCardData(
        kicker: 'দরকষাকষির ফলাফল',
        title: 'দরদাম করে ${tk(loss)} বেশি দিলাম',
        rows: [('শুরুর দাবি', tk(500)), ('শেষ পর্যন্ত দিলাম', tk(paid)), ('দরকষাকষির লাভ', '-${tk(loss)}')],
        stamp: 'হেরেছি',
      );
      _shareTxt = 'ভাইয়ের সাথে দরকষাকষি করে ${tk(500)} থেকে ${tk(paid)} দিয়ে আসলাম 🤡 দরদাম শিখতে চাইলে আমার কাছে আসবা না।';
      _rate = 500;
    });
    app.pay(paid);
    if (loss > 0) app.badge('haggle');
    _scrollDown();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _msgs.add((false, 'নতুন রাউন্ড। ঈদের চাঁদা ৳৫০০।')));
      _scrollDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('ভাইয়ের সাথে দরকষাকষি', lede: 'যত কমাতে চাইবে, তত বাড়বে। এটাই বাজারের নিয়ম।'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('শুরু: ৳৫০০', style: body(15, w: FontWeight.w700)),
          Text('এখন: ${tk(_rate)} (+${bnInt(((_rate - 500) / 5).round())}%)', style: body(15, w: FontWeight.w700, color: p.red)),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final (me, t) = _msgs[i];
              return Align(
                alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: me ? p.green : p.red,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(me ? 12 : 2),
                      bottomRight: Radius.circular(me ? 2 : 12),
                    ),
                  ),
                  child: Text(t, style: body(15.5, color: me ? p.greenInk : p.redInk)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in ['৳৫০ দিই?', 'ভাই প্লিজ', 'দেব না', 'রসিদ দেবেন?', 'পরে দিই'])
            ActionChip(
              label: Text(c, style: body(14)),
              onPressed: () => _talk(c),
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5),
              shape: const StadiumBorder(),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _in,
              onSubmitted: _talk,
              decoration: const InputDecoration(hintText: 'যেমন: ১০০ টাকা দিই?'),
            ),
          ),
          const SizedBox(width: 10),
          BhaiButton('বলো', onTap: () => _talk(_in.text)),
        ]),
        const SizedBox(height: 12),
        BhaiButton('হার মানো', kind: BtnKind.ghost, onTap: _giveUp),
        ShareBar(text: _shareTxt, card: _card),
      ]),
    );
  }
}

// ========================================================== পালাও ========

const _flee = [
  'হাহা, এত সহজ?', 'আঙুল এত ধীর কেন?', 'ভাই জিমে যায়, তুমি না।', 'বাটনও তোমাকে চাঁদা দিতে বলছে।',
  'বাম দিকে চাঁদা দেওয়ার বাটন আছে, ওটা সহজ।', 'তোমার চেষ্টা দেখে ভাইয়ের মায়া লাগছে।', 'আরেকবার চেষ্টার ফি ৳১০।',
  'তোমার আম্মু দেখলে কী বলতো?', 'বাটনটা ভাইয়ের ছেলে। ও দৌড় জানে।',
];

class FleeScreen extends StatefulWidget {
  const FleeScreen({super.key});
  @override
  State<FleeScreen> createState() => _FleeScreenState();
}

class _FleeScreenState extends State<FleeScreen> {
  static const _bw = 110.0, _bh = 44.0;
  int _tries = 0;
  bool _caught = false;
  Offset _pos = const Offset(180, 60);
  String _taunt = 'চেষ্টা: ০। ভাই অপেক্ষা করছে।';
  ShareCardData? _card;
  String _shareTxt = 'চাঁদা না দেওয়ার বাটনটা ধরতে পারো কিনা দেখো। আমি পারিনি 😩';
  static const _h = 280.0;
  double _w = 300;

  void _jump() {
    if (_caught) return;
    _tries++;
    if (_tries >= 18) {
      setState(() {
        _caught = true;
        _taunt = 'ক্লান্ত হয়ে গেলাম। এবার ধরতে দিলাম…';
      });
      return;
    }
    setState(() {
      _pos = Offset(8 + rng.nextDouble() * math.max(1, _w - _bw - 16), 8 + rng.nextDouble() * math.max(1, _h - _bh - 76));
      _taunt = 'চেষ্টা: ${bnInt(_tries)}। ${pick(_flee)}';
    });
  }

  void _catch() {
    if (!_caught) return;
    final n = _tries;
    app.update(() => app.escapes++);
    app.badge('escape');
    app.pay(200);
    setState(() {
      _taunt = 'মুক্তি! ${bnInt(n)} বার চেষ্টার পর। পেছনে তাকাও, ভাই দাঁড়িয়ে আছে। পালানোর জরিমানা ৳২০০।';
      _card = ShareCardData(
        kicker: 'পালাও চ্যালেঞ্জ',
        title: '${bnInt(n)} বার চেষ্টার পর মুক্তি',
        rows: [('পালানোর জরিমানা', tk(200)), ('মোট পালিয়েছি', '${bnInt(app.escapes)} বার')],
        big: 'পেছনে তাকাও, ভাই দাঁড়িয়ে আছে।',
        stamp: 'পলাতক',
      );
      _shareTxt = '"দেব না" বাটন ধরতে আমার ${bnInt(n)} বার লেগেছে, তারপরও ৳২০০ জরিমানা 😤 তুমি কয়বারে পারো?';
      _tries = 0;
      _caught = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('"দেব না" বাটনটা ধরো', lede: 'চাঁদা না দেওয়ার বাটন ধরতে পারলেই মুক্তি। চাঁদা দেওয়ার বাটন অবশ্য সবসময় হাতের কাছে।'),
        LayoutBuilder(builder: (_, c) {
          _w = c.maxWidth;
          return Container(
            height: _h,
            decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.muted, width: 2), borderRadius: BorderRadius.circular(6)),
            clipBehavior: Clip.hardEdge,
            child: Stack(children: [
              Positioned(
                left: 12,
                bottom: 12,
                child: BhaiButton('চাঁদা দিন ৳১০০', kind: BtnKind.red, onTap: () {
                  app.pay(100);
                  setState(() => _taunt = pick(['লক্ষ্মী নাগরিক। ভাই খুশি।', 'এত তাড়াতাড়ি? ভাই আরো চাইবে।', 'দিয়েছ বলে ভাই তোমার নাম ভালো লিস্টে লিখলো। ভালো লিস্টের চাঁদা বেশি।']));
                }),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                left: _pos.dx.clamp(0, math.max(0, _w - _bw)),
                top: _pos.dy,
                child: MouseRegion(
                  onEnter: (_) => _jump(),
                  child: GestureDetector(
                    onTapDown: (_) => _jump(),
                    onTap: _catch,
                    child: SizedBox(
                      width: _bw,
                      height: _bh,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.surface,
                          border: Border.all(color: p.ink, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: p.ink, offset: const Offset(3, 3))],
                        ),
                        child: Text(_caught ? 'ঠিক আছে, ধরো' : 'দেব না', style: body(15, w: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 10),
        SizedBox(height: 50, child: Text(_taunt, style: body(15.5, w: FontWeight.w600))),
        ShareBar(text: _shareTxt, card: _card),
      ]),
    );
  }
}
