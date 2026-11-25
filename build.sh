#!/bin/zsh
# Build ClipSaver.app + its share extension (ad-hoc signed, runs locally).
set -euo pipefail
cd "$(dirname "$0")"

xcodegen

xcodebuild \
  -project ClipSaver.xcodeproj \
  -scheme ClipSaver \
  -configuration Release \
  -derivedDataPath .build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  build

APP=".build/Build/Products/Release/ClipSaver.app"
echo "Built: $APP"
pluginkit -mv -i com.apple.share-services 2>/dev/null | grep -i clipsaver || true
