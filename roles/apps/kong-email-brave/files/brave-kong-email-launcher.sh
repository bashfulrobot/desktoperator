#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://mail.google.com/mail/u/1/#search/is%3Aunread+in%3Ainbox" \
  --class=brave-kong-email \
  --name="kong email" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
