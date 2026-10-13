import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Name, area and photo for the ID card. The photo stays on this device.
class IdCardStore extends ChangeNotifier {
  static const _key = 'idcard1';
  String name = '', area = '';
  Uint8List? photo;
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      final j = jsonDecode(_p!.getString(_key) ?? '{}') as Map<String, dynamic>;
      name = j['name'] ?? '';
      area = j['area'] ?? '';
      final b = j['photo'] as String?;
      photo = b == null ? null : base64Decode(b);
    } catch (_) {}
    notifyListeners();
  }

  void save({required String name, required String area, Uint8List? photo}) {
    this.name = name;
    this.area = area;
    this.photo = photo;
    _p?.setString(_key, jsonEncode({'name': this.name, 'area': this.area, 'photo': this.photo == null ? null : base64Encode(this.photo!)}));
    notifyListeners();
  }
}

final idStore = IdCardStore();

/// A stable four-digit number from the nickname, so the same person always gets the same card.
int memberNumber(String name) {
  var h = 7;
  for (final u in name.codeUnits) {
    h = (h * 31 + u) % 9000;
  }
  return 1000 + h;
}

/// Thin bars that look like a barcode, derived from [seed].
List<int> barcodeBars(int seed, {int count = 34}) {
  var x = seed % 2147483646 + 1;
  return [
    for (var i = 0; i < count; i++)
      () {
        x = (x * 48271) % 2147483647;
        return 1 + x % 3;
      }(),
  ];
}

/// The 360x450 card image. Always light so it looks the same wherever it is shared.
class IdCardView extends StatelessWidget {
  final String name, area, level;
  final Uint8List? photo;
  const IdCardView({super.key, required this.name, required this.area, required this.level, this.photo});

  @override
  Widget build(BuildContext context) {
    const p = Palette.light;
    final no = memberNumber(name);
    return SizedBox(
      width: 360,
      height: 450,
      child: Container(
        color: p.paper,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 78,
            color: p.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('চাঁদাদাতা পরিচয়পত্র', style: body(20, w: FontWeight.w700, color: Colors.white, h: 1.2)),
                  Text('চাঁদা বাজার · পাড়া কমিটি', style: body(12, color: Colors.white70, h: 1.2)),
                ]),
              ),
              Text('✦', style: display(34, color: p.yellow)),
            ]),
          ),
          Container(height: 8, color: p.yellow),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 112,
                  height: 140,
                  decoration: BoxDecoration(
                    color: p.yellow,
                    border: Border.all(color: p.ink, width: 3),
                    borderRadius: BorderRadius.circular(6),
                    image: photo == null ? null : DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover),
                  ),
                  alignment: Alignment.center,
                  child: photo == null ? const Text('😩', style: TextStyle(fontSize: 54)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name.isEmpty ? 'তোমার নাম' : name, style: body(25, w: FontWeight.w700, color: p.ink, h: 1.15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(area.isEmpty ? 'এলাকা' : area, style: body(15, color: p.muted, h: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    _field('সদস্য নং', bnDigits('$no')),
                    _field('লেভেল', level),
                    _field('মেয়াদ', 'ভাইয়ের মর্জি'),
                  ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Stack(clipBehavior: Clip.none, children: [
              SizedBox(
                height: 44,
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final b in barcodeBars(no)) ...[Container(width: b.toDouble(), color: p.ink), const SizedBox(width: 2)],
                ]),
              ),
              Positioned(
                right: 0,
                top: -62,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB3122B), width: 3), borderRadius: BorderRadius.circular(6)),
                    child: Text('অনুমোদিত', style: body(18, w: FontWeight.w700, color: const Color(0xFFB3122B))),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            height: 54,
            color: p.green,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('তোমারটা বানাও: চাঁদা বাজার ২.০', style: body(13.5, w: FontWeight.w700, color: p.greenInk, h: 1.2)),
              Text('ব্যঙ্গ ও বিনোদন। আসল চাঁদাবাজি অপরাধ।', style: body(9.5, color: p.greenInk, h: 1.2)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _field(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 62, child: Text(k, style: body(12.5, w: FontWeight.w600, color: Palette.light.muted, h: 1.3))),
          Expanded(child: Text(v, style: body(14, w: FontWeight.w700, color: Palette.light.ink, h: 1.3))),
        ]),
      );
}

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({super.key});
  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  final _name = TextEditingController(text: idStore.name);
  final _area = TextEditingController(text: idStore.area);
  final _key = GlobalKey();
  Uint8List? _photo = idStore.photo;
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 480, maxHeight: 600, imageQuality: 80);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() => _photo = bytes);
    } catch (_) {
      toast('ছবি আনা গেল না। গ্যালারি থেকে চেষ্টা করো।');
    }
  }

  bool _commit() {
    final (n, err) = cleanName(_name.text);
    setState(() => _err = err);
    if (n == null) return false;
    idStore.save(name: n, area: _area.text.trim(), photo: _photo);
    return true;
  }

  Future<void> _share() async {
    if (!_commit()) return;
    app.badge('idcard1');
    setState(() => _busy = true);
    try {
      await shareKeyAsPng(_key, '${idStore.name}-এর চাঁদাদাতা পরিচয়পত্র পেয়ে গেলাম 🪪😭 তুমি পেয়েছ?');
    } catch (_) {
      toast('ছবি শেয়ার হয়নি। লেখাটা কপি করে নিলাম।');
      await copyText('${idStore.name}-এর চাঁদাদাতা পরিচয়পত্র পেয়ে গেলাম 🪪😭');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = cleanName(_name.text).$1 ?? '';
    return BhaiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('চাঁদাদাতা পরিচয়পত্র', tag: 'প্রোফাইল ছবি বানাও', lede: 'নাম, এলাকা আর একটা ছবি দাও। কার্ডটা বন্ধুদের দেখাও বা প্রোফাইলে দাও। ছবি শুধু তোমার ফোনে থাকে।'),
        TextField(controller: _name, maxLength: 20, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'তোমার ডাকনাম', counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: _area, maxLength: 24, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'এলাকা / পাড়া', counterText: '')),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: body(14, w: FontWeight.w600, color: p.red))),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          BhaiButton('গ্যালারি থেকে ছবি', kind: BtnKind.ghost, onTap: () => _pick(ImageSource.gallery)),
          BhaiButton('সেলফি তোলো', kind: BtnKind.ghost, onTap: () => _pick(ImageSource.camera)),
          if (_photo != null) BhaiButton('ছবি সরাও', kind: BtnKind.ghost, onTap: () => setState(() => _photo = null)),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth.clamp(200.0, 360.0);
          return Center(
            child: SizedBox(
              width: w,
              height: w * 450 / 360,
              child: FittedBox(
                child: RepaintBoundary(key: _key, child: IdCardView(name: n, area: _area.text.trim(), level: app.levelName, photo: _photo)),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          BhaiButton('সেভ করো', kind: BtnKind.green, onTap: () {
            if (_commit()) toast('কার্ড সেভ হয়েছে।');
          }),
          BhaiButton(_busy ? 'অপেক্ষা…' : 'ছবি শেয়ার করো', kind: BtnKind.red, onTap: _busy ? null : _share),
        ]),
      ]),
    );
  }
}
