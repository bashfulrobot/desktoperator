#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://lucid.app/documents#/home" \
  --class=brave-lucid-chart \
  --name="lucid chart" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
