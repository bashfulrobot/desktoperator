#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://teams.microsoft.com/v2/" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
