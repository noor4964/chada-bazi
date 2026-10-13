# চাঁদা বাজার (Chada Bazar): Project Context

A sarcastic, funny, Bangla-language satire app meant to go viral on social media. This file summarizes everything discussed so far.

---

## 1. Project Overview

- **Idea:** A satirical "Chada app" that jokes about everyday চাঁদাবাজি (forced collections) and government bureaucracy.
- **Language:** Bangla.
- **Goal:** Be funny and highly shareable on Facebook, Instagram, WhatsApp and Messenger.
- **Planned production stack (existing preference):** Flutter frontend, optional NestJS backend.
- **Prototype:** A single-page HTML dashboard published as a web artifact.
  - Live link: https://claude.ai/artifact/MG4ukaVYYaeNSrFRV4VnPG
  - File: `chada-bazar.html`

---

## 2. Features Implemented in the Dashboard Prototype

### Core "Chada" section
| Feature | What it does |
|---|---|
| Header banner and ticker | Street-banner style title with a scrolling joke ticker |
| Stats row | Total chada paid, victim level, escape count, bhai's mood emoji |
| চাঁদা ক্যালকুলেটর | Pick an occasion and number of bhais, then get a stamped fake receipt with silly line items ("ভাই-অ্যাডেড ট্যাক্স", "ভালোবাসার টাকা") |
| ভাইয়ের সাথে দরকষাকষি | Haggling chatbot with canned replies; low offers raise the rate, refusing raises it more |
| আজ কার পালা? | Spin wheel that picks a collector archetype (পাড়ার ভাই, ক্লাব সেক্রেটারি, জিজ্ঞেস না করা মামা...) |
| বাহানা জেনারেটর | Random absurd reasons for the collection, with a share button |
| চাঁদা মুদ্রাস্ফীতি | Bar chart showing "ভাইদর" spiking at Eid, Puja, elections |
| পালাও গেম | The pay button runs away when you try to press it |
| ভাই রেটিং | Reviews of fictional bhais |
| চাঁদা-মুক্তি বিমা | Fake insurance offer ending in "শর্ত প্রযোজ্য।" |

### "সরকারি ঝামেলা বিভাগ" (government and bureaucracy satire)
| Feature | What it does |
|---|---|
| ফাইল ট্র্যাকার | User types a file name; gets a table number, an excuse ("স্যার চা খেতে গেছেন"), and a multi-year ETA with a barely moving progress bar |
| উন্নয়ন ঘোষণা জেনারেটর | Random "crore taka project" announcements with a twist |
| প্রতিশ্রুতি বনাম বাস্তবতা | Promise vs reality pairs ("ডিজিটাল সেবা চালু" vs "ওয়েবসাইট ডাউন") |
| সরকারি অফিসে যান | Counter bot replying "আজ নয়, কাল আসুন", with a return-visit counter |
| ঢাকা জ্যাম ক্যালকুলেটর | Travel time by weather/condition compared with walking time |
| বিদ্যুৎ আছে? | Lightbulb that goes dark, with a running outage count |
| শেয়ার buttons | Share or copy text of each result |

### Design notes
- Bold street-banner aesthetic: red, bottle green, signboard yellow, off-white paper.
- Font: Hind Siliguri (with fallbacks).
- Responsive, light/dark theme tokens, safe-area padding for phones.
- Footer disclaimer: satire; fictional characters; targets no specific person, party or government; real extortion is a crime.

---

## 3. Ideas Suggested but Not Yet Built

- Image share cards (1:1 or 4:5) with app name and link on every result
- Personalized name and area receipts
- "তুমি কোন টাইপের চাঁদা-ভিকটিম?" quiz
- Tag-a-friend fake invoice
- Area leaderboards, daily streaks and badges
- Weekly "মুদ্রাস্ফীতি রিপোর্ট" styled as a news bulletin
- Seasonal themes (Eid, Puja, Boishakh, budget, elections)
- Voice lines and fake "ভাই কল করছে" ringtone
- Short Reels/video content generated from app output
- More govt satire cards: সরকারি টেন্ডার লটারি, ভিআইপি রোড ক্লোজার আপডেট

---

## 4. Virality Strategy

1. **Every result is a screenshot-ready card.** Big Bangla text, clean border, app name and link in the corner.
2. **Personalize.** People share things about themselves: their name, area, quiz result.
3. **Social pressure.** Leaderboards, streaks, tag-a-friend invoices.
4. **Ride trending moments.** Seasonal and event-based content, refreshed weekly.
5. **Audio and video.** Voice lines and Reel-friendly output.
6. **Tight humor.** Short, punchy, everyday Bangla slang; jokes about relatable situations, not individuals.
7. **Technical basics.** Open Graph tags with Bangla text, deep links, fast first screen with no login, proper Bangla fonts.

**Recommended first three:** image share cards, personalized quiz, tag-a-friend invoice.

---

## 5. AI and Backend Decision Notes

### Is AI worth it?
- AI does not create virality by itself; shareable results do. It adds **personalization and surprise**.
- Worth using for: the haggling bhai (open-ended replies), personal roasts, quiz write-ups, fresh seasonal jokes.
- Not worth it for: calculator, spin wheel, file tracker, dodge game (already funny, instant, free).

### Cheaper approach
Use AI **at build time** to generate hundreds of jokes, curate the best, and ship them as static content. This gives variety with no running cost and no risk of an offensive live reply.

### Free AI APIs: caveats
- Options include Google Gemini, Groq, OpenRouter free models and Cloudflare Workers AI. Check current limits and terms, as they change.
- Free tiers can hit rate limits if the app goes viral, so **always keep a canned-line fallback**.
- Test Bangla quality first; poor grammar kills jokes.

### Backend needed only if using AI or social features
- Hide the API key (never ship it in the Flutter app)
- Rate-limit per device
- Cache repeated requests
- Moderate output (no real names, politics, abuse)
- Leaderboards, share-link previews, analytics

**Suggested stack:** NestJS API for the full app, or a small serverless proxy (Cloudflare Workers or Firebase Functions) for the first version.

### Recommended roadmap
1. Launch static features plus image share cards (no backend, no cost).
2. Add one AI feature (haggling bhai) behind a rate-limited proxy with fallback.
3. Once there is traction, add accounts, leaderboards and analytics.

---

## 6. Safety and Legal Notes

- Keep targets **generic and fictional** (পাড়ার ভাই, সরকারি অফিস), with no named politicians, parties or real places.
- Keep the visible satire disclaimer.
- Include a Report button and the ability to remove content quickly.
- Filter free-text name inputs on receipt/invoice features to avoid harassment or defamation of real people.
- Be aware that online satire in Bangladesh has drawn cyber-law complaints, so generic framing lowers risk.
- Add guardrails to any AI bot against real names, political content and abuse.

---

## 7. Version 2.0 (চাঁদা বাজার ২.০)

- Live link: https://claude.ai/artifact/W48XVug36cdRCWfUcfAQ8Q
- File: `chada-bazar-v2.html`
- Tab layout with deep links: `#rosid`, `#notice`, `#quiz`, `#call`, `#dor`, `#palao`, `#sarkar`, `#board`

| Feature | What it does |
|---|---|
| Image share cards | Every result can be turned into a 1080×1350 PNG card with branding and a disclaimer, plus Copy, WhatsApp and Facebook buttons |
| নিজের রসিদ | Receipt with your name, place and occasion, random line items and a taunting verdict |
| বন্ধুকে ফাঁসাও | Tag-a-friend "চূড়ান্ত চাঁদা নোটিশ": crime, fine, deadline, punishment, appeal fee |
| ভিকটিম কুইজ | 5 questions leading to 4 types (দানবীর হাতেম তাই, অদৃশ্য মানব, দরকষাকষি চ্যাম্পিয়ন, বাহানা বিশেষজ্ঞ), with % bars |
| ভাইয়ের কল | Full-screen fake call with ringtone and a 5-second prank delay. Declining adds fines and escalating SMS, and bhai calls back |
| দরকষাকষি | Every offer, "না", "প্লিজ" or receipt request raises the rate. Giving up produces a "৳X বেশি দিলাম" card |
| পালাও | The "দেব না" button runs away 18 times with taunts. Catching it still costs a ৳২০০ fine |
| সরকারি ঝামেলা | File tracker with speed money, load-shedding bulb, tender lottery, VIP road update |
| লিডারবোর্ড and ব্যাজ | Ranking against fictional areas, 10 badges, daily streak (localStorage) |
| Global taunts | Tab title changes to "ভাই তোমাকে খুঁজছে 👀" when you switch away, with a fine when you return. Also an idle tax, a copy tax, and a live victim level and bhai mood |
| Safety | Name filter blocks politician, party and title words. Nicknames only. Visible disclaimer |

### Flutter version (app and web from one codebase)

- Project: `chada_bazar/` (Flutter 3.47, Android and web targets). See `chada_bazar/README.md` for run and build commands.
- Same features as the HTML prototype: receipt, tag-a-friend notice, victim quiz, fake bhai call (code-generated ringtone), haggling, runaway button, government cards, leaderboard and badges.
- Image share cards use `RepaintBoundary` to PNG, shared through `share_plus`; copy and text share are fallbacks.
- Progress is saved with `shared_preferences`.
- Web build output: `chada_bazar/build/web` (static files, host anywhere).

### Two perspectives and shareable features (Flutter)

- On first launch the user picks **চাঁদাদাতা** (payer, real ledger plus jokes) or **ভাই** (collector game); the choice can be switched from the header.
- ভাই game: cartoon neighbours, upgrades, police-attention meter, and a 10% cut that the leader above always takes.
- Shareable features: daily run with an emoji-row text share, চাঁদা Wrapped story slides, ID card with selfie, voice prank (text-to-speech), pass-the-phone haggle, seasonal banner and weekly price report.
- Details and file map: `chada_bazar/README.md`.

---

## 8. Suggested Next Steps

- [x] Add name-based "চাঁদা রসিদ" card with image export
- [x] Add the victim-type quiz
- [x] Add the tag-a-friend invoice
- [ ] Write the haggling bhai system prompt with guardrails
- [ ] Sketch a minimal serverless AI proxy with rate limiting and fallback
- [x] Port the prototype screens to Flutter
- [ ] Set up Open Graph tags and a landing page for sharing
- [ ] Collect real user feedback on which cards get shared most
