# Scripts Reference

Desktop Operator includes several utility scripts for system bootstrap, configuration capture, and theme generation. All scripts are located in the `scripts/` directory.

## Quick Reference

```bash
# Bootstrap & Setup
./scripts/bootstrap.sh              # Initial system setup (run once)
./scripts/secure-setup.sh           # Create/manage vault files

# COSMIC Configuration
jsys cosmic-capture                 # Capture COSMIC desktop config

# Theme Generation
jsys generate-cosmic-colors         # Extract colors from COSMIC
jsys generate-theme-files           # Generate all app themes
```

## Bootstrap Scripts

### `bootstrap.sh`

**Purpose**: Prepares a fresh Ubuntu system to run Ansible.

**When to use**: First-time setup on a new machine, before cloning the repository.

**Usage**:
```bash
# Download and run (typical workflow)
curl -O https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

# Or if repository is already cloned
cd ~/dev/iac/desktoperator
./scripts/bootstrap.sh
```

**What it does**:

1. **Hostname Configuration**
   - Prompts for hostname
   - Must match entry in `inventory/hosts.yml`
   - Updates system hostname and `/etc/hosts`

2. **Package Installation**
   - Updates APT package lists
   - Installs: `software-properties-common`, `git`, `curl`
   - Adds Ansible PPA
   - Installs: `ansible`, `ansible-lint`
   - Installs: `just` command runner
   - Installs: `1password`, `1password-cli`, `restic`
   - Installs: `autorestic`

3. **Repository Setup**
   - Clones desktoperator to `~/dev/iac/desktoperator`
   - Or uses existing clone

4. **Vivaldi Profile Restoration** (Optional)
   - Downloads encrypted Vivaldi profile from SSH server
   - Decrypts with ansible-vault
   - Extracts to `~/.config/vivaldi/`

5. **1Password Authentication**
   - Launches 1Password desktop app
   - Guides through CLI integration setup
   - Retrieves vault password from 1Password
   - Saves to `.vault_pass` (600 permissions)

6. **Restic Configuration** (Optional)
   - Retrieves B2 credentials from 1Password
   - Creates `~/.config/autorestic/autorestic.yml`
   - Sets up backup configuration

7. **Vault Setup**
   - Checks for existing `vault.yml`
   - Creates from template if missing
   - Ensures proper encryption

8. **Security Verification**
   - Checks for sensitive files in git staging
   - Verifies file permissions
   - Warns about unencrypted vault files

**Requirements**:
- Ubuntu-based system (Ubuntu, Pop!_OS)
- Internet connection
- 1Password account with `desktoperator-bootstrap` item

**Next steps after bootstrap**:
```bash
cd ~/dev/iac/desktoperator
just bootstrap
just run
```

---

### `secure-setup.sh`

**Purpose**: Creates and manages secure local files (vault password, encrypted secrets).

**When to use**:
- Initial repository setup (without 1Password)
- Manual vault management
- Creating new vault files
- Verifying security of existing setup

**Usage**:
```bash
cd ~/dev/iac/desktoperator
./scripts/secure-setup.sh
```

**What it does**:

1. **Create `.vault_pass`**
   - **Option 1**: Enter manually (prompted twice for confirmation)
   - **Option 2**: Generate random 32-byte password (recommended)
   - **Option 3**: Retrieve from 1Password
   - Sets 600 permissions

2. **Create/Encrypt `vault.yml`**
   - Copies from `group_vars/all/vault.yml.example`
   - Opens in editor for secret entry
   - Encrypts with `ansible-vault`
   - Sets 600 permissions

3. **Optional SSH Config** (gitignored)
   - Creates `files/home/.ssh/config` template
   - Safe for sensitive host entries

4. **Security Verification**
   - Checks file permissions (should be 600)
   - Verifies vault.yml is encrypted
   - Checks git staging for sensitive files
   - Reports any security issues

**Interactive prompts**:
- Vault password source selection
- Recreate existing files (yes/no)
- Edit vault.yml before encryption
- Create optional SSH config

**Differences from `bootstrap.sh`**:
- No 1Password required (can generate random password)
- More interactive/manual workflow
- Focused on repository secrets only
- No system package installation
- Can be run multiple times safely

**Security notes**:
- `.vault_pass` is gitignored - NEVER commit
- `vault.yml` CAN be committed when encrypted
- Always run security verification before committing

---

## COSMIC Configuration Scripts

### `capture-cosmic-config.sh`

**Purpose**: Captures current COSMIC desktop configuration to repository.

**When to use**: After making changes to COSMIC settings that you want to version control.

**Usage**:
```bash
# Via jsys (recommended)
jsys cosmic-capture

# Or directly
cd ~/dev/iac/desktoperator
./scripts/capture-cosmic-config.sh
```

**What it does**:

1. **Creates Backup**
   - Moves existing `cosmic-config/` to `cosmic-config.backup.<timestamp>`
   - Prevents accidental data loss

2. **Copies COSMIC Config**
   - Uses `rsync` to copy `~/.config/cosmic/` → `cosmic-config/`
   - Preserves directory structure
   - **Excludes theme mode files**:
     - `com.system76.CosmicTheme.Dark/v1/is_dark`
     - `com.system76.CosmicTheme.Mode/v1/is_dark`
   - These are excluded because theme mode should be system-managed, not version controlled

3. **Provides Next Steps**
   - Reminds to review changes with `git diff cosmic-config/`
   - Suggests commit workflow

**Exclusions rationale**:
Theme mode (dark/light/auto) changes frequently based on:
- Time of day (auto mode)
- User preference toggling
- System dark mode detection

These shouldn't be version controlled as they're dynamic preferences, not configuration.

**What gets captured** (132 files from 30 components):
- Terminal settings (font, colors, keybindings)
- Panel/dock configuration
- Theme colors (dark and light)
- Workspace settings
- Application preferences
- Keyboard shortcuts
- Window rules

**Typical workflow**:
```bash
# 1. Make changes in COSMIC Settings
# 2. Capture changes
jsys cosmic-capture

# 3. Review
git diff cosmic-config/

# 4. Commit
cd ~/dev/iac/desktoperator
just -f justfiles/git commit
```

---

## Theme Generation Scripts

### `generate-cosmic-colors.sh`

**Purpose**: Extracts COSMIC theme colors and converts to Ansible variables.

**When to use**:
- After changing COSMIC theme colors
- Before regenerating application themes
- When setting up a new machine

**Usage**:
```bash
# Via jsys (recommended)
jsys generate-cosmic-colors

# Or directly
cd ~/dev/iac/desktoperator
./scripts/generate-cosmic-colors.sh
```

**What it does**:

1. **Sources Color Extraction Library**
   - Loads `extract-cosmic-colors.sh` for RGBA conversion functions

2. **Reads COSMIC Theme Files**
   - Dark theme: `~/.config/cosmic/com.system76.CosmicTheme.Dark/v1/`
   - Light theme: `~/.config/cosmic/com.system76.CosmicTheme.Light/v1/`
   - Colors extracted:
     - `accent` - Highlight color (cyan)
     - `success` - Success/positive color (green)
     - `warning` - Warning color (yellow)
     - `destructive` - Error/danger color (red)
     - `background` - Main background
     - `primary` - Primary UI elements
     - `secondary` - Secondary UI elements

3. **Derives Text Colors**
   - Calculates readable text colors for dark/light backgrounds
   - Dark mode: Light text (#e0e0e0, #909090, #808080)
   - Light mode: Dark text (#202020, #505050, #707070)

4. **Special Accent Handling**
   - **Light theme uses dark theme's accent** color
   - Ensures bright cyan (#63d0df) is consistent across both themes
   - Matches COSMIC window border color

5. **Converts Color Formats**
   - COSMIC format: RGBA floats (0.0-1.0)
   - Converts to: RGB integers (0-255)
   - Converts to: Hex codes (#RRGGBB)

6. **Generates YAML**
   - Creates `group_vars/all/auto-colors.yml`
   - Includes timestamp and warning header
   - Structured format for Ansible templates

**Output format** (`auto-colors.yml`):
```yaml
---
# Auto-generated COSMIC theme color variables
# Generated: 2025-10-21 10:00:17
# DO NOT EDIT MANUALLY - Run 'just generate-cosmic-colors' to regenerate

theme_colors_dark:
  colors:
    accent:
      hex: "#63d0df"
      r: 99
      g: 208
      b: 223
    # ... more colors
```

**Why accent is the same in both themes**:
COSMIC uses a bright accent color for window borders that stays consistent regardless of theme mode. By using the same accent in both light and dark themes, VSCode and Vivaldi themes match the window borders perfectly.

---

### `extract-cosmic-colors.sh`

**Purpose**: Provides color conversion functions (library, not executed directly).

**When to use**: Sourced by other scripts, not run directly.

**Functions provided**:

1. **`extract_rgba_floats <file>`**
   ```bash
   # Extracts RGBA float values from COSMIC color file
   # Input: (red: 0.3882353, green: 0.8156863, blue: 0.8745098, alpha: 1.0)
   # Output: 0.3882353 0.8156863 0.8745098 1.0
   ```

2. **`rgba_to_rgb <r> <g> <b> <a>`**
   ```bash
   # Converts RGBA floats (0.0-1.0) to RGB integers (0-255)
   # Input: 0.3882353 0.8156863 0.8745098 1.0
   # Output: 99 208 223
   ```

3. **`rgb_to_hex <r> <g> <b>`**
   ```bash
   # Converts RGB integers to hex code
   # Input: 99 208 223
   # Output: #63d0df
   ```

**Usage in scripts**:
```bash
source "${SCRIPT_DIR}/extract-cosmic-colors.sh"

rgba=$(extract_rgba_floats "$COSMIC_CONFIG/accent")
rgb=$(rgba_to_rgb $rgba)
hex=$(rgb_to_hex $rgb)
```

---

### `generate-theme-files.sh`

**Purpose**: Orchestrates generation of all application theme files.

**When to use**: After extracting COSMIC colors, to regenerate all app themes.

**Usage**:
```bash
# Via jsys (recommended)
jsys generate-theme-files

# Or directly
cd ~/dev/iac/desktoperator
./scripts/generate-theme-files.sh
```

**What it does**:

1. **Generates VSCode Themes**
   - Calls `generate-vscode-themes.sh`
   - Creates `cosmic-theme.vsix`

2. **Generates Vivaldi Themes**
   - Calls `generate-vivaldi-themes.sh`
   - Creates `cosmic-dark.zip` and `cosmic-light.zip`

**Output**:
```
extras/themes/
├── vscode/
│   └── cosmic-theme.vsix          # VSCode extension
└── vivaldi/
    ├── cosmic-dark.zip            # Dark browser theme
    └── cosmic-light.zip           # Light browser theme
```

**Dependencies**:
- `group_vars/all/auto-colors.yml` must exist
- Run `generate-cosmic-colors.sh` first if needed

---

### `generate-vscode-themes.sh`

**Purpose**: Generates VSCode theme extension (VSIX).

**When to use**: Called by `generate-theme-files.sh` or run manually to rebuild VSCode theme.

**Usage**:
```bash
cd ~/dev/iac/desktoperator
./scripts/generate-vscode-themes.sh
```

**What it does**:

1. **Checks/Installs vsce**
   - Verifies `@vscode/vsce` is installed globally
   - Installs via npm if missing (requires sudo)

2. **Creates Build Directory**
   - `extras/themes/vscode/cosmic-theme/`
   - `extras/themes/vscode/cosmic-theme/themes/`

3. **Renders Templates** (using Ansible playbook)
   - `cosmic-dark.json.j2` → `themes/cosmic-dark.json`
   - `cosmic-light.json.j2` → `themes/cosmic-light.json`
   - `package.json.j2` → `package.json`
   - `vscodeignore.j2` → `.vscodeignore`

4. **Packages as VSIX**
   - Runs `vsce package`
   - Output: `extras/themes/vscode/cosmic-theme.vsix`
   - Single VSIX contains both dark and light themes

5. **Cleanup**
   - Removes build directory
   - Keeps only final VSIX

**Templates used**:
- `roles/apps/vscode/templates/cosmic-dark.json.j2` - Dark theme
- `roles/apps/vscode/templates/cosmic-light.json.j2` - Light theme
- `roles/apps/vscode/templates/package.json.j2` - Extension manifest
- `roles/apps/vscode/templates/vscodeignore.j2` - Build exclusions

**Color usage**:
Templates use a **hybrid approach**:
- COSMIC variables for brand colors (accent, semantic)
- Hardcoded values for syntax highlighting balance

---

### `generate-vivaldi-themes.sh`

**Purpose**: Generates Vivaldi browser theme packages (ZIP).

**When to use**: Called by `generate-theme-files.sh` or run manually to rebuild Vivaldi themes.

**Usage**:
```bash
cd ~/dev/iac/desktoperator
./scripts/generate-vivaldi-themes.sh
```

**What it does**:

1. **Creates Build Directories**
   - `extras/themes/vivaldi/cosmic-dark-build/`
   - `extras/themes/vivaldi/cosmic-light-build/`

2. **Copies Theme Icons**
   - Dark theme: `roles/apps/vivaldi/files/dark-icons/*.svg`
   - Light theme: `roles/apps/vivaldi/files/light-icons/*.svg`
   - Includes 40+ SVG icons for browser buttons

3. **Renders Theme Settings** (using Ansible playbook)
   - `theme-settings-dark.json.j2` → `theme.json` (dark build)
   - `theme-settings-light.json.j2` → `theme.json` (light build)

4. **Packages as ZIP**
   - Dark: `extras/themes/vivaldi/cosmic-dark.zip`
   - Light: `extras/themes/vivaldi/cosmic-light.zip`

5. **Cleanup**
   - Removes build directories
   - Keeps only final ZIPs

**Templates used**:
- `roles/apps/vivaldi/templates/theme-settings-dark.json.j2`
- `roles/apps/vivaldi/templates/theme-settings-light.json.j2`

**Icon sets**:
Custom SVG icons matching COSMIC design language for:
- Navigation buttons (back, forward, home)
- Panel buttons (downloads, bookmarks, extensions)
- Browser controls (reload, stop, settings)
- Status indicators (mail, calendar, sync)

---

## Script Dependencies

```
bootstrap.sh
  (standalone - no dependencies)

secure-setup.sh
  (standalone - no dependencies)
  └── Optional: 1Password CLI for password retrieval

capture-cosmic-config.sh
  (standalone)

generate-cosmic-colors.sh
  └── extract-cosmic-colors.sh (sourced)

generate-theme-files.sh
  ├── generate-vscode-themes.sh
  │   └── Requires: vsce (npm package)
  └── generate-vivaldi-themes.sh
      (no external dependencies)
```

## Common Workflows

### Fresh Machine Setup

```bash
# 1. Download and run bootstrap
curl -O https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

# 2. Navigate to repository
cd ~/dev/iac/desktoperator

# 3. Run Ansible (themes auto-generated)
just run
```

### Updating Themes After COSMIC Changes

```bash
# 1. Extract new colors
jsys generate-cosmic-colors

# 2. Generate theme files
jsys generate-theme-files

# 3. Deploy to applications
jsys app vscode
jsys app vivaldi

# 4. Commit changes (optional)
cd ~/dev/iac/desktoperator
just -f justfiles/git commit
```

### Capturing COSMIC Configuration

```bash
# 1. Make changes in COSMIC Settings
# 2. Capture configuration
jsys cosmic-capture

# 3. Review changes
git diff cosmic-config/

# 4. Commit if desired
cd ~/dev/iac/desktoperator
just -f justfiles/git commit
```

### Manual Vault Setup

```bash
# Create/manage vault files without 1Password
cd ~/dev/iac/desktoperator
./scripts/secure-setup.sh

# Choose option 2 (generate random) for vault password
# Edit vault.yml with your secrets
# Encrypt when prompted
```

## Environment Variables

### `bootstrap.sh`

- `DESKTOPERATOR_DIR` - Override repository location (default: `~/dev/iac/desktoperator`)

### All theme generation scripts

- Scripts automatically detect repository root using:
  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  ```

## Exit Codes

All scripts follow standard exit code conventions:
- `0` - Success
- `1` - General error
- Non-zero - Specific error (see script output)

Scripts use `set -euo pipefail` for:
- `e` - Exit on error
- `u` - Exit on undefined variable
- `pipefail` - Exit if any command in pipeline fails

## Security Considerations

### Sensitive Files Created

- `.vault_pass` - Ansible vault password (600 permissions, gitignored)
- `vault.yml` - Encrypted secrets (600 permissions when encrypted)
- `autorestic.yml` - Backup credentials (600 permissions)

### Git Safety

Scripts that create files check git status and warn about:
- Unencrypted vault files in staging
- Sensitive files accidentally staged
- Incorrect file permissions

Always run before committing:
```bash
just -f justfiles/security check-git
```

## Troubleshooting

### Bootstrap fails on package installation

```bash
# Update package lists
sudo apt-get update

# Try installing dependencies manually
sudo apt-get install -y software-properties-common git curl

# Re-run bootstrap
./scripts/bootstrap.sh
```

### Theme generation fails

```bash
# Ensure colors are extracted first
jsys generate-cosmic-colors

# Check that auto-colors.yml exists
cat group_vars/all/auto-colors.yml

# Regenerate themes
jsys generate-theme-files
```

### VSIX packaging fails

```bash
# Install vsce globally
sudo npm install -g @vscode/vsce

# Try again
./scripts/generate-vscode-themes.sh
```

### Permission errors

```bash
# Fix .vault_pass permissions
chmod 600 .vault_pass

# Fix vault.yml permissions
chmod 600 group_vars/all/vault.yml

# Verify
./scripts/secure-setup.sh
# (Choose existing files to verify only)
```

## See Also

- [Theme Generation Documentation](theme-generation.md)
- [COSMIC Desktop Documentation](cosmic-desktop.md)
- [Getting Started Guide](getting-started.md)
