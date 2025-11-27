#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://app.slack.com/client/T0DS5NB27" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
