#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://cloud.konghq.com/us/overview/" \
  --class=brave-konnect \
  --name="konnect" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
