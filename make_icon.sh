#!/bin/zsh
# Regenerate Sources/ClipSaver/Resources/AppIcon.icns from Artwork/Icon.svg.
set -euo pipefail
cd "$(dirname "$0")"

ICONSET="$(mktemp -d)/AppIcon.iconset"
swift Tools/rasterize.swift Artwork/Icon.svg "$ICONSET"
iconutil -c icns "$ICONSET" -o Sources/ClipSaver/Resources/AppIcon.icns
echo "Wrote Sources/ClipSaver/Resources/AppIcon.icns"
