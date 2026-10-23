#!/bin/bash
# Builds a release archive and uploads it to App Store Connect for TestFlight.
# Needs: WC_TEAM_ID set in Config.xcconfig (paid Apple Developer team), and that team's
# Apple ID signed in under Xcode ▸ Settings ▸ Accounts. Run from the repo root.
set -euo pipefail

TEAM_ID=$(grep -E '^WC_TEAM_ID' Config.xcconfig | sed 's/.*= *//')
[ -n "$TEAM_ID" ] || { echo "Set WC_TEAM_ID in Config.xcconfig first."; exit 1; }

BUILD="${1:-$(date +%Y%m%d%H%M)}"   # build number must go up on every upload
OUT="build/release"

xcodegen generate -q
mkdir -p "$OUT"

xcodebuild -project WindCredit.xcodeproj -scheme WindCredit -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/WindCredit.xcarchive" \
  CURRENT_PROJECT_VERSION="$BUILD" CODE_SIGNING_ALLOWED=NO archive
# Archive unsigned, then let the export step sign everything with the team's
# distribution certificate and an App Store profile (no registered test devices needed).

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

xcodebuild -exportArchive -archivePath "$OUT/WindCredit.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT" -allowProvisioningUpdates

echo "Uploaded build $BUILD. It appears in App Store Connect ▸ TestFlight after processing (about 10–30 min)."
