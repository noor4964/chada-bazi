import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The leader above you always takes this share of what you collect.
const leaderTaxPercent = 10;

/// A cartoon neighbour you can ask for chada. Purely fictional archetypes.
class Target {
  final String id, name, emoji, blurb;
  final int minAmt, maxAmt;

  /// Chances of paying in full, haggling (half), or hiding. The rest
  /// complains, which raises the police-attention meter by [complainHeat].
  final double pay, haggle, flee;
  final int complainHeat;
  final List<String> payLines, haggleLines, fleeLines;
  final String complainLine;

  const Target({
    required this.id,
    required this.name,
    required this.emoji,
    required this.blurb,
    required this.minAmt,
    required this.maxAmt,
    required this.pay,
    required this.haggle,
    required this.flee,
    required this.complainHeat,
    required this.payLines,
    required this.haggleLines,
    required this.fleeLines,
    required this.complainLine,
  });
}

const targets = <Target>[
  Target(
    id: 'mama', name: 'জিজ্ঞেস না করা মামা', emoji: '👴', blurb: 'কিছু না জিজ্ঞেস করেই দিয়ে দেয়। সন্দেহজনক রকম ভালো মানুষ।',
    minAmt: 50, maxAmt: 200, pay: .8, haggle: .1, flee: .02, complainHeat: 6,
    payLines: ['মামা পকেট থেকে বের করে দিলেন, কারণও জিজ্ঞেস করলেন না।', 'মামা বললেন, "নাও বাবা, চা খেও।"'],
    haggleLines: ['মামা অর্ধেক দিয়ে বললেন, বাকিটা পেনশন এলে।'],
    fleeLines: ['মামা ঘুমিয়ে পড়েছেন। সত্যিই।'],
    complainLine: 'মামা হঠাৎ জিজ্ঞেস করলেন, "কিসের চাঁদা?" তোমার উত্তর হোঁচট খেল।',
  ),
  Target(
    id: 'cha', name: 'মোড়ের চায়ের দোকানদার', emoji: '☕', blurb: 'রোজ দেখা হয়। হাসিমুখে দেয়, তবে হিসাব রাখে।',
    minAmt: 100, maxAmt: 300, pay: .55, haggle: .25, flee: .05, complainHeat: 12,
    payLines: ['দোকানদার ক্যাশ বাক্স থেকে দিলেন আর বললেন, "চা ফ্রি, চাঁদা না।"', 'দোকানদার দিয়ে দিলেন, সাথে একটা বিস্কুট ধরিয়ে দিলেন।'],
    haggleLines: ['দোকানদার বললেন, "আজ বিক্রি কম, অর্ধেক রাখো।"'],
    fleeLines: ['দোকানদার হঠাৎ কেটলি আনতে ভেতরে ঢুকে গেলেন।'],
    complainLine: 'দোকানদার বললেন, "খাতায় লিখে রাখলাম।" ভাইয়ের গা শিরশির করল।',
  ),
  Target(
    id: 'hisabi', name: 'হিসাবি চাচা', emoji: '🧮', blurb: 'প্রতিটা টাকার রসিদ চায়। রসিদ বই ছাড়া ঝুঁকি আছে।',
    minAmt: 200, maxAmt: 500, pay: .25, haggle: .45, flee: .05, complainHeat: 15,
    payLines: ['চাচা তিনবার গুনে দিলেন, তারপর রসিদের ছবি তুলে রাখলেন।'],
    haggleLines: ['চাচা বললেন, "আগে হিসাব দাও।" শেষে অর্ধেকে রাজি হলেন।', 'চাচা ক্যালকুলেটর বের করে ৫০% ছাড় আদায় করলেন।'],
    fleeLines: ['চাচা "ব্যাংকে যেতে হবে" বলে হাঁটা দিলেন।'],
    complainLine: 'চাচা খাতা বের করে লিখলেন: তারিখ, সময়, ভাইয়ের চেহারা।',
  ),
  Target(
    id: 'flat', name: 'নতুন ফ্ল্যাটের ভাড়াটিয়া', emoji: '🏢', blurb: 'এই পাড়ায় নতুন। নিয়ম জানে না, তবে শিখছে।',
    minAmt: 300, maxAmt: 800, pay: .4, haggle: .2, flee: .2, complainHeat: 20,
    payLines: ['ভাড়াটিয়া "পাড়ার নিয়ম" ভেবে দিয়ে দিলেন।', 'ভাড়াটিয়া ফোন নম্বর চাইলেন, ভাই ভান করলেন শুনতে পাননি।'],
    haggleLines: ['ভাড়াটিয়া বললেন, "মাসের শেষে", তবে অর্ধেক এখনই দিলেন।'],
    fleeLines: ['ভাড়াটিয়া ইন্টারকমে "বাসায় কেউ নেই" বলে দিলেন।'],
    complainLine: 'ভাড়াটিয়া বাড়িওয়ালাকে ফোন করলেন। ভাই পিছিয়ে এলেন।',
  ),
  Target(
    id: 'live', name: 'ফেসবুক-লাইভ ভাতিজা', emoji: '📱', blurb: 'সবকিছু লাইভ করে। টাকা দেয় কম, তবে ঝুঁকি বেশি।',
    minAmt: 100, maxAmt: 400, pay: .2, haggle: .15, flee: .05, complainHeat: 30,
    payLines: ['ভাতিজা ক্যামেরা বন্ধ করে চুপচাপ দিয়ে দিল।'],
    haggleLines: ['ভাতিজা বলল, "অর্ধেক নাও, নইলে লাইভ।"'],
    fleeLines: ['ভাতিজা সেলফি স্টিক নিয়ে দৌড় দিল।'],
    complainLine: 'ভাতিজা লাইভ শুরু করল: "বন্ধুরা, দেখুন আমার সামনে কে!" দর্শক ৩৭০ জন।',
  ),
  Target(
    id: 'lawyer', name: 'উকিল ফুপু', emoji: '⚖️', blurb: 'আইনের ধারা মুখস্থ। ঝুঁকি অনেক বেশি, তবে দিলে অনেক দেয়।',
    minAmt: 500, maxAmt: 1500, pay: .1, haggle: .1, flee: .0, complainHeat: 35,
    payLines: ['ফুপু রসিদ লিখিয়ে নিয়ে তারপর দিলেন। সাথে একটা লেকচার।'],
    haggleLines: ['ফুপু ধারা শোনালেন, ভাই ভয় পেয়ে অর্ধেকে রাজি হলেন।'],
    fleeLines: ['ফুপু সরে গেলেন।'],
    complainLine: 'ফুপু বললেন, "আমি কিন্তু সব নোট করছি।" ভাইয়ের হাঁটু কাঁপল।',
  ),
];

enum UpgradeId { mic, bike, nephew, receipt }

class UpgradeDef {
  final UpgradeId id;
  final String name, emoji, effect;
  final int baseCost, maxLevel;
  const UpgradeDef(this.id, this.name, this.emoji, this.effect, this.baseCost, this.maxLevel);
}

const upgradeDefs = <UpgradeDef>[
  UpgradeDef(UpgradeId.mic, 'মাইক', '🎤', 'প্রতি লেভেলে চাঁদার অঙ্ক +২০%', 400, 5),
  UpgradeDef(UpgradeId.bike, 'বাইক', '🏍️', 'প্রতি লেভেলে লুকিয়ে থাকা মানুষ ২৫% কম', 600, 3),
  UpgradeDef(UpgradeId.nephew, 'ভাতিজা (সামলানোর লোক)', '🧑‍🤝‍🧑', 'প্রতি লেভেলে পুলিশের নজর ১৫% কম বাড়ে', 800, 4),
  UpgradeDef(UpgradeId.receipt, 'ভুয়া রসিদ বই', '📒', 'প্রতি লেভেলে দেওয়ার সম্ভাবনা +৪%', 500, 5),
];

int upgradeCost(UpgradeDef d, int level) => ((d.baseCost * pow(1.8, level)) / 10).round() * 10;

const ranks = <(int, String)>[
  (0, 'পাড়ার নতুন ভাই'),
  (2000, 'মোড়ের ভাই'),
  (10000, 'এলাকার ভাই'),
  (40000, 'ওস্তাদ ভাই'),
  (100000, 'বড় ভাই'),
];

enum Kind { paid, haggled, fled, complained }

class CollectResult {
  final Target target;
  final Kind kind;
  final String line;
  final int gross, tax, net, heatDelta, fine;
  final bool caught;
  const CollectResult({
    required this.target,
    required this.kind,
    required this.line,
    required this.gross,
    required this.tax,
    required this.net,
    required this.heatDelta,
    this.fine = 0,
    this.caught = false,
  });
}

/// What happened in one attempt, before tax and before it touches any state.
class Roll {
  final Kind kind;
  final String line;
  final int gross, heatDelta;
  const Roll(this.kind, this.line, this.gross, this.heatDelta);
}

/// Pure outcome of asking [t] once. Upgrade levels default to zero, which is
/// what the daily run uses so everyone plays on equal terms.
Roll rollOutcome(Target t, Random rng, {int mic = 0, int bike = 0, int nephew = 0, int receipt = 0, double amountMult = 1}) {
  var pFlee = t.flee * (1 - 0.25 * bike);
  var pPay = min(0.9, t.pay + 0.04 * receipt);
  var pHaggle = t.haggle + (t.flee - pFlee);
  var pComplain = max(0.02, 1 - pPay - pHaggle - pFlee);
  final sum = pPay + pHaggle + pFlee + pComplain;
  pPay /= sum;
  pHaggle /= sum;
  pFlee /= sum;
  pComplain /= sum;

  final base = t.minAmt + rng.nextInt(t.maxAmt - t.minAmt + 1);
  final amount = ((base * (1 + 0.2 * mic) * amountMult) / 10).round() * 10;
  int cool(int h) => (h * (1 - 0.15 * nephew)).round();

  final r = rng.nextDouble();
  if (r < pPay) {
    return Roll(Kind.paid, t.payLines[rng.nextInt(t.payLines.length)], amount, cool(2));
  } else if (r < pPay + pHaggle) {
    return Roll(Kind.haggled, t.haggleLines[rng.nextInt(t.haggleLines.length)], (amount / 2 / 10).round() * 10, cool(3));
  } else if (r < pPay + pHaggle + pFlee) {
    return Roll(Kind.fled, t.fleeLines[rng.nextInt(t.fleeLines.length)], 0, 1);
  }
  return Roll(Kind.complained, t.complainLine, 0, cool(t.complainHeat));
}

class BajState extends ChangeNotifier {
  static const _key = 'baj1';
  int cash = 300, heat = 0, collected = 0, taxPaid = 0, caught = 0, tries = 0;
  final Map<String, int> upgrades = {};
  final List<CollectResult> log = [];
  SharedPreferences? _p;

  int level(UpgradeId id) => upgrades[id.name] ?? 0;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      final j = jsonDecode(_p!.getString(_key) ?? '{}') as Map<String, dynamic>;
      cash = j['cash'] ?? 300;
      heat = j['heat'] ?? 0;
      collected = j['collected'] ?? 0;
      taxPaid = j['taxPaid'] ?? 0;
      caught = j['caught'] ?? 0;
      tries = j['tries'] ?? 0;
      upgrades
        ..clear()
        ..addAll(Map<String, int>.from(j['upgrades'] ?? const {}));
    } catch (_) {}
    notifyListeners();
  }

  void _changed() {
    _p?.setString(_key, jsonEncode({'cash': cash, 'heat': heat, 'collected': collected, 'taxPaid': taxPaid, 'caught': caught, 'tries': tries, 'upgrades': upgrades}));
    notifyListeners();
  }

  int get rankIndex {
    var r = 0;
    for (var i = 0; i < ranks.length; i++) {
      if (collected >= ranks[i].$1) r = i;
    }
    return r;
  }

  String get rankName => ranks[rankIndex].$2;

  /// One attempt to collect from [t]. [rng] is injectable so tests can fix outcomes.
  /// [seasonMult] scales the amount during a festival season.
  CollectResult collect(Target t, Random rng, {double seasonMult = 1}) {
    tries++;
    final roll = rollOutcome(
      t,
      rng,
      mic: level(UpgradeId.mic),
      bike: level(UpgradeId.bike),
      nephew: level(UpgradeId.nephew),
      receipt: level(UpgradeId.receipt),
      amountMult: seasonMult,
    );
    final kind = roll.kind, gross = roll.gross, heatDelta = roll.heatDelta, line = roll.line;

    final tax = (gross * leaderTaxPercent / 100).round();
    final net = gross - tax;
    cash += net;
    taxPaid += tax;
    collected += gross;
    heat = (heat + heatDelta).clamp(0, 100);

    var fine = 0;
    var wasCaught = false;
    if (heat >= 100) {
      wasCaught = true;
      caught++;
      fine = cash ~/ 2;
      cash -= fine;
      heat = 30;
    }

    final res = CollectResult(
      target: t, kind: kind, line: line, gross: gross, tax: tax, net: net, heatDelta: heatDelta, fine: fine, caught: wasCaught,
    );
    log.insert(0, res);
    if (log.length > 8) log.removeLast();
    _changed();
    return res;
  }

  static const coolCost = 100;
  static const coolAmount = 25;

  bool get canCool => cash >= coolCost && heat > 0;

  /// Hang out at the tea stall until things calm down.
  bool coolDown() {
    if (!canCool) return false;
    cash -= coolCost;
    heat = max(0, heat - coolAmount);
    _changed();
    return true;
  }

  bool canBuy(UpgradeDef d) => level(d.id) < d.maxLevel && cash >= upgradeCost(d, level(d.id));

  bool buy(UpgradeDef d) {
    if (!canBuy(d)) return false;
    cash -= upgradeCost(d, level(d.id));
    upgrades[d.id.name] = level(d.id) + 1;
    _changed();
    return true;
  }

  void reset() {
    cash = 300;
    heat = collected = taxPaid = caught = tries = 0;
    upgrades.clear();
    log.clear();
    _changed();
  }
}

final baj = BajState();
