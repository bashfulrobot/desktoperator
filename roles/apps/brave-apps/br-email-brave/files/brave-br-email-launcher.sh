#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://mail.google.com/mail/u/0/#search/is%3Aunread+AND+label%3Anoffin.com+OR+in%3Ainbox" \
  --class=brave-br-email \
  --name="br email" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
