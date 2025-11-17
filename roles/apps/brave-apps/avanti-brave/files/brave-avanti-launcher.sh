#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://avanti.letter.ai/" \
  --class=brave-avanti \
  --name="avanti" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
