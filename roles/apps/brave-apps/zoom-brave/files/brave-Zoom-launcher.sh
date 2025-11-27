#!/usr/bin/env bash
set -euo pipefail

# Accept URL argument or use default
URL="${1:-https://app.zoom.us/wc/home}"

exec brave-browser \
  --app="$URL" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations
