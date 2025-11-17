#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://drive.google.com/drive/u/1/my-drive" \
  --class=brave-kong-drive \
  --name="kong drive" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
