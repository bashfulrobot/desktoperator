#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://wd12.myworkday.com/kong/d/home.htmld" \
  --class=brave-workday \
  --name="workday" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
