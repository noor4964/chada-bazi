const _bn = '০১২৩৪৫৬৭৮৯';

const bnMonthNames = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

/// Converts ASCII digits in [s] to Bangla digits.
String bnDigits(String s) => s.replaceAllMapped(RegExp(r'\d'), (m) => _bn[int.parse(m[0]!)]);

/// Formats an integer with Indian digit grouping and Bangla digits.
String bnInt(int n) {
  final neg = n < 0;
  var s = n.abs().toString();
  if (s.length > 3) {
    final tail = s.substring(s.length - 3);
    var head = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) parts.insert(0, head);
    s = '${parts.join(',')},$tail';
  }
  return bnDigits('${neg ? '-' : ''}$s');
}

/// First number found in [s] (Bangla or ASCII digits), or null.
int? firstNumber(String s) {
  final ascii = s.replaceAllMapped(RegExp('[০-৯]'), (m) => _bn.indexOf(m[0]!).toString());
  final m = RegExp(r'\d+').firstMatch(ascii);
  return m == null ? null : int.tryParse(m[0]!);
}

const _blocked = [
  'মন্ত্রী', 'এমপি', 'নেতা', 'নেত্রী', 'লীগ', 'বিএনপি', 'আওয়ামী', 'জামায়াত',
  'জাতীয় পার্টি', 'সরকার', 'পুলিশ', 'ওসি', 'শেখ', 'জিয়া', 'প্রেসিডেন্ট',
  'চেয়ারম্যান', 'কাউন্সিলর', 'minister', 'leader', 'league', 'bnp', 'awami', 'police',
];

/// Returns (cleanName, null) or (null, errorMessage).
(String?, String?) cleanName(String raw) {
  final v = raw
      .replaceAll(RegExp(r'[0-9০-৯@#<>{}\[\]\\/]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (v.isEmpty) return (null, 'একটা ডাকনাম লেখো।');
  final low = v.toLowerCase();
  if (_blocked.any(low.contains)) {
    return (null, 'নেতা, দল বা পদবির নাম চলবে না। বন্ধুর ডাকনাম দাও।');
  }
  if (v.split(' ').length > 2) return (null, 'শুধু ডাকনাম দাও, পুরো নাম নয়।');
  return (v, null);
}
