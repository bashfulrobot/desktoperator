#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://kong.lightning.force.com/lightning/page/home" \
  --class=brave-sfdc \
  --name="sfdc" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
