#!/usr/bin/env bash
set -euo pipefail
exec brave-browser \
  --app="https://drive.google.com/drive/u/0/my-drive" \
  --class=brave-br-drive \
  --name="br drive" \
  --no-first-run \
  --disable-features=TranslateUI,ExtensionsToolbarMenu \
  --ozone-platform=wayland \
  --ozone-platform-hint=auto \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  "$@"
