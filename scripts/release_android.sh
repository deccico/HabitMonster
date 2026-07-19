#!/usr/bin/env bash
# Android release cycle for Task Monster. Same mandatory steps as release.sh,
# but the artifact is a signed app bundle for Google Play instead of a web
# deploy:
#   local tests -> bump patch version -> commit & push -> GitHub CI check
#   -> build signed .aab
#
#   ./scripts/release_android.sh                     # cuts a release of the committed tree
#   ./scripts/release_android.sh "Fix stage tracker" # bundles working changes under that message
#
# The .aab lands in build/app/outputs/bundle/release/app-release.aab and is
# then uploaded to the Play internal testing track via scripts/play_upload.py
# (override the track with PLAY_TRACK, or skip the upload with PLAY_TRACK=none;
# promote internal -> production in the Play Console).
set -euo pipefail

# Tool locations per machine (flutter/keytool are not on the default PATH).
if [ "$(uname)" = "Darwin" ]; then
  # Adrian's Mac: Homebrew flutter + JDK 17 (keytool needs JAVA_HOME here).
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  export PATH="/opt/homebrew/bin:$JAVA_HOME/bin:$HOME/.pub-cache/bin:$PATH"
else
  # ai-box VPS.
  export PATH="/opt/flutter/bin:$HOME/.pub-cache/bin:$PATH"
fi

cd "$(dirname "$0")/.."

# Release signing is mandatory for a Play upload: without android/key.properties
# the Gradle config silently falls back to the debug key, which Play rejects.
if [ ! -f android/key.properties ]; then
  echo "ERROR: android/key.properties not found — refusing to build a debug-signed bundle." >&2
  exit 1
fi

msg="${1:-}"

echo "==> Local checks (analyze + test)"
flutter analyze
flutter test

echo "==> Bump patch version"
dart run tool/bump_version.dart
new_version="$(grep -oE "[0-9]+\.[0-9]+\.[0-9]+" lib/version.dart | head -1)"
if [ -z "$msg" ]; then
  msg="Release v${new_version} (Android)"
fi
echo "    ${msg}"

echo "==> Commit & push"
git add -A
git commit -m "$msg"
git push
sha="$(git rev-parse HEAD)"

echo "==> GitHub CI check (${sha})"
./scripts/check_ci.sh "$sha"

echo "==> Build signed app bundle"
flutter build appbundle --release

aab="build/app/outputs/bundle/release/app-release.aab"
[ -f "$aab" ] || { echo "ERROR: expected bundle not found at ${aab}" >&2; exit 1; }

echo "==> Verify release signature"
# keytool exits 0 even for a debug-signed jar, so check the certificate is the
# release one (CN from the keystore, not "Android Debug").
cert="$(keytool -printcert -jarfile "$aab")"
if echo "$cert" | grep -q "Android Debug"; then
  echo "ERROR: bundle is debug-signed" >&2
  exit 1
fi
echo "$cert" | grep -m1 "Owner:"

track="${PLAY_TRACK:-internal}"
if [ "$track" = "none" ]; then
  echo "==> Released v${new_version} (Play upload skipped)"
  echo "    Bundle: ${aab}"
else
  echo "==> Upload to Play (${track} track)"
  python3 scripts/play_upload.py "$aab" --track "$track"
  echo "==> Released v${new_version} to Play ${track}"
fi
