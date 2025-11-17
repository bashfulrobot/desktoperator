#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://chatgpt.com/codex" \
  --class=brave-codex \
  --name="codex" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
