import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card.dart';
import 'theme.dart';

export 'share_card.dart';

/// Replace with the public web URL once deployed.
const appLink = 'https://github.com/noor4964/chada-bazi';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

void toast(String msg) {
  final m = messengerKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, style: body(15, w: FontWeight.w600)),
    duration: const Duration(milliseconds: 3600),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
  ));
}

/// Hard-shadow "street sign" card.
class BhaiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const BhaiCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.ink, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: p.ink, offset: const Offset(5, 5))],
      ),
      child: child,
    );
  }
}

class CardTitle extends StatelessWidget {
  final String title;
  final String? tag;
  final String? lede;
  const CardTitle(this.title, {super.key, this.tag, this.lede});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(title, style: body(22, w: FontWeight.w700, h: 1.25)),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(color: p.yellow, borderRadius: BorderRadius.circular(3)),
            child: Text(tag!, style: body(12, w: FontWeight.w700, color: p.yellowInk)),
          ),
      ]),
      if (lede != null) ...[
        const SizedBox(height: 4),
        Text(lede!, style: body(15, color: p.muted)),
      ],
      const SizedBox(height: 14),
    ]);
  }
}

enum BtnKind { yellow, red, green, ghost }

class BhaiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  const BhaiButton(this.label, {super.key, required this.onTap, this.kind = BtnKind.yellow});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (bg, fg) = switch (kind) {
      BtnKind.yellow => (p.yellow, p.yellowInk),
      BtnKind.red => (p.red, p.redInk),
      BtnKind.green => (p.green, p.greenInk),
      BtnKind.ghost => (p.surface, p.ink),
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: p.ink, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: p.ink, offset: const Offset(3, 3))],
          ),
          child: Text(label, style: body(16, w: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}

class OutBox extends StatelessWidget {
  final Widget child;
  final Color? accent;
  const OutBox({super.key, required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: p.paper,
        border: Border(left: BorderSide(color: accent ?? p.green, width: 4)),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------- share ---

/// Text + image share buttons shown under a result.
class ShareBar extends StatelessWidget {
  final String text;
  final ShareCardData? card;
  const ShareBar({super.key, required this.text, this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(spacing: 10, runSpacing: 10, children: [
        if (card != null)
          BhaiButton('ছবি কার্ড বানাও', kind: BtnKind.red, onTap: () => showShareCard(context, card!, text)),
        BhaiButton('কপি', kind: BtnKind.ghost, onTap: () => copyText(text)),
        BhaiButton('শেয়ার', kind: BtnKind.green, onTap: () => shareText(text)),
      ]),
    );
  }
}

Future<void> copyText(String text) async {
  await Clipboard.setData(ClipboardData(text: '$text\n$appLink'));
  toast('কপি হয়েছে। এবার বন্ধুদের গ্রুপে ছাড়ো।');
}

Future<void> shareText(String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: '$text\n$appLink'));
  } catch (_) {
    await copyText(text);
  }
}

/// Renders the [RepaintBoundary] behind [key] to PNG bytes. [pixelRatio] 3
/// turns a 360-wide widget into a 1080-wide image.
Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 3}) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final img = await boundary.toImage(pixelRatio: pixelRatio);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes?.buffer.asUint8List();
}

/// Captures the widget behind [key] and opens the system share sheet with it.
/// Throws if the image could not be made or shared.
Future<void> shareKeyAsPng(GlobalKey key, String text, {double pixelRatio = 3}) async {
  final png = await capturePng(key, pixelRatio: pixelRatio);
  if (png == null) throw StateError('no image');
  await SharePlus.instance.share(ShareParams(
    text: '$text\n$appLink',
    files: [XFile.fromData(png, mimeType: 'image/png', name: 'chada-bazar.png')],
  ));
}

void showShareCard(BuildContext context, ShareCardData data, String text) {
  showDialog<void>(
    context: context,
    builder: (_) => _ShareCardDialog(data: data, text: text),
  );
}

class _ShareCardDialog extends StatefulWidget {
  final ShareCardData data;
  final String text;
  const _ShareCardDialog({required this.data, required this.text});

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  // Remembered for the session so the next card opens in the last chosen look.
  static CardStyle _lastStyle = CardStyle.sticker;
  static bool _lastStory = false;

  final _key = GlobalKey();
  bool _busy = false;
  CardStyle _style = _lastStyle;
  bool _story = _lastStory;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await shareKeyAsPng(_key, widget.text); // 360x450 -> 1080x1350, or 360x640 -> 1080x1920
    } catch (_) {
      toast('ছবি শেয়ার হয়নি। লেখাটা কপি করে নিলাম।');
      await copyText(widget.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            for (final s in CardStyle.values)
              ChoiceChip(
                label: Text(s.label, style: body(14, w: FontWeight.w700, color: _style == s ? p.yellowInk : p.ink)),
                selected: _style == s,
                selectedColor: p.yellow,
                backgroundColor: p.surface,
                side: BorderSide(color: p.ink, width: 1.5),
                showCheckmark: false,
                onSelected: (_) => setState(() => _style = _lastStyle = s),
              ),
            ChoiceChip(
              label: Text(_story ? '৯:১৬ স্টোরি' : '৪:৫ পোস্ট', style: body(14, w: FontWeight.w700, color: p.ink)),
              selected: false,
              backgroundColor: p.surface,
              side: BorderSide(color: p.ink, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
              avatar: Icon(Icons.swap_vert_rounded, size: 18, color: p.ink),
              onSelected: (_) => setState(() => _story = _lastStory = !_story),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 64).clamp(200.0, 360.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(key: _key, child: ShareCardView(data: widget.data, style: _style, story: _story)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            BhaiButton(_busy ? 'অপেক্ষা…' : 'ছবি শেয়ার করো', kind: BtnKind.red, onTap: _busy ? null : _share),
            BhaiButton('লেখা কপি', kind: BtnKind.ghost, onTap: () => copyText(widget.text)),
            BhaiButton('বন্ধ করো', kind: BtnKind.ghost, onTap: () => Navigator.pop(context)),
          ]),
        ]),
      ),
    );
  }
}
