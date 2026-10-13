import 'dart:async';

import 'package:flutter/material.dart';

import 'baj_state.dart';
import 'daily.dart';
import 'ledger.dart';
import 'screens/baj_screens.dart';
import 'screens/bhag.dart';
import 'screens/daily.dart';
import 'screens/duel.dart';
import 'screens/govt_board.dart';
import 'screens/idcard.dart';
import 'screens/khata.dart';
import 'screens/news.dart';
import 'screens/play_features.dart';
import 'screens/share_features.dart';
import 'screens/voice.dart';
import 'screens/wrapped.dart';
import 'season.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  await ledger.load();
  await baj.load();
  await daily.load();
  await idStore.load();
  runApp(const ChadaBazarApp());
}

class ChadaBazarApp extends StatelessWidget {
  const ChadaBazarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'চাঁদা বাজার ২.০',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(Palette.light, Brightness.light),
      darkTheme: buildTheme(Palette.dark, Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

/// The two ways to play: 'data' pays chada, 'baj' collects it (fictional game).
bool get _isBaj => app.perspective == 'baj';

/// Tabs for the current perspective.
List<(String, String, bool)> get _tabs => _isBaj ? _bajTabs : _dataTabs;

const _bajTabs = <(String, String, bool)>[
  ('beat', 'পাড়ায় বের হও', false),
  ('daily', 'আজকের চাঁদা', true),
  ('office', 'ভাইয়ের দপ্তর', false),
  ('mic', 'পাড়ার মাইক', false),
  ('voice', 'ভাইয়ের ভয়েস', true),
  ('news', 'মৌসুম ও খবর', true),
  ('bhag', 'নেতার ভাগ', false),
  ('bboard', 'ভাইদের তালিকা', false),
];

const _dataTabs = <(String, String, bool)>[
  ('khata', 'আমার খাতা', true),
  ('rosid', 'নিজের রসিদ', false),
  ('notice', 'বন্ধুকে ফাঁসাও', true),
  ('quiz', 'ভিকটিম কুইজ', true),
  ('wrapped', 'চাঁদা Wrapped', true),
  ('idcard', 'পরিচয়পত্র', true),
  ('duel', 'ফোন পাস দরকষাকষি', true),
  ('news', 'মৌসুম ও খবর', true),
  ('call', 'ভাইয়ের কল', false),
  ('bhag', 'নেতার ভাগ', false),
  ('dor', 'দরকষাকষি', false),
  ('palao', 'পালাও', false),
  ('sarkar', 'সরকারি ঝামেলা', false),
  ('board', 'লিডারবোর্ড', false),
];

/// Icon, short label (bottom bar) and one-line hint (More sheet) per tab id.
const _navMeta = <String, (IconData, String, String)>{
  'daily': (Icons.today_rounded, 'আজকের', 'প্রতিদিন নতুন পাড়া, স্কোর শেয়ার করো'),
  'voice': (Icons.record_voice_over_rounded, 'ভয়েস', 'ভাইয়ের গলায় বন্ধুকে ভয় দেখাও'),
  'news': (Icons.newspaper_rounded, 'খবর', 'মৌসুম ও সাপ্তাহিক রিপোর্ট'),
  'wrapped': (Icons.auto_awesome_rounded, 'Wrapped', 'বছরের চাঁদার গল্প, স্টোরি স্লাইডে'),
  'idcard': (Icons.badge_rounded, 'পরিচয়পত্র', 'তোমার চাঁদাদাতা কার্ড'),
  'duel': (Icons.people_alt_rounded, 'দুজনে', 'দুজনে ফোন পাস করে দরকষাকষি'),
  'beat': (Icons.directions_bike_rounded, 'এলাকা', 'পাড়ায় গিয়ে চাঁদা তোলো'),
  'office': (Icons.storefront_rounded, 'দপ্তর', 'র‍্যাঙ্ক ও আপগ্রেড'),
  'mic': (Icons.mic_rounded, 'মাইক', 'পাড়ার মাইক ঘোষণা'),
  'bboard': (Icons.leaderboard_rounded, 'তালিকা', 'এলাকার ভাইদের তালিকা'),
  'khata': (Icons.menu_book_rounded, 'খাতা', 'চাঁদা ও ধারের আসল হিসাব'),
  'rosid': (Icons.receipt_long_rounded, 'রসিদ', 'নিজের নামে চাঁদার রসিদ'),
  'notice': (Icons.campaign_rounded, 'ফাঁসাও', 'বন্ধুকে নোটিশ পাঠাও'),
  'quiz': (Icons.psychology_alt_rounded, 'কুইজ', 'তুমি কোন টাইপের ভিকটিম?'),
  'call': (Icons.phone_in_talk_rounded, 'কল', 'ভাই কল করছে'),
  'bhag': (Icons.pie_chart_rounded, 'ভাগ', 'নেতার ১০% কাটলে কত বাকি'),
  'dor': (Icons.forum_rounded, 'দরকষাকষি', 'ভাইয়ের সাথে দাম করো'),
  'palao': (Icons.directions_run_rounded, 'পালাও', '"দেব না" বাটন ধরো'),
  'sarkar': (Icons.account_balance_rounded, 'সরকারি', 'ফাইল, লোডশেডিং, টেন্ডার'),
  'board': (Icons.emoji_events_rounded, 'র‍্যাঙ্ক', 'লিডারবোর্ড ও ব্যাজ'),
};

/// With more than 5 tabs, the first 4 sit in the bottom bar and the rest live
/// behind "আরও". With 5 or fewer, every tab gets its own bar slot.
bool get _hasMore => _tabs.length > 5;
int get _primaryCount => _hasMore ? 4 : _tabs.length;

const _bajTicker = [
  'ব্রেকিং: নেতা ঘোষণা দিয়েছেন, এবারও সবার থেকে ১০% ভাগ নেওয়া হবে',
  'গবেষণা: মাইক কিনলে চাঁদার অঙ্ক বাড়ে, গলাও বসে যায়',
  'সতর্কতা: ফেসবুক-লাইভ ভাতিজা আজ খুব সক্রিয়',
  'উকিল ফুপু আজ নোটবুক নিয়ে বের হয়েছেন',
];

const _ticker = [
  'ব্রেকিং: ভাই ঘোষণা দিয়েছেন, এখন থেকে অনলাইনেও চাঁদা নেওয়া হবে',
  'পেঁয়াজের দাম কমেছে, ভাইদর বেড়েছে ২০%',
  'গবেষণা: "পরে দিব" বলা মানুষদের ৯৯% পরে ডাবল দেয়',
  'নতুন সার্ভিস: চাঁদা দিলে ভাই আর একবার কম ফোন করবে (শর্ত প্রযোজ্য)',
  'বৃষ্টির কারণে আজ চাঁদা ১০% বেশি, ভাইয়ের ছাতা লাগবে',
  'এই অ্যাপ খোলার জন্য ৳১০ স্ক্রিন-টাইম চাঁদা কাটা হয়েছে',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _tab = 0;
  final _scroll = ScrollController();
  Timer? _idle;
  bool _awayFlag = false;
  bool _resetArmed = false;

  static const _idleLines = [
    'ভাই দেখছে তুমি কিছু করছ না। অলস ট্যাক্স ৳২০।',
    'এত চুপচাপ? চুপ থাকার চার্জ ৳২০।',
    'স্ক্রিন দেখে দেখে ভাবছো পালাবে? ৳২০ যোগ হলো।',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    app.onToast = toast;
    app.addListener(_onApp);
    _resetIdle();
  }

  /// Rebuilds the shell when the perspective changes.
  void _onApp() {
    if (!mounted) return;
    setState(() {
      if (_tab >= _tabs.length) _tab = 0;
    });
  }

  void _switchTo(String perspective) {
    if (app.perspective == perspective) return;
    _tab = 0;
    app.setPerspective(perspective);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _resetIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 45), () {
      // The idle and leave-the-app fines are for the payer; the collector has no one to fine him.
      if (!mounted || _isBaj || app.perspective == null) return _resetIdle();
      toast(pick(_idleLines));
      app.pay(20);
      _resetIdle();
    });
  }

  /// Leaving the app and coming back costs ৳৩০.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _awayFlag = true;
    } else if (s == AppLifecycleState.resumed && _awayFlag) {
      _awayFlag = false;
      if (_isBaj || app.perspective == null) return;
      toast('ফিরে এসেছ? অন্য অ্যাপে পালানোর জরিমানা ৳৩০।');
      app.pay(30);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    app.removeListener(_onApp);
    _idle?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _tab = i);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _openMore(Palette p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      backgroundColor: p.paper,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: p.ink, width: 2),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('আরও খেলা', style: body(20, w: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                for (var i = _primaryCount; i < _tabs.length; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.pop(ctx);
                      _select(i);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: i == _tab ? p.yellow : p.surface,
                        border: Border.all(color: p.ink, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Icon(_navMeta[_tabs[i].$1]!.$1, size: 30, color: i == _tab ? p.yellowInk : p.red),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tabs[i].$2, style: body(16, w: FontWeight.w700, color: i == _tab ? p.yellowInk : p.ink, h: 1.2)),
                          Text(_navMeta[_tabs[i].$1]!.$3, style: body(12.5, color: i == _tab ? p.yellowInk : p.muted, h: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ]),
                    ),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bottomNav(Palette p) {
    final inMore = _hasMore && _tab >= _primaryCount;
    final moreMeta = inMore ? _navMeta[_tabs[_tab].$1]! : (Icons.apps_rounded, 'আরও', '');
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.ink, width: 2))),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: p.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: p.yellow,
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStatePropertyAll(body(12.5, w: FontWeight.w600)),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(size: 26, color: s.contains(WidgetState.selected) ? p.yellowInk : p.ink),
          ),
        ),
        child: NavigationBar(
          selectedIndex: inMore ? _primaryCount : _tab,
          onDestinationSelected: (i) => _hasMore && i == _primaryCount ? _openMore(p) : _select(i),
          destinations: [
            for (var i = 0; i < _primaryCount; i++)
              NavigationDestination(
                icon: Badge(isLabelVisible: _tabs[i].$3, smallSize: 8, backgroundColor: p.red, child: Icon(_navMeta[_tabs[i].$1]!.$1)),
                label: _navMeta[_tabs[i].$1]!.$2,
                tooltip: _tabs[i].$2,
              ),
            if (_hasMore) NavigationDestination(icon: Icon(moreMeta.$1), label: moreMeta.$2, tooltip: 'আরও খেলা'),
          ],
        ),
      ),
    );
  }

  Widget _body() => switch (_tabs[_tab].$1) {
        'daily' => const DailyScreen(),
        'voice' => const VoiceScreen(),
        'news' => const NewsScreen(),
        'wrapped' => const WrappedScreen(),
        'idcard' => const IdCardScreen(),
        'duel' => const DuelScreen(),
        'beat' => const BeatScreen(),
        'office' => const OfficeScreen(),
        'mic' => const MicScreen(),
        'bboard' => const BajBoardScreen(),
        'khata' => const KhataScreen(),
        'rosid' => const ReceiptScreen(),
        'notice' => const NoticeScreen(),
        'quiz' => const QuizScreen(),
        'call' => const CallScreen(),
        'bhag' => BhagScreen(collector: _isBaj),
        'dor' => const HaggleScreen(),
        'palao' => const FleeScreen(),
        'sarkar' => const GovtScreen(),
        _ => const BoardScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (app.perspective == null) return _chooser(p);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Listener(
      onPointerDown: (_) => _resetIdle(),
      child: Scaffold(
        bottomNavigationBar: wide ? null : _bottomNav(p),
        body: CustomScrollView(controller: _scroll, slivers: [
          SliverToBoxAdapter(child: _masthead(p)),
          SliverToBoxAdapter(child: _tickerBar(p)),
          SliverToBoxAdapter(child: _seasonBanner(p)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 0), child: _stats(p)),
              ),
            ),
          ),
          if (wide) SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(p, _tab, _select, app.perspective ?? '')),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 22, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    child: KeyedSubtree(key: ValueKey(_tab), child: _body()),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _footer(p)),
        ]),
      ),
    );
  }

  Widget _masthead(Palette p) {
    final baj = _isBaj;
    final bg = baj ? p.green : p.red;
    final fg = baj ? p.greenInk : p.redInk;
    return Container(
      color: bg,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                Text('চাঁদা বাজার', style: display(60, color: fg).copyWith(shadows: const [Shadow(color: Color(0x40000000), offset: Offset(3, 3))])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: p.yellow, borderRadius: BorderRadius.circular(3)),
                  child: Text(baj ? 'ভাই মোড' : '২.০', style: body(18, w: FontWeight.w700, color: p.yellowInk)),
                ),
              ]),
              Text(baj ? 'পাড়া সামলাও। নেতাকে ১০% দিতে ভুলো না।' : 'ভাই আপনার পাশে আছে। পকেটের ভেতরে।', style: body(17, w: FontWeight.w600, color: fg)),
              const SizedBox(height: 12),
              _perspectiveSwitch(p),
            ]),
          ),
        ),
      ),
    );
  }

  /// Two pills in the header: switch between paying and collecting at any time.
  Widget _perspectiveSwitch(Palette p) {
    Widget pill(String id, String label, IconData icon) {
      final on = app.perspective == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchTo(id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: on ? p.yellow : Colors.black.withValues(alpha: .18),
              border: Border.all(color: on ? p.ink : Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: on ? p.yellowInk : Colors.white),
              const SizedBox(width: 6),
              Text(label, style: body(15, w: FontWeight.w700, color: on ? p.yellowInk : Colors.white, h: 1.2)),
            ]),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(children: [
        pill('data', 'আমি চাঁদাদাতা', Icons.account_balance_wallet_rounded),
        const SizedBox(width: 8),
        pill('baj', 'আমি ভাই', Icons.two_wheeler_rounded),
      ]),
    );
  }

  /// First launch: pick a side. It can be changed any time from the header.
  Widget _chooser(Palette p) {
    Widget card(String id, String emoji, String title, String desc, Color bg, Color fg) => GestureDetector(
          onTap: () => _switchTo(id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: p.ink, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: p.ink, offset: const Offset(5, 5))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 6),
              Text(title, style: body(24, w: FontWeight.w700, color: fg, h: 1.25)),
              const SizedBox(height: 4),
              Text(desc, style: body(15.5, color: fg, h: 1.4)),
            ]),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 22, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('চাঁদা বাজার', style: display(54, color: p.red), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('তুমি কে?', style: body(24, w: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('পরে হেডার থেকে যেকোনো সময় বদলাতে পারবে।', style: body(14, color: p.muted), textAlign: TextAlign.center),
                const SizedBox(height: 22),
                card('data', '😩', 'আমি চাঁদাদাতা', 'ভাইয়ের হাত থেকে বাঁচার চেষ্টা করো। রসিদ, দরকষাকষি, পালানো আর নিজের আসল হিসাবের খাতা।', p.surface, p.ink),
                const SizedBox(height: 18),
                card('baj', '🏍️', 'আমি ভাই', 'পাড়া সামলাও, মাইক আর বাইক কিনো। ওপরের নেতা কিন্তু ১০% নিয়ে যাবেন।', p.green, p.greenInk),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tickerBar(Palette p) {
    final season = currentSeason(DateTime.now());
    final lines = [...?season?.tickerLines, ...(_isBaj ? _bajTicker : _ticker)];
    return Container(
      color: p.ink,
      height: 34,
      child: ClipRect(child: _Marquee(text: lines.join('   ✦   '), style: body(15, w: FontWeight.w600, color: p.paper))),
    );
  }

  /// A strip under the ticker while a festival season is on. Tap to read more.
  Widget _seasonBanner(Palette p) {
    final s = currentSeason(DateTime.now());
    if (s == null) return const SizedBox.shrink();
    final newsIndex = _tabs.indexWhere((t) => t.$1 == 'news');
    return GestureDetector(
      onTap: newsIndex < 0 ? null : () => _select(newsIndex),
      child: Container(
        width: double.infinity,
        color: p.yellow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Row(children: [
              Text(s.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isBaj ? '${s.name} চলছে: চাঁদার অঙ্ক ${bnDigits(s.multiplier.toString())} গুণ' : '${s.name} চলছে: ${s.tagline}',
                  style: body(14.5, w: FontWeight.w700, color: p.yellowInk, h: 1.3),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stats(Palette p) => ListenableBuilder(
        listenable: Listenable.merge([app, baj]),
        builder: (_, _) {
          Widget s(String v, String l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: p.surface, border: Border.all(color: p.line, width: 1.5), borderRadius: BorderRadius.circular(6)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: body(22, w: FontWeight.w700, h: 1.2))),
                  Text(l, style: body(12.5, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              );
          return LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth < 600 ? 2 : 4;
            final w = (c.maxWidth - 10 * (cols - 1)) / cols;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final x in _isBaj
                  ? [
                      (tk(baj.cash), 'পকেটে টাকা'),
                      (baj.rankName, 'র‍্যাঙ্ক'),
                      ('${bnInt(baj.heat)}%', 'পুলিশের নজর'),
                      (tk(baj.taxPaid), 'নেতাকে দিয়েছ'),
                    ]
                  : [
                      (tk(app.paid), 'মোট জরিমানা'),
                      (app.levelName, 'ভিকটিম লেভেল'),
                      ('${bnInt(app.streak)} দিন', 'টানা চাঁদা স্ট্রিক'),
                      (app.mood, 'ভাইয়ের মুড'),
                    ])
                SizedBox(width: w, child: s(x.$1, x.$2)),
            ]);
          });
        },
      );

  Widget _footer(Palette p) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 28, 16, MediaQuery.of(context).padding.bottom + 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(color: p.line, thickness: 1.5),
              const SizedBox(height: 6),
              Text('সতর্কতা: এটা পুরোপুরি ব্যঙ্গ ও বিনোদন। সব চরিত্র ও জায়গা কাল্পনিক; কোনো ব্যক্তি, দল বা সরকারকে লক্ষ্য করে বানানো নয়। আসল চাঁদাবাজি অপরাধ। কেউ চাঁদা চাইলে ৯৯৯-এ জানাও।', style: body(13, color: p.muted)),
              const SizedBox(height: 6),
              Text('কোনো কনটেন্ট আপত্তিকর লাগলে জানাও, দ্রুত সরিয়ে দেওয়া হবে।', style: body(13, color: p.muted)),
              const SizedBox(height: 12),
              BhaiButton(_resetArmed ? 'নিশ্চিত? আবার চাপো' : 'আমার হিসাব মুছে ফেলো', kind: BtnKind.ghost, onTap: () {
                if (_resetArmed) {
                  app.reset();
                  if (_isBaj) baj.reset();
                  setState(() => _resetArmed = false);
                  toast('হিসাব মুছে গেছে। ভাই কিন্তু ভোলে না।');
                } else {
                  setState(() => _resetArmed = true);
                }
              }),
            ]),
          ),
        ),
      );
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final Palette p;
  final int selected;
  final ValueChanged<int> onSelect;
  final String perspective;
  _TabsDelegate(this.p, this.selected, this.onSelect, this.perspective);

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) => Container(
        decoration: BoxDecoration(color: p.paper, border: Border(bottom: BorderSide(color: p.ink, width: 2))),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: _tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final on = i == selected;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? p.ink : p.surface,
                  border: Border.all(color: p.ink, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(children: [
                  Text(_tabs[i].$2, style: body(14.5, w: FontWeight.w600, color: on ? p.paper : p.ink)),
                  if (_tabs[i].$3)
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: p.red, borderRadius: BorderRadius.circular(3)),
                      child: Text('নতুন', style: body(10, w: FontWeight.w700, color: p.redInk, h: 1.4)),
                    ),
                ]),
              ),
            );
          },
        ),
      );

  @override
  bool shouldRebuild(_TabsDelegate o) => o.selected != selected || o.p != p || o.perspective != perspective;
}

/// Right-to-left scrolling text strip.
class _Marquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _Marquee({required this.text, required this.style});
  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 70))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis)));
    }
    return LayoutBuilder(builder: (_, c) {
      final tp = TextPainter(text: TextSpan(text: widget.text, style: widget.style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
      final tw = tp.width + 40;
      return AnimatedBuilder(
        animation: _c,
        builder: (_, _) => OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Transform.translate(
            offset: Offset(c.maxWidth - (c.maxWidth + tw) * _c.value, 0),
            child: Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
          ),
        ),
      );
    });
  }
}
