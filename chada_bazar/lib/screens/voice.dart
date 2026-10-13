import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../voice_script.dart';
import '../widgets.dart';

/// The phone reads a prank message in a gruff ভাই voice.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final _tts = FlutterTts();
  final _name = TextEditingController(text: 'সাকিব');
  int _sit = 0, _profile = 0;
  bool _speaking = false;
  bool? _bnAvailable;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _tts.setLanguage('bn-BD');
      final ok = await _tts.isLanguageAvailable('bn-BD');
      if (mounted) setState(() => _bnAvailable = ok == true || ok == 1);
    } catch (_) {
      // Some browsers do not answer this question; stay quiet and let play decide.
    }
    void done() {
      if (mounted) setState(() => _speaking = false);
    }

    _tts.setCompletionHandler(done);
    _tts.setCancelHandler(done);
    _tts.setErrorHandler((_) => done());
  }

  @override
  void dispose() {
    _tts.stop();
    _name.dispose();
    super.dispose();
  }

  String? _cleanedName() {
    final (n, err) = cleanName(_name.text);
    setState(() => _err = err);
    return n;
  }

  Future<void> _play() async {
    final n = _cleanedName();
    if (n == null) return;
    final prof = voiceProfiles[_profile];
    try {
      await _tts.setLanguage('bn-BD');
      await _tts.setPitch(prof.pitch);
      await _tts.setSpeechRate(prof.rate);
      setState(() => _speaking = true);
      await _tts.speak(buildVoiceScript(n, _sit));
      app.badge('voice1');
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
      toast('এই ডিভাইসে ভয়েস বাজল না। লেখাটা শেয়ার করতে পারো।');
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = cleanName(_name.text).$1 ?? 'বন্ধু';
    final script = buildVoiceScript(n, _sit);
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('ভাইয়ের ভয়েস মেসেজ',
            tag: 'বন্ধুকে ভয় দেখাও',
            lede: 'বন্ধুর ডাকনাম দাও, ফোন গম্ভীর গলায় পড়ে শোনাবে। ফোনটা বন্ধুর কানের কাছে ধরো আর রিঅ্যাকশন দেখো।'),
        TextField(
          controller: _name,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'বন্ধুর ডাকনাম', counterText: ''),
        ),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
        const SizedBox(height: 12),
        Text('কী নিয়ে হুমকি', style: body(13.5, color: p.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < voiceSituations.length; i++)
            ChoiceChip(
              label: Text(voiceSituations[i].$1, style: body(14, color: _sit == i ? p.yellowInk : p.ink)),
              selected: _sit == i,
              selectedColor: p.yellow,
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5),
              showCheckmark: false,
              onSelected: (_) => setState(() => _sit = i),
            ),
        ]),
        const SizedBox(height: 12),
        Text('কার গলা', style: body(13.5, color: p.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < voiceProfiles.length; i++)
            ChoiceChip(
              label: Text(voiceProfiles[i].name, style: body(14, color: _profile == i ? p.yellowInk : p.ink)),
              selected: _profile == i,
              selectedColor: p.yellow,
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5),
              showCheckmark: false,
              onSelected: (_) => setState(() => _profile = i),
            ),
        ]),
        const SizedBox(height: 14),
        OutBox(accent: p.red, child: Text('“$script”', style: body(16, h: 1.55))),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          BhaiButton(_speaking ? 'থামাও' : '🔊 বাজাও', kind: BtnKind.red, onTap: _speaking ? _stop : _play),
        ]),
        if (_bnAvailable == false)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('এই ফোনে বাংলা ভয়েস পাওয়া যায়নি। সেটিংসের টেক্সট-টু-স্পিচ থেকে বাংলা ভাষা ইনস্টল করলে গলা শোনা যাবে। ততক্ষণ লেখাটা শেয়ার করো।', style: body(13.5, w: FontWeight.w600, color: p.red)),
          ),
        ShareBar(
          text: '📢 ভাইয়ের ভয়েস মেসেজ: $script',
          card: ShareCardData(kicker: 'ভাইয়ের ভয়েস', title: '$n-কে ভাইয়ের মেসেজ', rows: const [], big: '“$script”', stamp: 'জরুরি'),
        ),
      ]),
    );
  }
}
