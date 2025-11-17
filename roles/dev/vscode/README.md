# Visual Studio Code Role

Installs Visual Studio Code from the official Microsoft repository.

## Overview

This role installs Visual Studio Code using the official Microsoft apt repository for Ubuntu/Debian systems. This ensures you always get the latest stable version with automatic updates through the system package manager.

## Installation Method

- **Source**: Official Microsoft apt repository
- **Package**: `code`
- **Repository**: `https://packages.microsoft.com/repos/code`
- **GPG Key**: `https://packages.microsoft.com/keys/microsoft.asc`

## Features

- Installs from official Microsoft repository
- Supports both installation and removal
- Automatic updates via apt
- Clean removal of repository and keys when absent
- Follows Ansible best practices

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `app_states['vscode']` | `present` | Installation state (`present` or `absent`) |

## Dependencies

The role automatically installs required dependencies:
- `wget` - For downloading packages
- `gpg` - For GPG key management
- `apt-transport-https` - For HTTPS repository support

## Usage

### Install VSCode

VSCode is included in `common_apps` by default, so it will be installed automatically when you run:

```bash
just run
# or
just apps
```

### Install VSCode Only

```bash
just app vscode
# or
ansible-playbook site.yml --tags vscode
```

### Check Mode (Dry Run)

```bash
ansible-playbook site.yml --tags vscode --check --diff
```

### Remove VSCode

In your inventory or host_vars:

```yaml
app_states:
  vscode: absent
```

Then run:

```bash
just apps
```

## What Gets Configured

### Installed

When `app_states['vscode'] == 'present'`:
- Microsoft GPG key added to `/usr/share/keyrings/packages.microsoft.gpg`
- Microsoft repository added to `/etc/apt/sources.list.d/vscode.list`
- Package `code` installed
- Repository configured for automatic updates
- High-resolution icon installed to hicolor theme directory
- COSMIC Desktop compatibility (GNOME keyring integration)
- Wayland optimization flags configured
- Operator Mono Lig custom CSS file installed

### Removed

When `app_states['vscode'] == 'absent'`:
- Package `code` removed
- Microsoft repository removed
- GPG key removed

## Tags

- `vscode` - Run only VSCode tasks
- `editor` - Run all editor-related tasks
- `development` - Run all development tool tasks
- `apps` - Run all application tasks

## Examples

### Enable for All Hosts

Already enabled by default in `roles/apps/defaults/main.yml`:

```yaml
common_apps:
  - vscode

app_states:
  vscode: present
```

### Disable for Specific Host

In `inventory/host_vars/laptop.yml`:

```yaml
app_states:
  vscode: absent
```

### Manual Commands

```bash
# Install VSCode specifically
just install vscode

# Remove VSCode
just uninstall vscode

# Run with verbose output
ansible-playbook site.yml --tags vscode -vv
```

## Post-Installation

After installation, you can:

1. **Launch VSCode**
   ```bash
   code
   ```

2. **Install Extensions via CLI**
   ```bash
   code --install-extension ms-python.python
   code --install-extension ms-vscode.cpptools
   code --install-extension be5invis.vscode-custom-css
   ```

3. **Configure VSCode**
   - Settings sync via GitHub/Microsoft account
   - Manual configuration in `~/.config/Code/User/settings.json`

## Operator Mono Lig Font Setup

This role includes support for the **Operator Mono Lig** font - a premium programming font with excellent ligature support and beautiful italics.

### What's Included

The role automatically configures:

1. **Custom CSS file**: Located at `~/.config/Code/User/custom-css/operator_mono_lig_style.css`
2. **Font configuration**: Applies Operator Mono Lig to editor tokens and UI elements
3. **Ligature support**: Enables programming ligatures (=>, >=, ===, etc.)
4. **Italic styling**: Beautiful cursive italics for comments and keywords

### Font Installation

The Operator Mono Lig font files are installed by the [fonts role](../fonts/) from the [willfore/vscode_operator_mono_lig](https://github.com/willfore/vscode_operator_mono_lig) repository.

Font files are installed to `/usr/local/share/fonts/github-fonts/` and are available system-wide.

### VSCode Configuration Required

**One-time setup** (then Settings Sync will handle it):

1. **Install the vscode-custom-css extension**:
   ```bash
   code --install-extension be5invis.vscode-custom-css
   ```

2. **Settings are pre-configured** in `settings.json`:
   ```json
   {
     "editor.fontFamily": "'Iosevka Nerd Font', 'Operator Mono Lig', ...",
     "editor.fontLigatures": true,
     "vscode_custom_css.imports": [
       "file:///home/dustin/.config/Code/User/custom-css/operator_mono_lig_style.css"
     ],
     "vscode_custom_css.policy": true
   }
   ```

3. **Activate the custom CSS**:
   - Open Command Palette (Ctrl+Shift+P)
   - Run: `Reload Custom CSS and JS`
   - Reload VSCode

### Font Features

- **Base font**: Iosevka Nerd Font provides excellent ligatures and narrow/space-efficient rendering
- **Operator Mono Lig overlay**: Custom CSS applies Operator Mono Lig to specific tokens (keywords, comments, etc.)
- **Ligatures**: Programming symbols rendered as single glyphs (via Iosevka)
- **Italics**: Keywords, comments, and type names use beautiful cursive italics (via Operator Mono Lig)
- **Nerd Font symbols**: Full icon/symbol support for prompts and UI elements
- **Token styling**: Different code elements use appropriate font weights and styles
- **UI integration**: Tab titles use Operator Mono Lig for consistency
- **Stylistic sets**: Iosevka supports extensive customization via stylistic sets

### Font Hierarchy

The font family uses this fallback chain:
1. **Iosevka Nerd Font** - Base editor font with ligatures and Nerd Font symbols
2. **Operator Mono Lig** - Applied to specific tokens via custom CSS
3. **JetBrains Mono Nerd Font** - Fallback if above are unavailable
4. **Font Awesome icons** - For additional icon glyphs

### Verifying Font Installation

Check if the font is installed:

```bash
fc-list | grep -i "operator mono"
```

You should see entries for:
- OperatorMonoLig-Book.otf
- OperatorMonoLig-BookItalic.otf
- OperatorMonoLig-Light.otf
- OperatorMonoLig-LightItalic.otf

### Troubleshooting Operator Mono Lig

**Font not showing in VSCode**:
1. Verify font is installed: `fc-list | grep -i operator`
2. Rebuild font cache: `fc-cache -f -v`
3. Restart VSCode completely
4. Check settings.json has correct font family

**Custom CSS not applying**:
1. Verify extension is installed: `code --list-extensions | grep vscode-custom-css`
2. Check CSS file exists: `~/.config/Code/User/custom-css/operator_mono_lig_style.css`
3. Run "Reload Custom CSS and JS" from Command Palette
4. Check for errors in Developer Tools (Help → Toggle Developer Tools)

**Ligatures not working**:
- Ensure `"editor.fontLigatures": true` or specific ligatures are enabled in settings.json
- Some themes may override ligature settings

### Alternative Fonts

If you prefer different fonts, modify the font family in settings.json:
- **Iosevka Nerd Font**: Narrow, space-efficient, extensive stylistic sets (current)
- **Fira Code Nerd Font**: Popular, comprehensive ligature set
- **Victor Mono**: Cursive italics, open source
- **JetBrains Mono Nerd Font**: Clean, professional, excellent ligatures

### Iosevka Variants

This setup uses **Iosevka Nerd Font** (Default variant) which is optimized for code editors. Note:
- **Iosevka** (Default): For code editors like VSCode ✓
- **IosevkaTerm**: For terminal emulators (Cosmic Terminal uses this)
- **Iosevka Fixed**: Alternative with tighter spacing

### Iosevka Stylistic Sets

Iosevka supports extensive customization via [stylistic sets](https://github.com/be5invis/Iosevka/blob/main/doc/stylistic-sets.md). To use specific sets, configure `editor.fontLigatures` in VSCode settings:

```json
"editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03'"
```

**Recommended ligature settings:**
- `'calt'` - Default ligatures (contextual alternates)
- `'dlig'` - Discretionary ligatures (optional, additional)
- `false` - Disable all ligatures

The default `calt` setting provides balanced ligature support for most users.

## Integration with Desktop Operator

VSCode integrates with other Desktop Operator features:

- **System-wide installation** - Available for all users
- **Automatic updates** - Via apt package manager
- **Version control** - Installation state tracked in inventory
- **Multi-host** - Easy deployment across all machines

## Troubleshooting

### VSCode Not Installing

Check the Microsoft repository is accessible:
```bash
curl -s https://packages.microsoft.com/repos/code/dists/stable/InRelease
```

### GPG Key Issues

Manually verify the GPG key:
```bash
curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor
```

### Repository Not Found

Check repository configuration:
```bash
cat /etc/apt/sources.list.d/vscode.list
apt-cache policy code
```

### Clean Reinstall

```bash
# Set to absent
ansible-playbook site.yml --tags vscode -e "app_states={'vscode': 'absent'}"

# Set back to present
ansible-playbook site.yml --tags vscode -e "app_states={'vscode': 'present'}"
```

## References

- [VSCode Linux Installation Docs](https://code.visualstudio.com/docs/setup/linux)
- [Microsoft Package Repository](https://packages.microsoft.com/)
- [VSCode Downloads](https://code.visualstudio.com/Download)

## See Also

- [Claude Code Role](../claude-code/) - AI-powered coding assistant
- [Helix Role](../helix/) - Modern terminal-based editor
- [Apps Role Documentation](../README.md) - Overview of all app roles
