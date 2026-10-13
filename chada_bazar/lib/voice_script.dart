/// One prank line per situation. {n} is replaced by the friend's nickname.
const voiceSituations = <(String, String)>[
  ('ট্রিট বাকি', '{n}, শুনছো? আমি পাড়ার ভাই বলছি। তোমার ট্রিট তিন বছর ধরে বাকি। আজকের মধ্যে না দিলে মাইকে তোমার নাম বলব।'),
  ('ফোন ধরো না', '{n}, ফোন ধরছো না কেন? আমি জানি তুমি অনলাইনে আছো। সবুজ বাতি জ্বলছে।'),
  ('ধার ফেরত', '{n}, ধার নিয়ে ভুলে গেছো? ভাইয়ের মনে সব থাকে। এক সপ্তাহ সময় দিলাম।'),
  ('জন্মদিনের কেক', '{n}, শুনলাম জন্মদিনে কেক একা খেয়েছো। ভাইয়ের ভাগ কই?'),
  ('গ্রুপে seen', '{n}, গ্রুপে মেসেজ দেখে রিপ্লাই দাও না। এই অপরাধের জরিমানা পাঁচশো টাকা।'),
  ('দেরিতে আসা', '{n}, পাঁচ মিনিটে আসছি বলে দুই ঘণ্টা! ভাই কিন্তু ঘড়ি দেখে।'),
];

/// How the line is spoken.
class VoiceProfile {
  final String name;
  final double pitch, rate;
  const VoiceProfile(this.name, this.pitch, this.rate);
}

const voiceProfiles = <VoiceProfile>[
  VoiceProfile('গম্ভীর ভাই', 0.6, 0.42),
  VoiceProfile('রাগী মাইক', 0.8, 0.6),
  VoiceProfile('মিষ্টি হুমকি', 1.2, 0.5),
];

String buildVoiceScript(String name, int situation) {
  final i = situation.clamp(0, voiceSituations.length - 1);
  return voiceSituations[i].$2.replaceAll('{n}', name);
}
