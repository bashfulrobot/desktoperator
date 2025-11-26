#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://app.tactiq.io/#/transcripts" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
