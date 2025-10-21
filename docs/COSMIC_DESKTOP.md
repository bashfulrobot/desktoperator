# COSMIC Desktop Configuration Management

This guide explains how Desktop Operator manages your COSMIC desktop environment configuration through Ansible.

## Overview

COSMIC (Computer Operating System Main Interface Components) is System76's new desktop environment built in Rust. Desktop Operator manages all COSMIC configuration files, allowing you to:

- **Version control** your desktop settings
- **Synchronize** desktop configuration across multiple machines
- **Restore** your desktop environment on fresh installs
- **Track changes** to your desktop settings over time

## How It Works

COSMIC stores all configuration in `~/.config/cosmic/` with a directory structure like:

```
~/.config/cosmic/
├── com.system76.CosmicComp/          # Compositor settings
├── com.system76.CosmicTerm/          # Terminal settings
├── com.system76.CosmicPanel.Dock/    # Dock configuration
├── com.system76.CosmicTheme.Dark/    # Dark theme colors
├── com.system76.CosmicTheme.Light/   # Light theme colors
└── ... (30 components total)
```

Each component contains versioned configuration files under `v1/` subdirectories. These are simple text files with single values:

```bash
# Example: Terminal font size
$ cat ~/.config/cosmic/com.system76.CosmicTerm/v1/font_size
17

# Example: Dock position
$ cat ~/.config/cosmic/com.system76.CosmicPanel.Dock/v1/anchor
Bottom
```

Desktop Operator captures all 132 configuration files from these 30 components and stores them in your repository under `cosmic-config/`. When you run Ansible, it syncs these files back to `~/.config/cosmic/` on your machine.

## Quick Reference

```bash
# Capture your current COSMIC settings to the repository
just cosmic-capture

# Apply COSMIC configuration from repository
just cosmic

# Full desktop configuration (includes COSMIC)
just desktop

# Check what would change (dry run)
just check
```

## Initial Setup

The COSMIC role is already configured and will run automatically. On your first Ansible run after setup:

```bash
# Run full configuration (includes COSMIC)
just run

# Or run just the COSMIC configuration
just cosmic
```

This will sync your repository's `cosmic-config/` directory to `~/.config/cosmic/`.

## Workflow: Making Desktop Changes

### Method 1: Direct Changes (Recommended)

This is the typical workflow - change settings via COSMIC Settings app, then capture them:

**1. Make changes in COSMIC**
   - Use the COSMIC Settings application
   - Adjust panels, themes, shortcuts, etc.
   - Changes are immediately saved to `~/.config/cosmic/`

**2. Capture the changes**
   ```bash
   just cosmic-capture
   ```

**3. Review what changed**
   ```bash
   git diff cosmic-config/
   ```

**4. Commit the changes**
   ```bash
   just commit
   ```

**5. Apply to other machines**
   ```bash
   # On another machine
   git pull
   just cosmic
   ```

### Method 2: Edit Repository First

For advanced users who want to edit config files directly:

**1. Edit files in `cosmic-config/`**
   ```bash
   # Example: Change terminal font size
   echo "18" > cosmic-config/com.system76.CosmicTerm/v1/font_size
   ```

**2. Apply to your machine**
   ```bash
   just cosmic
   ```

**3. Commit the changes**
   ```bash
   just commit
   ```

## What Gets Managed

The COSMIC role manages **all** configuration for these components:

### Desktop Environment
- **CosmicComp** - Compositor (window management, tiling, workspaces)
- **CosmicPanel** - Top panel configuration
- **CosmicPanel.Dock** - Dock/launcher settings
- **CosmicPanel.Panel** - Panel-specific settings
- **CosmicWorkspaces** - Workspace configuration

### Applications
- **CosmicTerm** - Terminal emulator (font, colors, behavior)
- **CosmicEdit** - Text editor settings
- **CosmicFiles** - File manager preferences
- **CosmicStore** - App store configuration
- **CosmicAudio** - Audio settings

### Themes & Appearance
- **CosmicTheme.Dark** - Dark theme colors and styling
- **CosmicTheme.Light** - Light theme colors and styling
- **CosmicTheme.Dark.Builder** - Dark theme customization
- **CosmicTheme.Light.Builder** - Light theme customization
- **CosmicTheme.Mode** - Theme mode selector (dark/light/auto)
- **CosmicTk** - Toolkit settings (spacing, density, window controls)

### System Components
- **CosmicSettings** - Settings app configuration
- **CosmicSettingsDaemon** - Settings daemon
- **CosmicSettings.Shortcuts** - Keyboard shortcuts
- **CosmicSettings.Wallpaper** - Wallpaper configuration
- **CosmicSettings.WindowRules** - Per-application window rules
- **CosmicBackground** - Background/wallpaper service
- **CosmicIdle** - Idle/suspend settings
- **CosmicNotifications** - Notification settings
- **CosmicPortal** - Desktop portal settings

### Applets & Widgets
- **CosmicAppletAudio** - Audio applet
- **CosmicAppletTime** - Clock/time applet
- **CosmicAppLibrary** - Application library
- **CosmicAppList** - Application list/favorites
- **CosmicPanelButton** - Panel button configuration

**Total: 30 components, 132 configuration files**

## Common Scenarios

### Setting Up a New Machine

```bash
# 1. Run bootstrap (includes git clone)
./scripts/bootstrap.sh

# 2. Navigate to repository
cd ~/dev/iac/desktoperator

# 3. Run Ansible (COSMIC config will be applied automatically)
just run
```

Your COSMIC desktop will be configured exactly as defined in your repository.

### Sharing Configuration Across Machines

```bash
# On machine 1: Make changes and capture
just cosmic-capture
git diff cosmic-config/
just commit

# On machine 2: Pull and apply
git pull
just cosmic
```

### Backing Up Your Desktop Settings

Your COSMIC configuration is automatically backed up in git:

```bash
# View history of your desktop settings
git log --oneline cosmic-config/

# See what changed in a specific commit
git show abc1234 cosmic-config/

# Restore to a previous configuration
git checkout abc1234 -- cosmic-config/
just cosmic
```

### Testing COSMIC Changes

```bash
# 1. Make changes in COSMIC Settings
# 2. Test by logging out and back in
# 3. If you like the changes, capture them
just cosmic-capture

# 4. If you don't like them, restore from git
git checkout cosmic-config/
just cosmic
```

### Machine-Specific Settings

If you need different COSMIC settings per machine, you have options:

**Option 1: Don't manage via Ansible (per-component)**
```bash
# Remove specific component from repository
rm -rf cosmic-config/com.system76.CosmicPanel.Dock/
git commit -m "Don't manage dock config (machine-specific)"
```

**Option 2: Use git branches**
```bash
# Create machine-specific branch
git checkout -b desktop-home
# Make changes to cosmic-config/
just commit

# On work machine
git checkout -b desktop-work
# Different cosmic-config/ settings
just commit
```

**Option 3: Host-specific overrides**

Create host-specific configuration in inventory:

```yaml
# inventory/host_vars/desktop-home.yml
cosmic_components:
  # Only sync these specific components
  - com.system76.CosmicTerm
  - com.system76.CosmicTheme.Dark
```

## Troubleshooting

### COSMIC Settings Not Applying

**Problem**: You ran `just cosmic` but settings didn't change.

**Solution**: COSMIC caches some settings. Log out and back in, or restart COSMIC:
```bash
just cosmic
# Then log out and back in
```

### Configuration Conflicts

**Problem**: You changed settings locally and in git, now there are conflicts.

**Solution**: Decide which to keep:
```bash
# Keep local changes (what's on your machine)
just cosmic-capture  # Overwrites repository
git diff cosmic-config/
just commit

# Keep repository changes (discard local)
git checkout cosmic-config/  # Restore from git
just cosmic  # Apply to machine
```

### Missing Configuration Files

**Problem**: Some COSMIC components don't have config files yet.

**Explanation**: COSMIC only creates config files when you change a setting from its default. If you haven't customized a component, it won't have config files.

**Solution**: Change a setting in COSMIC Settings, then run `just cosmic-capture`.

### Sync Not Working

**Problem**: `just cosmic` runs but nothing changes.

**Debug steps**:
```bash
# 1. Check if cosmic-config exists in repo
ls -la cosmic-config/

# 2. Run in verbose mode
ansible-playbook site.yml --limit $(hostname) --tags cosmic -vv

# 3. Manually check sync
diff -r cosmic-config/ ~/.config/cosmic/
```

## Advanced Usage

### Selective Component Management

Edit `roles/desktop/cosmic/defaults/main.yml` to manage only specific components:

```yaml
cosmic_components:
  - com.system76.CosmicTerm
  - com.system76.CosmicPanel.Dock
  - com.system76.CosmicTheme.Dark
  # Remove others you don't want managed
```

### Template-Based Configuration

For dynamic values (like machine-specific paths), use Jinja2 templates:

```bash
# 1. Create template directory
mkdir -p roles/desktop/cosmic/templates/com.system76.CosmicTerm/

# 2. Create template
cat > roles/desktop/cosmic/templates/com.system76.CosmicTerm/font_size.j2 <<EOF
{{ cosmic_term_font_size | default('14') }}
EOF

# 3. Define variable per host
# inventory/host_vars/laptop.yml
cosmic_term_font_size: 12

# inventory/host_vars/desktop.yml
cosmic_term_font_size: 16
```

### Backup Before Sync

Enable backup to preserve current settings:

```yaml
# inventory/group_vars/all/settings.yml
cosmic_backup_existing: true
```

This creates `~/.config/cosmic-backup-<timestamp>` before syncing.

## File Reference

```
desktoperator/
├── cosmic-config/                    # Your COSMIC configuration (132 files)
│   ├── com.system76.CosmicComp/
│   ├── com.system76.CosmicTerm/
│   └── ... (30 components)
│
├── roles/desktop/cosmic/
│   ├── defaults/main.yml            # Default variables
│   ├── tasks/main.yml               # Sync tasks
│   ├── templates/                   # Optional Jinja2 templates
│   └── README.md                    # Role documentation
│
├── scripts/
│   └── capture-cosmic-config.sh     # Capture script
│
└── docs/
    └── COSMIC_DESKTOP.md            # This file
```

## Integration with Theme Management

Desktop Operator automatically extracts COSMIC theme colors and applies them to other applications, maintaining visual consistency across your desktop.

**Supported Applications**:
- **VSCode** - Color theme extension
- **Vivaldi** - Browser theme

**Quick Commands**:
```bash
# Extract colors from COSMIC
jsys generate-cosmic-colors

# Generate all application themes
jsys generate-theme-files

# Deploy to specific apps
jsys app vscode
jsys app vivaldi
```

For detailed information about theme generation, see:
- [Theme Generation Documentation](THEME_GENERATION.md) - Complete theme system guide
- [Scripts Reference](SCRIPTS.md) - All script documentation

## See Also

- [COSMIC Desktop Official Docs](https://github.com/pop-os/cosmic-epoch)
- [Ansible synchronize module](https://docs.ansible.com/ansible/latest/collections/ansible/posix/synchronize_module.html)
- [Desktop Operator Getting Started](GETTING_STARTED.md)
