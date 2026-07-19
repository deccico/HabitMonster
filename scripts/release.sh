#!/usr/bin/env bash
# Full release cycle for Task Monster. Runs the mandatory steps in order:
#   local tests -> bump patch version -> commit & push -> GitHub CI check -> deploy to prod
#
#   ./scripts/release.sh                       # cuts a release of the committed tree
#   ./scripts/release.sh "Fix stage tracker"   # bundles staged/working changes under that message
#
# Any working-tree changes are committed with the given message (or a default
# "Release vX.Y.Z"). Deploy only happens after GitHub CI goes green.
set -euo pipefail

# This VPS's tool locations (flutter / firebase are not on the default PATH).
export PATH="/opt/flutter/bin:$HOME/.pub-cache/bin:$PATH"
# Project-scoped deploy credential (monstruous-tasker-manager service account:
# Firebase Hosting Admin on habit-monster-50e69, and Play Console Admin — the
# same key drives scripts/play_upload.py). Kept outside the repo; overrides any
# globally configured credential so other projects' deploys are unaffected.
# (The former monster-deployer account was deleted 2026-07-19.)
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.secrets/play-publisher.json"

cd "$(dirname "$0")/.."

msg="${1:-}"

echo "==> Local checks (analyze + test)"
flutter analyze
flutter test

echo "==> Bump patch version"
dart run tool/bump_version.dart
new_version="$(grep -oE "[0-9]+\.[0-9]+\.[0-9]+" lib/version.dart | head -1)"
if [ -z "$msg" ]; then
  msg="Release v${new_version}"
fi
echo "    ${msg}"

echo "==> Commit & push"
git add -A
git commit -m "$msg"
git push
sha="$(git rev-parse HEAD)"

echo "==> GitHub CI check (${sha})"
./scripts/check_ci.sh "$sha"

echo "==> Build web"
# --pwa-strategy=none: no service worker (web/flutter_service_worker.js ships
# a self-destruct worker for browsers that registered the old one), so with
# the no-cache hosting headers every reload gets the freshly deployed app.
flutter build web --pwa-strategy=none
# The build writes an EMPTY flutter_service_worker.js that clobbers the
# network-first offline worker copied from web/ — restore it, then inject the
# actual build file list as the offline precache manifest (first visit must
# cache the whole shell; runtime caching only sees post-activation requests).
cp web/flutter_service_worker.js build/web/flutter_service_worker.js
python3 - <<'PY'
import json, pathlib, re
root = pathlib.Path('build/web')
skip = {'flutter_service_worker.js', 'version.json', '.last_build_id', 'NOTICES'}
files = ['./'] + sorted(
    str(p.relative_to(root)).replace('\\', '/')
    for p in root.rglob('*')
    if p.is_file() and p.name not in skip
)
sw = root / 'flutter_service_worker.js'
text, count = re.subn(
    r'/\*__PRECACHE__\*/ \[[^\]]*\]',
    '/*__PRECACHE__*/ ' + json.dumps(files),
    sw.read_text(),
)
assert count == 1, 'precache placeholder not found in flutter_service_worker.js'
sw.write_text(text)
print(f'precache manifest: {len(files)} files')
PY

echo "==> Verify web plugin registrant"
# Guard against a stale generated registrant (bit RoadMate in v1.0.9-v1.0.18:
# the cached web_plugin_registrant.dart predated shared_preferences being
# added, so SharedPreferences silently threw MissingPluginException on web and
# progress never saved). Every *_web plugin package resolved in
# package_config.json must be imported by the registrant compiled into the build.
registrant="$(ls -t .dart_tool/flutter_build/*/web_plugin_registrant.dart 2>/dev/null | head -1)"
if [ -z "$registrant" ]; then
  echo "ERROR: no web_plugin_registrant.dart found after build" >&2
  exit 1
fi
missing=0
for pkg in $(grep -oE '"name": *"[a-z0-9_]+_web"' .dart_tool/package_config.json | grep -oE '[a-z0-9_]+_web'); do
  if ! grep -q "package:${pkg}/" "$registrant"; then
    echo "ERROR: ${pkg} is resolved but not registered in ${registrant}" >&2
    echo "       Stale build cache — run 'flutter clean' and rebuild." >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

echo "==> Deploy to prod"
firebase deploy --only hosting

echo "==> Released v${new_version} -> https://task-monster.ink"
