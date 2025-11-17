# Brave Web App Builder (Brave Browser + CLI)

This role provides a lightweight alternative to the `pake` web-app builder.
It includes its own icon generation and generates standard `.desktop` entries
that simply open Brave with `--app=...` on Wayland.

## Features

- Validates `brave-browser` is installed before templating helpers
- Deploys `generate-brave-icon-set` and `create-brave-web-app` (`brave-web-apps.fish`) into `~/.config/fish/conf.d`
- Independent icon generation (no pake dependency)
- Optionally reuses existing `pake` icons as fallback if available
- Ensures every Brave app uses `--class=brave-<name>` / `StartupWMClass=brave-<name>` so the icon stays consistent in Alt+Tab
- Uses Wayland-friendly defaults (`--ozone-platform=wayland`, `--ozone-platform-hint=auto`, `--enable-features=UseOzonePlatform,WaylandWindowDecorations`, `--no-first-run`, etc.)
- Keeps Brave's main profile so bookmarks/logins/extensions stay shared

## Usage

1. Generate icons for your app:
   ```bash
   generate-brave-icon-set 'https://example.com/favicon.ico' myapp
   ```

2. Create the Brave web app scaffolding:
   ```bash
   create-brave-web-app https://example.com myapp
   ```

3. Wire the app into `roles/apps/defaults/main.yml` and `roles/apps/tasks/main.yml`

4. Deploy with Ansible:
   ```bash
   ansible-playbook site.yml --tags myapp-brave
   ```

**Note**: If pake icons already exist for an app, `create-brave-web-app` will automatically
copy them as a fallback, making the icon generation step optional.
