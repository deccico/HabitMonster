# Google Play listing — Task Monster (submission pack)

Status: **ready to submit.** Task Monster ships as a web app
(https://task-monster.ink) and a signed Android app bundle. This document holds
everything needed for the Play Console submission — store listing text plus the
exact answers for every App-content questionnaire.

- Package name: `com.darumatic.task_monster`
- Bundle to upload: v0.0.18+ (`scripts/release_android.sh` →
  `build/app/outputs/bundle/release/app-release.aab`). Do **not** upload
  v0.0.17 or earlier: Families-policy compliance (adult-gated external links,
  Advertising-ID collection disabled) landed in v0.0.18.
- Developer: Darumatic — hello@darumatic.com — https://darumatic.com
- Price / ads: Free, no ads, no in-app purchases

---

## Store listing text

### App name (max 30 chars)

> Task Monster

### Short description (max 80 chars)

> Do a real-life task, press the button, and watch your mystery monster evolve!

### Full description (max 4000 chars)

> **Turn everyday tasks into an adventure!**
>
> Task Monster is a simple, joyful reward app for kids and families. Finish a
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
> Task Monster is free and ad-free, made with ❤️ by Darumatic.

---

## Store settings

| Field | Value |
|---|---|
| App or game | App |
| Category | Parenting |
| Tags | Parenting, Productivity, Kids |
| Contact email (required) | hello@darumatic.com |
| Website | https://task-monster.ink |

## App content questionnaires — decided answers

### Privacy policy

`https://task-monster.ink/privacy.html` (live; source in
[`privacy-policy.md`](privacy-policy.md), hosted from `web/privacy.html`).

### Ads

Contains ads: **No.**

### App access

**All functionality is available without special access.** (The parent PIN is
user-created on-device, not a login; reviewers can use everything without
credentials.)

### Content rating (IARC questionnaire)

Category **"Utility, productivity, communication, or other"**; email
hello@darumatic.com. Every content question is **No**: no violence, sexuality,
language, controlled substances, gambling themes; no user-generated content or
user interaction/chat; no location sharing; no personal-info sharing; no
digital purchases (the "Buy me a coffee" donation opens in the external
browser and is not an in-app purchase). Expected rating: **Everyone / PEGI 3**.

### Target audience and content

Target age groups: **5–8, 9–12, and 18 & over** (mixed audience — kids use it
with their parents). Store presence appeals to children: yes, intentionally.

Families-policy compliance shipped in v0.0.18:

- External links ("Buy me a coffee", darumatic.com in Credits) sit behind an
  **adult gate** (`lib/services/adult_gate.dart`): parent PIN/fingerprint when
  the lock is on, otherwise an age-neutral arithmetic challenge.
- **Advertising ID is never collected**: `google_analytics_adid_collection_enabled=false`
  and ad-personalisation signals off in `AndroidManifest.xml`.
- No ads, no purchases, no chat, no third-party ad SDKs.

After approval, optionally opt in to the **Designed for Families** program
(the app meets its requirements; it adds the family-friendly badge).

### Data safety form

- **Does your app collect or share any of the required user data types?** Yes.
- Data types declared, all with: Collected **Yes**, Shared **No**, Processed
  ephemerally **No**, Required (no opt-out) **Yes**, Purpose **Analytics**:
  - *App activity → App interactions* (anonymous events via Google Analytics
    for Firebase, e.g. "an evolution happened").
  - *Device or other IDs* (Firebase app-instance ID only — **not** the
    Advertising ID, which is disabled).
- Is all collected data encrypted in transit? **Yes.**
- Do you provide a way to request deletion? Analytics data is anonymous and
  not linkable; all app data (profiles, progress, PIN) is on-device and
  deleted by uninstalling/clearing storage — declare via the privacy policy.
- Everything the child enters (names, stages, PIN hash) stays **on device**
  and is never transmitted.

### Remaining declarations

News app: **No.** COVID-19 contact-tracing/status app: **No.** Government
app: **No.** Financial features: **None.** Health features: **None.**

---

## Graphic assets (in this directory)

| Asset | File | Play requirement |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG ✓ |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 ✓ (says "Task Monster") |
| Phone screenshot 1 | `screenshot-1-mystery-egg.png` | 1080×2025 ✓ (min 2 required) |
| Phone screenshot 2 | `screenshot-2-evolved-dragon.png` | 1080×2025 ✓ |
| Phone screenshot 3 | `screenshot-3-profiles.png` | 1080×2025 ✓ |
| Phone screenshot 4 | `screenshot-4-parent-lock.png` | 1080×2025 ✓ |
| 7"/10" tablet screenshots | — | Optional; only needed for the tablet badge |

Screenshots are captured from the real app (dark theme) at phone aspect ratio.

---

## Submission walkthrough (Play Console)

1. [ ] **Create app**: name "Task Monster", App, Free, default language
       en-US → confirms package `com.darumatic.task_monster` on first upload.
2. [ ] **Internal testing** → create release → enrol in Play App Signing →
       upload `app-release.aab` (v0.0.18+), add yourself as tester.
3. [ ] **App content** (Policy → App content): work through each item with the
       answers above.
4. [ ] **Store listing**: paste the text from this file; upload icon, feature
       graphic and the four screenshots.
5. [ ] **Store settings**: category Parenting, contact details as above.
6. [ ] **Countries**: select all (or start with your launch markets).
7. [ ] Promote internal → **Production** and submit for review. Reviews for
       child-audience apps can take several days to a few weeks.
