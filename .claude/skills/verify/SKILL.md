---
name: verify
description: Build, serve, and drive Task Monster (Flutter web) headlessly to verify UI changes at the real surface.
---

# Verifying Task Monster (Flutter web)

Flutter is not on PATH: `export PATH="/opt/flutter/bin:$PATH"`.

## Build + serve

```bash
flutter build web --pwa-strategy=none        # same flags as release.sh
python3 -m http.server 8765 --directory build/web &   # kill with: pkill -f 'http.server 8765'
```

## Drive it

Use Playwright (`npm install playwright` in the scratchpad; browsers are already
in `/root/.cache/ms-playwright`). The app renders to canvas (CanvasKit), so DOM
selectors DON'T work and enabling the semantics placeholder only exposes the
logo label — **drive by viewport coordinates and verify each step from
screenshots**.

Known coordinates at viewport 480x900 (after ~8s boot/splash wait):

- App bar: profile button (296, 47), Reset (375, 47), lock (415, 47), ⋮ menu (456, 47)
- START button (240, 836)
- Info-menu sheet rows: About (240, 732), Support (240, 796), Credits (240, 860)

Gotchas:

- Wait ~8s after `goto` for the engine + splash, then ~1.2s after each click
  for sheet/dialog animations.
- Grant `permissions: ['clipboard-read', 'clipboard-write']` on the browser
  context to assert clipboard contents via `navigator.clipboard.readText()`.
- The cheer mascot animates forever; never wait for network/render idle.
