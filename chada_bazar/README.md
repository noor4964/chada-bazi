# চাঁদা বাজার ২.০ (Flutter)

One Flutter codebase for the Android app and the website. Satire only; every character and place is fictional.

## Run

```bash
flutter pub get
flutter run -d chrome        # web
flutter run                  # connected Android device or emulator
```

## Build

```bash
flutter build web --release  # output: build/web (static files, host anywhere)
flutter build apk --release  # output: build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle      # for the Play Store
```

Android needs the SDK licences accepted once: `flutter doctor --android-licenses`.

## Before going public

- Set `appLink` in `lib/widgets.dart` to the deployed web URL. It is added to every shared text.
- Replace the placeholder Android signing (the release build currently uses the debug key) before uploading to the Play Store.
- Add a real `og:image` and `og:url` to `web/index.html` so links preview well on Facebook and WhatsApp.

## Logo and splash

The logo is a yellow taka coin on red. To change it:

```bash
flutter test tool/gen_icon_test.dart        # redraws assets/icon/*.png (Windows, uses the Nirmala font)
dart run flutter_launcher_icons             # Android launcher and web icons
dart run flutter_native_splash:create       # Android and web splash screens
```

You can also replace `assets/icon/icon.png` (1024x1024, full bleed) and `assets/icon/icon_foreground.png` (transparent, keep the artwork inside the centre 66%) with your own art and run the last two commands.

## Two perspectives

On first launch the app asks who you are. The choice can be changed any time from the two pills in the header.

| | চাঁদাদাতা (payer) | ভাই (collector, a game) |
|---|---|---|
| Tabs | খাতা, রসিদ, ফাঁসাও, কুইজ, আরও (কল, নেতার ভাগ, দরকষাকষি, পালাও, সরকারি, লিডারবোর্ড) | এলাকা, দপ্তর, মাইক, ভাগ, তালিকা |
| Idea | Survive bhai, keep a real private ledger | Run a made-up neighbourhood; the leader above takes 10% of everything; police attention ends the run |

### Share cards

Every "ছবি কার্ড বানাও" button opens a preview with three looks (স্টিকার, নিয়ন, Y2K) and two sizes (4:5 post, 9:16 story). Each card gets a "POV:" caption and floating emoji stickers chosen from its kicker (`povFor` and `stickersFor` in `lib/share_card.dart`). To give a new feature its own caption, add its kicker word to the table in `povFor`. The link printed on every card and added to shared text is `appLink` in `lib/widgets.dart`.

### Shareable features

| Feature | Side | What gets shared |
|---|---|---|
| আজকের চাঁদা (daily run) | ভাই | Plain-text emoji row, e.g. `চাঁদা বাজার #২৮৬ 🤝😤😤🚔 ৳১৩৯ · নেতা নিল ৳২৯`. Same four neighbours and same dice for everyone each day (`SeededRandom`, so web and phone agree). |
| চাঁদা Wrapped | চাঁদাদাতা | 9:16 story slides built from the real ledger, one PNG per slide |
| পরিচয়পত্র | চাঁদাদাতা | ID card image with a photo (photo stays on the device) |
| ভাইয়ের ভয়েস | ভাই | Phone reads a prank line in Bangla (`flutter_tts`); the text is shareable. Needs a Bangla voice installed on the device. |
| ফোন পাস দরকষাকষি | চাঁদাদাতা | Two people, one phone; the chat and verdict become a card |
| মৌসুম ও খবর | both | Festival banner and game bonus; weekly price-report card |

Festival dates in `lib/season.dart` are approximate and need a yearly update.

The ভাই side is only a game: cartoon characters, fake money, no sharing of real names, nothing that can be used to collect real money. Every screen keeps the satire disclaimer.

## Layout

| File | What it holds |
|---|---|
| `lib/main.dart` | App shell: masthead, ticker, stats, tab rail, global taunts (idle tax, leaving-the-app fine) |
| `lib/theme.dart` | Palette (light and dark) and fonts |
| `lib/state.dart` | Saved progress: total paid, streak, badges (shared_preferences) |
| `lib/widgets.dart` | Cards, buttons, share bar, 4:5 image share card |
| `lib/screens/share_features.dart` | Receipt, tag-a-friend notice, victim quiz |
| `lib/screens/play_features.dart` | Fake bhai call, haggling, runaway button |
| `lib/screens/govt_board.dart` | Government satire cards, leaderboard, badges |
| `lib/screens/khata.dart`, `lib/ledger.dart` | Real on-device ledger: contributions and loans |
| `lib/screens/bhag.dart` | Leader's-cut calculator (10% by default) |
| `lib/baj_state.dart` | Collector game rules: targets, odds, upgrades, police-attention meter (unit-tested) |
| `lib/screens/baj_screens.dart` | Collector screens: neighbourhood, office and upgrades, loudspeaker, board |
| `lib/daily.dart`, `lib/screens/daily.dart` | Daily run: seeded neighbours and dice, streak, text share |
| `lib/wrapped.dart`, `lib/screens/wrapped.dart` | Yearly recap data and story slides |
| `lib/screens/idcard.dart` | ID card widget, photo storage, share |
| `lib/voice_script.dart`, `lib/screens/voice.dart` | Prank voice lines and text-to-speech playback |
| `lib/duel.dart`, `lib/screens/duel.dart` | Pass-the-phone haggle rules and screen |
| `lib/season.dart`, `lib/screens/news.dart` | Festival windows, weekly price report |
| `lib/util.dart` | Bangla digits, name filter (blocks politicians, parties, titles) |

## Notes

- Fonts (Galada, Hind Siliguri) load from Google Fonts at runtime, so the first launch needs internet. Bundle the font files as assets for offline use.
- The ringtone is generated in code, so there is no audio asset.
- Browsers only play audio after a tap; the fake call is started by a tap, so this works.
