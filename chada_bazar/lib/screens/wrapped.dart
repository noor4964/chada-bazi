import 'package:flutter/material.dart';

import '../ledger.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import '../wrapped.dart';

const _taunts = {
  'পূজা / ঈদ': 'উৎসবের আনন্দ, পকেটের কান্না',
  'ক্লাব': 'ক্লাবের নামে কে কী খেল, কেউ জানে না',
  'বিল্ডিং / সার্ভিস চার্জ': 'সার্ভিস নেই, চার্জ আছে',
  'চা-পানি': 'চা ছোট, বিল বড়',
  'টোল / পার্কিং': 'রাস্তাও এখন ভাড়ায়',
  'অন্যান্য': 'কারণ না জেনেই দিয়েছ',
};

/// A year recap as vertical story slides, one image per slide.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});
  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  static const _slideCount = 5;
  final _pc = PageController();
  final _keys = List.generate(_slideCount, (_) => GlobalKey());
  int _page = 0;
  bool _sample = false;
  bool _busy = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _shareSlide(WrappedData d) async {
    setState(() => _busy = true);
    try {
      await shareKeyAsPng(_keys[_page], '${d.year} সালে ${tk(d.total)} চাঁদা দিয়েছি 😭 আমার চাঁদা Wrapped:', pixelRatio: 3);
    } catch (_) {
      toast('ছবি শেয়ার হয়নি। লেখাটা কপি করে নিলাম।');
      await copyText('${d.year} সালে ${tk(d.total)} চাঁদা দিয়েছি 😭 আমার চাঁদা Wrapped!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final year = DateTime.now().year;
    return ListenableBuilder(
      listenable: ledger,
      builder: (_, _) {
        final data = _sample ? sampleWrapped(year) : buildWrapped(ledger, year);
        if (data == null) {
          return BhaiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('চাঁদা Wrapped', lede: 'বছর শেষে তোমার চাঁদার গল্প, স্টোরির মতো স্লাইডে। তোমার খাতায় এই বছরের কিছু লেখা নেই, তাই আগে কিছু লিখো। চাইলে একটা উদাহরণ দেখতে পারো।'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                BhaiButton('উদাহরণ দেখো', kind: BtnKind.red, onTap: () => setState(() => _sample = true)),
              ]),
            ]),
          );
        }
        // Awarding a badge notifies listeners, which is not allowed while building.
        if (!app.badges.contains('wrapped1')) WidgetsBinding.instance.addPostFrameCallback((_) => app.badge('wrapped1'));
        final slides = _slides(p, data);
        return BhaiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardTitle('${bnDigits('${data.year}')} চাঁদা Wrapped', tag: _sample ? 'উদাহরণ' : 'তোমার খাতা থেকে', lede: 'স্লাইড টেনে দেখো, যেটা পছন্দ সেটা ছবি করে স্টোরিতে দাও।'),
            LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth.clamp(200.0, 360.0);
              return Center(
                child: SizedBox(
                  width: w,
                  height: w * 16 / 9,
                  child: PageView(
                    controller: _pc,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        FittedBox(
                          fit: BoxFit.contain,
                          child: RepaintBoundary(key: _keys[i], child: SizedBox(width: 360, height: 640, child: slides[i])),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _slideCount; i++)
                Container(
                  width: i == _page ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(color: i == _page ? p.red : p.line, borderRadius: BorderRadius.circular(4)),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              BhaiButton('◀', kind: BtnKind.ghost, onTap: _page == 0 ? null : () => _pc.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)),
              BhaiButton('▶', kind: BtnKind.ghost, onTap: _page == _slideCount - 1 ? null : () => _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)),
              BhaiButton(_busy ? 'অপেক্ষা…' : 'এই স্লাইড শেয়ার করো', kind: BtnKind.red, onTap: _busy ? null : () => _shareSlide(data)),
              if (_sample) BhaiButton('উদাহরণ বন্ধ', kind: BtnKind.ghost, onTap: () => setState(() => _sample = false)),
            ]),
          ]),
        );
      },
    );
  }

  List<Widget> _slides(Palette p, WrappedData d) {
    final yr = bnDigits('${d.year}');
    return [
      _Slide(
        bg: const Color(0xFFC8102E), fg: Colors.white, kicker: '$yr সালের চাঁদা হিসাব',
        big: tk(d.total), bigSize: 76,
        sub: '${bnInt(d.count)} বার পকেট থেকে বের হয়েছে।\nগড়ে ${tk(d.average)} করে।', footer: 'চাঁদা Wrapped $yr',
      ),
      _Slide(
        bg: const Color(0xFF1C1A16), fg: const Color(0xFFF2ECD9), kicker: 'সবচেয়ে বেশি গেছে',
        big: d.topCategory, bigSize: 46,
        sub: '${tk(d.topAmount)} · মোট চাঁদার ${bnInt(d.topPercent)}%\n${_taunts[d.topCategory] ?? 'ভাই খুশি'}', footer: 'চাঁদা Wrapped $yr',
      ),
      _Slide(
        bg: const Color(0xFFF7C600), fg: const Color(0xFF1C1A16), kicker: 'সবচেয়ে ব্যয়বহুল মাস',
        big: bnMonthNames[d.peakMonth - 1], bigSize: 56,
        sub: '${tk(d.peakAmount)} গেছে এই মাসে।\nভাই ছুটি নেয়নি।', footer: 'চাঁদা Wrapped $yr',
      ),
      _Slide(
        bg: const Color(0xFF0B5D3B), fg: const Color(0xFFF2ECD9), kicker: 'ধারের হিসাব',
        big: d.loanCount == 0 ? 'ধার নেই' : 'পাব ${tk(d.owedToMe)}', bigSize: 52,
        sub: d.loanCount == 0 ? 'ভাই হতাশ।' : 'দেব ${tk(d.iOwe)}\n${d.owedToMe >= d.iOwe ? 'তুমি আসলে একটা ব্যাংক।' : 'ধারে একটু ডুবে আছো।'}', footer: 'চাঁদা Wrapped $yr',
      ),
      _Slide(
        bg: const Color(0xFFF2ECD9), fg: const Color(0xFF1C1A16), accent: const Color(0xFFC8102E), kicker: 'ভাইয়ের চোখে তুমি',
        big: d.title, bigSize: 46,
        sub: '$yr সালে ${tk(d.total)} দিয়ে এই খেতাব পেলে।\nবন্ধুরা কত দিয়েছে জানতে চাও?', footer: 'চাঁদা বাজার · তোমারটা বানাও',
      ),
    ];
  }
}

/// One 360x640 story slide.
class _Slide extends StatelessWidget {
  final Color bg, fg;
  final Color? accent;
  final String kicker, big, sub, footer;
  final double bigSize;
  const _Slide({
    required this.bg,
    required this.fg,
    required this.kicker,
    required this.big,
    required this.sub,
    required this.footer,
    required this.bigSize,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('চাঁদা বাজার', style: display(34, color: accent ?? const Color(0xFFF7C600))),
        const Spacer(),
        Text(kicker, style: body(19, w: FontWeight.w600, color: fg.withValues(alpha: .85))),
        const SizedBox(height: 8),
        Text(big, style: display(bigSize, color: accent ?? fg).copyWith(height: 1.1)),
        const SizedBox(height: 16),
        Text(sub, style: body(19, w: FontWeight.w600, color: fg, h: 1.5)),
        const Spacer(),
        Text(footer, style: body(13.5, w: FontWeight.w600, color: fg.withValues(alpha: .7))),
        Text('ব্যঙ্গ ও বিনোদন। আসল চাঁদাবাজি অপরাধ।', style: body(10.5, color: fg.withValues(alpha: .6))),
      ]),
    );
  }
}
