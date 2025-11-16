#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://developer.konghq.com/" \
  --class=brave-kong-docs \
  --name="kong docs" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
