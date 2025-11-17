#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://bashfulrobot.omni.siderolabs.io/omni/" \
  --class=brave-omni \
  --name="omni" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
