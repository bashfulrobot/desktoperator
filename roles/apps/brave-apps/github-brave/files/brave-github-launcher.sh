#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app=https://github.com \
  --class=brave-github \
  --name='GitHub' \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations "$@"
