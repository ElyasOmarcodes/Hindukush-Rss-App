#!/usr/bin/env bash
# Post-scaffold patch for the iOS project: set a friendly display name.
set -euo pipefail

PLIST="ios/Runner/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "WARN: $PLIST not found; skipping iOS patch." >&2
  exit 0
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Hindukush" "$PLIST" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Hindukush" "$PLIST"

echo "iOS Info.plist patched (CFBundleDisplayName=Hindukush)."
