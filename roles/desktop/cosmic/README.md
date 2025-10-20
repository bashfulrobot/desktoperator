# COSMIC Desktop Configuration Role

This Ansible role manages COSMIC desktop environment and application configurations by syncing config files from your repository to `~/.config/cosmic`.

## Overview

COSMIC stores its configuration in `~/.config/cosmic/` with individual directories for each component (desktop, applications, themes, etc.). Each component has versioned config files under a `v1/` subdirectory with simple text values.

## Directory Structure

```
roles/desktop/cosmic/
├── defaults/
│   └── main.yml          # Default variables
├── tasks/
│   └── main.yml          # Main tasks
├── templates/            # Optional Jinja2 templates for dynamic configs
└── README.md             # This file
```

## Usage

### Option 1: Copy entire COSMIC config to repository (Recommended)

1. Copy your current COSMIC config to the repository:
   ```bash
   cp -r ~/.config/cosmic cosmic-config/
   ```

2. Add the directory to your repository and commit it

3. Set this variable in your inventory or playbook:
   ```yaml
   cosmic_sync_from_repo: true
   ```

4. The role will sync the entire `cosmic-config/` directory to `~/.config/cosmic/`

### Option 2: Use templates for individual configs

1. Create templates for specific config files in `templates/`:
   ```
   templates/
   └── com.system76.CosmicTerm/
       └── font_size.j2
   ```

2. Define custom configs in your variables:
   ```yaml
   cosmic_use_templates: true
   cosmic_custom_configs:
     - component: com.system76.CosmicTerm
       file: font_size
     - component: com.system76.CosmicPanel.Dock
       file: size
   ```

3. Templates can use variables:
   ```jinja2
   {{ cosmic_term_font_size | default('14') }}
   ```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cosmic_config_path` | `{{ user.home }}/.config/cosmic` | Path to COSMIC config directory |
| `cosmic_components` | (see defaults/main.yml) | List of COSMIC components to manage |
| `cosmic_backup_existing` | `true` | Whether to backup existing config before managing |
| `cosmic_backup_dir` | `~/.config/cosmic-backup-<timestamp>` | Backup directory path |
| `cosmic_sync_from_repo` | `false` | Sync entire config from repository |
| `cosmic_use_templates` | `true` | Use templates for individual configs |
| `cosmic_custom_configs` | `[]` | List of custom configs to template |

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
    cosmic_sync_from_repo: true
    cosmic_backup_existing: true
  roles:
    - role: desktop/cosmic
```

## Notes

- COSMIC config files are simple text files with single values (no JSON/YAML)
- Each component stores config in versioned directories (v1/)
- Most config files are just plain text values like "17" or "Bottom"
- The role can backup your existing config before managing it
- Use the sync approach for full configuration management
- Use templates for selective/dynamic configuration
