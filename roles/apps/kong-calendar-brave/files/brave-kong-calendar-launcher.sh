#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://calendar.google.com/calendar/u/1/r" \
  --class=brave-kong-calendar \
  --name="kong calendar" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
