#!/usr/bin/env bash
# Build, archive and export a signed App Store .ipa for Task Monster.
#
# Signing is automatic (cloud-managed Apple Distribution certificate) via the
# Apple ID logged into Xcode, team DARUMATIC PTY LTD (76UL6RCLTT).
#
# Usage:
#   scripts/release_ios.sh            # build + archive + export .ipa
#   scripts/release_ios.sh --upload   # additionally upload to App Store Connect
#
# Output: build/ios/ipa/task_monster.ipa

set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER=${FLUTTER:-/opt/homebrew/bin/flutter}
ARCHIVE=build/ios/archive/Runner.xcarchive

echo "==> flutter build ios (release, no codesign)"
"$FLUTTER" build ios --release --no-codesign

echo "==> xcodebuild archive"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release archive \
  -archivePath "$ARCHIVE" \
  -destination "generic/platform=iOS" \
  DEVELOPMENT_TEAM=76UL6RCLTT \
  -allowProvisioningUpdates -quiet

echo "==> xcodebuild -exportArchive (app-store-connect)"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates -quiet

echo "==> Exported: $(ls build/ios/ipa/*.ipa)"

if [[ "${1:-}" == "--upload" ]]; then
  echo "==> Uploading to App Store Connect (requires the app record to exist)"
  UPLOAD_PLIST=$(mktemp -t ExportOptionsUpload).plist
  sed 's|<string>export</string>|<string>upload</string>|' \
    ios/ExportOptions.plist > "$UPLOAD_PLIST"
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath build/ios/upload \
    -exportOptionsPlist "$UPLOAD_PLIST" \
    -allowProvisioningUpdates
  echo "==> Upload complete. Check App Store Connect → TestFlight → Builds."
fi
