import 'util.dart';

/// Pass-the-phone haggle: one person plays the ভাই, the other haggles.
/// Pure rules, no UI.
enum DuelStatus { payerTurn, bhaiTurn, dealt, angry }

class DuelMessage {
  final bool fromBhai;
  final String text;
  const DuelMessage(this.fromBhai, this.text);
}

const duelMaxRounds = 3;

class DuelGame {
  final String bhai, payer;
  final int startDemand;
  int demand;
  int round = 1;
  int lastOffer = 0;
  int? finalAmount;
  DuelStatus status = DuelStatus.payerTurn;
  final List<DuelMessage> log = [];

  DuelGame({required this.bhai, required this.payer, required this.startDemand}) : demand = startDemand {
    log.add(DuelMessage(true, 'চাঁদা ${_t(startDemand)}। দর কষা চলবে, তবে আমার দিকে।'));
  }

  static String _t(int n) => '৳${bnInt(n)}';

  /// The payer offers [x]. An offer at or above the demand is an instant deal.
  void payerOffer(int x) {
    if (status != DuelStatus.payerTurn) throw StateError('not the payer\'s turn');
    if (x < 0) x = 0;
    log.add(DuelMessage(false, '${_t(x)} দিই?'));
    if (x >= demand) {
      _deal(demand);
      return;
    }
    lastOffer = x;
    status = DuelStatus.bhaiTurn;
  }

  /// The bhai takes the last offer.
  void bhaiAccept() {
    if (status != DuelStatus.bhaiTurn) throw StateError('not the bhai\'s turn');
    log.add(DuelMessage(true, 'ঠিক আছে, ${_t(lastOffer)}। এবার যাও।'));
    _deal(lastOffer);
  }

  /// The bhai names a new demand between the last offer and the old demand.
  /// After the last round there is no counter: he must accept or get angry.
  void bhaiCounter(int newDemand) {
    if (status != DuelStatus.bhaiTurn) throw StateError('not the bhai\'s turn');
    if (round >= duelMaxRounds) throw StateError('last round: accept or get angry');
    if (newDemand <= lastOffer || newDemand >= demand) {
      throw ArgumentError('counter must be above the offer and below the demand');
    }
    log.add(DuelMessage(true, 'না, ${_t(newDemand)} দাও।'));
    demand = newDemand;
    round++;
    status = DuelStatus.payerTurn;
  }

  /// The bhai loses patience: the amount goes up by 20%, rounded to ৳10.
  void bhaiAngry() {
    if (status != DuelStatus.bhaiTurn) throw StateError('not the bhai\'s turn');
    final amount = (demand * 1.2 / 10).round() * 10;
    log.add(DuelMessage(true, 'অনেক হয়েছে! এখন ${_t(amount)}, রাগের চার্জসহ।'));
    finalAmount = amount;
    status = DuelStatus.angry;
  }

  void _deal(int amount) {
    finalAmount = amount;
    status = DuelStatus.dealt;
  }

  bool get finished => status == DuelStatus.dealt || status == DuelStatus.angry;

  /// Can the bhai still name a new demand?
  bool get canCounter => status == DuelStatus.bhaiTurn && round < duelMaxRounds && demand - lastOffer > 10;

  /// Final amount as a share of the opening demand.
  double get ratio => (finalAmount ?? demand) / startDemand;

  /// 'payer', 'bhai' or 'draw'.
  String get winner {
    if (!finished) return '';
    if (ratio <= 0.5) return 'payer';
    if (ratio >= 0.9) return 'bhai';
    return 'draw';
  }

  String get winnerName => switch (winner) {
        'payer' => payer,
        'bhai' => bhai,
        _ => '',
      };

  String get verdict => switch (winner) {
        'payer' => '$payer জিতেছে। দরকষাকষি চ্যাম্পিয়ন!',
        'bhai' => '$bhai জিতেছে। ভাইয়ের হাত থেকে কেউ বাঁচে না।',
        _ => 'ড্র। দুজনেই একটু একটু হেরেছে।',
      };
}
