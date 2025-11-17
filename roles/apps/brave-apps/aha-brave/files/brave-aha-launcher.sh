#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://konghq.aha.io/products/AI/feature_cards" \
  --class=brave-aha \
  --name="aha" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
