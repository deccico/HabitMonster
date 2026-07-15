# Google Play listing — Habit Monster (pre-approval pack)

Status: **not yet published on Google Play.** Habit Monster currently ships as a
web app (https://habit-monster-50e69.web.app) and a signed APK distributed
directly. This document holds everything needed for the Play Console listing,
for review/approval before submission.

- Package name: `com.darumatic.habit_monster`
- Current version: v0.0.15 (versionCode from `pubspec.yaml` `+N`)
- Developer: Darumatic — hello@darumatic.com — https://darumatic.com
- Price / ads: Free, no ads, no in-app purchases

---

## Store listing text

### App name (max 30 chars)

> Habit Monster

### Short description (max 80 chars)

> Do a real-life task, press the button, and watch your mystery monster evolve!

### Full description (max 4000 chars)

> **Turn everyday tasks into an adventure!**
>
> Habit Monster is a simple, joyful reward app for kids and families. Finish a
> real-life task — homework, tidying up, brushing teeth — then press the big
> button and watch your monster evolve with a burst of animation and sound.
>
> **🥚 Every egg is a surprise**
> Your monster starts as a mystery egg. Nobody knows what's inside! It might
> grow into a mighty dragon, a blazing phoenix, a deep-sea leviathan, a
> thundering dinosaur, or a cosmic alien — each with 15 evolution stages, from
> adorable hatchling to epic final form.
>
> **⭐ Prestige and start again**
> Reach the final stage and earn a Prestige star — then a brand-new egg
> appears with a different creature inside.
>
> **👨‍👩‍👧‍👦 Made for families**
> • A profile for each child, with their own monster and progress
> • Optional parent lock: evolutions need a grown-up's 4-digit PIN (or
>   fingerprint) — so rewards stay honest
> • A one-minute cooldown between evolutions stops button-mashing
>
> **🔒 Private by design**
> No accounts, no sign-up, no ads. All progress is stored on your device.
>
> Habit Monster is free and ad-free, made with ❤️ by Darumatic.

---

## Categorisation & declarations

| Field | Value |
|---|---|
| App or game | App |
| Category | Parenting |
| Tags | Parenting, Productivity, Kids |
| Contains ads | No |
| In-app purchases | No |
| Content rating (IARC) | Everyone — no violence, no user-generated content, no chat, no gambling, no location sharing |
| Target audience | Decide before submission: "Parents" (18+) vs. including children. If any child age group is selected, the **Families policy** applies — see open items below. |
| App access | Full access, no login required |
| External link | In-app "Buy me a coffee" link (buymeacoffee.com/darumatic) opens in browser — allowed, but under Families policy external links need an adult gate; the parent lock does not currently gate the menu. Review before selecting a child audience. |

### Data safety form

- Collected: approximate usage/diagnostics via **Firebase Analytics** (app
  interactions, device/app info). No personal info, no location, no files.
- Shared with third parties: No (Google Analytics for Firebase acts as a
  service provider).
- Data encrypted in transit: Yes. Deletion: data is anonymous; local progress
  can be wiped by clearing app storage.
- All monster/profile data (names, stages, PIN hash) stays **on device** in
  local storage and is never transmitted.

### Privacy policy (required field)

Draft at [`privacy-policy.md`](privacy-policy.md). It must be hosted at a
public URL before submission — proposal: ship it as `privacy.html` on the web
app (https://habit-monster-50e69.web.app/privacy.html) in the next release and
paste that URL into the Play Console.

---

## Graphic assets (in this directory)

| Asset | File | Play requirement |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG ✓ |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 ✓ |
| Phone screenshot 1 | `screenshot-1-mystery-egg.png` | 1080×2025 ✓ (min 2 required) |
| Phone screenshot 2 | `screenshot-2-evolved-dragon.png` | 1080×2025 ✓ |
| Phone screenshot 3 | `screenshot-3-profiles.png` | 1080×2025 ✓ |
| Phone screenshot 4 | `screenshot-4-parent-lock.png` | 1080×2025 ✓ |
| 7"/10" tablet screenshots | — | Optional; only needed for the tablet badge |

Screenshots are captured from the real app (v0.0.15, dark theme) at phone
aspect ratio.

---

## Submission checklist (after pre-approval)

1. [ ] Decide target audience (parents-only vs. children — Families policy).
2. [ ] If a child audience is selected: gate the external links behind the
       parent lock and confirm Firebase Analytics is configured for
       child-directed treatment (or disabled on Android).
3. [ ] Host the privacy policy and paste the URL into Play Console.
4. [ ] Build an **app bundle** (Play does not accept APKs for new apps):
       `flutter build appbundle --release` — signs with the keystore
       referenced by the git-ignored `android/key.properties`.
5. [ ] Create the app in Play Console (com.darumatic.habit_monster), enrol in
       Play App Signing, upload the `.aab` to an internal-testing track first.
6. [ ] Fill store listing from this file; complete content-rating, data-safety
       and target-audience questionnaires as declared above.
7. [ ] Promote internal → production once review passes.
