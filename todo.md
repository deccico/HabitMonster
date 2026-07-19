# TODO

## Opt in to Google Play "Designed for Families" after approval

After the app is approved on Google Play, opt in to the **Designed for
Families** program to get the family-friendly badge and surface Task Monster
in family-focused discovery.

Where: Play Console → Grow → **Designed for Families** (appears once the app
targets child age groups and is published).

The app already meets the requirements as of v0.0.18:

- [x] Target audience declared as 5–8, 9–12 and 18+ (mixed audience)
- [x] No ads, no in-app purchases, no third-party ad SDKs
- [x] External links (Buy me a coffee, darumatic.com) behind an adult gate
      (`lib/services/adult_gate.dart`)
- [x] Advertising-ID collection disabled (`AndroidManifest.xml` meta-data)
- [x] Privacy policy live at https://task-monster.ink/privacy.html covering
      children's data (nothing personal collected)
- [x] Content rating: Everyone / PEGI 3

Remaining steps:

- [ ] Wait for the initial production approval
- [ ] Complete the Designed for Families opt-in questionnaire in Play Console
- [ ] Confirm the family badge shows on the store listing

Reference: submission pack in `docs/play-store/listing.md`
("Target audience and content" section).

## Fix edge-to-edge display on Android

Play Console flagged a recommendation on the v0.0.22 production release:
"Edge-to-edge may not display for all users" (User experience). Apps
targeting SDK 35+ are drawn edge-to-edge by default on Android 15+, and the
current UI may not inset correctly behind the system bars.

- [ ] Audit screens with `SafeArea`/insets on an Android 15 device or emulator
- [ ] Fix any content drawn under the status/navigation bars
- [ ] Re-check the recommendation clears in Play Console → Production →
      Release dashboard after the next release
