# COSMIC Desktop Configuration Role

This Ansible role manages COSMIC desktop environment and application configurations by syncing config files from your repository to `~/.config/cosmic`.

## Overview

COSMIC stores its configuration in `~/.config/cosmic/` with individual directories for each component (desktop, applications, themes, etc.). Each component has versioned config files under a `v1/` subdirectory with simple text values.

## Font Configuration

### Cosmic Terminal Font

The terminal is configured to use **IosevkaTerm Nerd Font Mono**, which provides:
- Optimized metrics for terminal emulators
- Programming ligatures for code display
- Nerd Font symbols for shell prompts (Starship, Powerlevel10k, etc.)
- Narrow, space-efficient rendering

Configuration file: `config/com.system76.CosmicTerm/v1/font_name`

**Why IosevkaTerm?**
- IosevkaTerm is specifically optimized for terminal emulators with adjusted spacing
- Standard Iosevka is designed for code editors (VSCode, etc.)
- Both support ligatures and Nerd Font symbols, but IosevkaTerm has better terminal metrics

### Ligatures in Helix Editor

When using Helix editor inside Cosmic Terminal:
1. **Cosmic Terminal** controls font rendering (uses IosevkaTerm)
2. **Ligatures are enabled** automatically via the font's `calt` feature
3. **Helix displays ligatures** through the terminal's font rendering

No additional Helix configuration needed - ligatures work out of the box!

## Directory Structure

```
roles/desktop/cosmic/
├── config/               # COSMIC configuration files (synced to ~/.config/cosmic)
│   ├── com.system76.CosmicTerm/
│   │   └── v1/
│   │       ├── font_name        # Terminal font family
│   │       ├── font_size        # Terminal font size
│   │       └── ...
│   ├── com.system76.CosmicPanel/
│   ├── com.system76.CosmicTheme.Dark/
│   └── ...
├── defaults/
│   └── main.yml          # Default variables
├── tasks/
│   └── main.yml          # Main tasks
└── README.md             # This file
```

## Usage

### Standard Usage

The role automatically syncs all configurations from `roles/desktop/cosmic/config/` to `~/.config/cosmic/`:

```bash
ansible-playbook site.yml --tags cosmic
# or
just cosmic
```

### Modifying Terminal Font

To change the terminal font, edit:
```
roles/desktop/cosmic/config/com.system76.CosmicTerm/v1/font_name
```

Then run:
```bash
ansible-playbook site.yml --tags cosmic
```

Restart Cosmic Terminal for changes to take effect.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cosmic_config_path` | `{{ user.home }}/.config/cosmic` | Path to COSMIC config directory |
| `cosmic_components` | (see defaults/main.yml) | List of COSMIC components to manage |
| `cosmic_backup_existing` | `false` | Whether to backup existing config before managing |
| `cosmic_backup_dir` | `~/.config/cosmic-backup-<timestamp>` | Backup directory path |

## COSMIC Components

The role manages these COSMIC components by default:

**Desktop Environment:**
- CosmicComp (compositor)
- CosmicPanel (top panel)
- CosmicPanel.Dock (dock)
- CosmicPanel.Panel (panel configuration)
- CosmicWorkspaces (workspace management)

**Applications:**
- CosmicTerm (terminal)
- CosmicEdit (text editor)
- CosmicFiles (file manager)
- CosmicStore (app store)

**System & Settings:**
- CosmicSettings (settings app)
- CosmicSettingsDaemon (settings daemon)
- CosmicSettings.Shortcuts (keyboard shortcuts)
- CosmicSettings.Wallpaper (wallpaper settings)
- CosmicSettings.WindowRules (window rules)

**Themes:**
- CosmicTheme.Dark (dark theme)
- CosmicTheme.Light (light theme)
- CosmicTheme.Mode (theme mode selector)

**Other Components:**
- CosmicAppLibrary, CosmicAppList, CosmicBackground, CosmicIdle, CosmicNotifications, CosmicPortal, CosmicTk
- Applets: CosmicAppletAudio, CosmicAppletTime

## Tags

- `cosmic` - Run all COSMIC tasks
- `desktop` - Run desktop environment tasks (includes cosmic)

## Example Playbook

```yaml
- hosts: desktops
  vars:
    cosmic_backup_existing: true
  roles:
    - role: desktop/cosmic
```

## Notes

- COSMIC config files are simple text files with single values (no JSON/YAML)
- Each component stores config in versioned directories (v1/)
- Most config files are just plain text values like "17" or "IosevkaTerm Nerd Font Mono"
- The role can backup your existing config before managing it
- Configuration is synced using rsync with delete option (removes stale files)
- Changes typically require restarting the affected application or COSMIC session

## Integration with Other Roles

### Fonts Role
The [fonts role](../../apps/fonts/) installs IosevkaTerm Nerd Font, which is referenced in the terminal configuration.

### VSCode Role
The [VSCode role](../../apps/vscode/) uses regular Iosevka Nerd Font (optimized for editors, not terminals).

Both Iosevka variants provide ligatures and Nerd Font symbols, but with different spacing optimized for their use case.
