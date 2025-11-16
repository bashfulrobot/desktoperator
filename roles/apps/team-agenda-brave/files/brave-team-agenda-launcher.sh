#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://docs.google.com/document/d/1VyhPZPHQofpooPC3Shz70evrlCxG-jBToJ21vYWF0Ho" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
