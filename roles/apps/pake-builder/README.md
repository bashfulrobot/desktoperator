# Pake Web App Builder

Create desktop applications from websites using Pake (Rust + Tauri) via Docker.

## Overview

This role provides two main functions for creating and managing Pake desktop apps:

1. **`generate-icon-set`** - Download/process icons and generate multi-sized variants
2. **`create-web-app`** - Build Pake desktop app and Ansible role scaffolding

## Workflow

### Creating a New Web App

**IMPORTANT:** Icons must be generated BEFORE building the app (the .deb build requires icons to exist).

```bash
# Step 1: Generate icons and create role structure (MUST be first!)
generate-icon-set 'https://github.githubassets.com/favicons/favicon.svg' github

# Step 2: Build the app (.deb package + complete Ansible scaffolding)
create-web-app https://github.com github

# Step 3: Deploy via Ansible
ansible-playbook site.yml --tags github
```

## Function Reference

### `generate-icon-set`

Downloads or reads an icon file, converts to PNG, and generates multi-sized variants. When outputting to the Ansible repository (default), this function also creates the complete role directory structure (files/, tasks/, handlers/).

**Usage:**
```fish
generate-icon-set <icon_source> <name> [--output <path>] [--add-background]
```

**Arguments:**
- `icon_source` - URL or local file path (supports SVG, PNG, JPG)
- `name` - App name for output filenames
- `--output` - Custom output directory (default: Ansible repo)
- `--add-background` - Add gray rounded background

**Examples:**
```fish
# Generate icons to Ansible repo (default)
generate-icon-set 'https://github.../logo.svg' github

# Generate icons to Downloads folder
generate-icon-set './my-icon.png' myapp --output ~/Downloads

# Add background for logos with theme conflicts
generate-icon-set 'https://...' app --add-background
```

**Output Files:**

Default location: `~/dev/iac/desktoperator/roles/apps/<name>-pake/files/`
- `pake-<name>-icon.png` - Master high-quality source
- `pake-<name>-icon-16.png` through `pake-<name>-icon-800.png`

Custom location: `<output-path>/<name>/`
- `<name>.png` - Master high-quality source
- `<name>-16.png` through `<name>-800.png`

### `create-web-app`

Builds a Pake desktop app (.deb) and completes Ansible role scaffolding (tasks, handlers, desktop file). **Requires icons to be generated first** via `generate-icon-set`.

**Usage:**
```fish
create-web-app <app_url> <name> [pake-options...]
```

**Arguments:**
- `app_url` - Website URL to wrap
- `name` - App name
- `pake-options` - Any Pake CLI options (--width, --height, etc.)

**Examples:**
```fish
# Basic app
create-web-app https://github.com github

# With custom window size
create-web-app https://mail.google.com gmail --width 1600 --height 1000

# With system tray support
create-web-app https://slack.com slack --show-system-tray
```

**Output:**
- `.deb` package in `roles/apps/<name>-pake/files/`
- Completes Ansible role structure (adds tasks, handlers, desktop file)

**Important:** Icons must be generated FIRST using `generate-icon-set`. This function will fail with an error if the role directory and icons don't already exist.

## Helper Scripts

### Regenerate All Icons

Regenerate icons for all existing Pake apps:

```bash
./scripts/regenerate-pake-icons.fish
```

### Rebuild All Apps

Rebuild all Pake apps from scratch (icons + apps):

```bash
# Regenerate everything (icons first, then apps)
./scripts/regenerate-pake-apps.fish

# Deploy all apps
ansible-playbook site.yml --tags pake-apps
```

Note: `regenerate-pake-apps.fish` handles the complete workflow for each app:
1. Generates icons via `generate-icon-set`
2. Builds .deb and scaffolding via `create-web-app`

## File Structure

```
roles/apps/<name>-pake/
├── files/
│   ├── <name>.deb                    # Pake application package
│   ├── pake-<name>.desktop           # Desktop entry file
│   ├── pake-<name>-icon.png          # Master icon (high quality)
│   ├── pake-<name>-icon-16.png       # 16x16 icon
│   ├── pake-<name>-icon-32.png       # 32x32 icon
│   ├── pake-<name>-icon-48.png       # 48x48 icon
│   ├── pake-<name>-icon-64.png       # 64x64 icon
│   ├── pake-<name>-icon-128.png      # 128x128 icon
│   ├── pake-<name>-icon-256.png      # 256x256 icon
│   ├── pake-<name>-icon-512.png      # 512x512 icon
│   └── pake-<name>-icon-800.png      # 800x800 icon
├── tasks/
│   └── main.yml                      # Installation tasks
└── handlers/
    └── main.yml                      # Icon cache update handler
```

## Icon Size Reference

Icons are generated at the following sizes for optimal display across different contexts:

- **16x16** - Small taskbar/window decorations
- **32x32** - Standard taskbar
- **48x48** - Desktop shortcuts, file managers
- **64x64** - Large icons view
- **128x128** - High-DPI displays (small)
- **256x256** - High-DPI displays (medium)
- **512x512** - High-DPI displays (large)
- **800x800** - Scalable/extra large displays

## Tips

### Finding Icon URLs

1. **Favicon:** `https://example.com/favicon.ico`
2. **Apple Touch Icon:** `https://example.com/apple-touch-icon.png`
3. **Brandfetch:** Browse icons at https://brandfetch.com
4. **GitHub:** Repository → About section → Website → view page source → search for "og:image"

### When to Use `--add-background`

Use the `--add-background` flag when:
- Logo is too small/minimalist
- Icon has transparency that looks bad on all backgrounds
- Logo is designed for a specific background color
- You want a consistent app icon aesthetic

Examples:
- Asana logo (simple checkmark)
- Konnect logo (minimal design)

### Troubleshooting

**Icons not showing after deployment:**
```bash
# Update icon cache manually
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor
```

**Wrong icon size/quality:**
```bash
# Regenerate with a different source
generate-icon-set 'https://better-quality-icon.png' appname
ansible-playbook site.yml --tags appname
```

## Dependencies

- Docker (for building Pake apps)
- ImageMagick (for raster icon processing)
- librsvg2-bin (for SVG to PNG conversion)
- Fish shell (for wrapper functions)

These are installed automatically by the Pake role.
