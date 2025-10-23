# Theme Generation System

Desktop Operator automatically generates application themes from your COSMIC desktop colors, ensuring visual consistency across all applications.

## Overview

The theme generation system extracts colors from COSMIC Desktop and applies them to:
- **VSCode** - Color theme extension (VSIX)
- **Vivaldi** - Browser theme (ZIP)

This creates a unified visual experience where all applications match your desktop theme.

## Quick Reference

```bash
# Extract COSMIC theme colors to Ansible variables
jsys generate-cosmic-colors

# Generate all application theme files (VSCode + Vivaldi)
jsys generate-theme-files

# Deploy themes to specific applications
jsys app vscode
jsys app vivaldi
```

## How It Works

### 1. Color Extraction

COSMIC stores theme colors in `~/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}/v1/`:

```
~/.config/cosmic/
├── com.system76.CosmicTheme.Dark/v1/
│   ├── accent          # Cyan highlight color
│   ├── success         # Green color
│   ├── warning         # Yellow color
│   ├── destructive     # Red/error color
│   ├── background      # Main background
│   ├── primary         # Primary UI elements
│   └── secondary       # Secondary UI elements
└── com.system76.CosmicTheme.Light/v1/
    └── (same structure)
```

Colors are stored as RGBA float values:
```ron
(
    red: 0.3882353,
    green: 0.8156863,
    blue: 0.8745098,
    alpha: 1.0,
)
```

**Script**: `scripts/generate-cosmic-colors.sh`
- Extracts colors from both Dark and Light themes
- Converts RGBA floats → RGB integers → Hex codes
- Generates `group_vars/all/auto-colors.yml`

**Special Behavior - Accent Color Consistency**:
The script ensures the bright accent color (cyan) is the same in both light and dark themes by using the dark theme's accent for both. This matches the COSMIC window border color across theme modes.

### 2. Theme Generation

Once colors are extracted, theme files are generated for each application.

**Script**: `scripts/generate-theme-files.sh`
- Orchestrates theme generation for all apps
- Calls `generate-vscode-themes.sh`
- Calls `generate-vivaldi-themes.sh`

#### VSCode Theme Generation

**Script**: `scripts/generate-vscode-themes.sh`

**Process**:
1. Loads `group_vars/all/auto-colors.yml`
2. Renders Jinja2 templates:
   - `cosmic-dark.json.j2` → Dark theme
   - `cosmic-light.json.j2` → Light theme
   - `package.json.j2` → Extension manifest
3. Packages with `vsce` → `cosmic-theme.vsix`

**Templates**: `roles/apps/vscode/templates/`
- `cosmic-dark.json.j2` - Dark theme with hardcoded colors + selective COSMIC variables
- `cosmic-light.json.j2` - Light theme with hardcoded colors + selective COSMIC variables
- `package.json.j2` - VSCode extension metadata
- `vscodeignore.j2` - Build exclusions

**Output**: `extras/themes/vscode/cosmic-theme.vsix`
- Single VSIX package containing both dark and light themes
- Auto-installed when running `jsys app vscode`

**Design Philosophy**:
VSCode themes use a **hybrid approach**:
- **COSMIC variables**: Used for brand/accent colors that should match desktop
  - `badge.background`, `activityBarBadge.background` → accent
  - `checkbox.border`, `focusBorder` → accent
  - `minimap` highlights → accent
  - Semantic colors (success, warning, destructive)
- **Hardcoded values**: Used for fine-tuned syntax highlighting and UI balance
  - Syntax token colors (strings, keywords, functions, etc.)
  - Specific UI element backgrounds
  - List selections and hover states

This provides consistency with COSMIC while maintaining professional syntax highlighting.

#### Vivaldi Theme Generation

**Script**: `scripts/generate-vivaldi-themes.sh`

**Process**:
1. Loads `group_vars/all/auto-colors.yml`
2. Renders theme JSON files:
   - `theme-settings-dark.json.j2` → Dark theme
   - `theme-settings-light.json.j2` → Light theme
3. Copies theme button icons
4. Packages as ZIP files

**Templates**: `roles/apps/vivaldi/templates/`
- `theme-settings-dark.json.j2` - Dark theme configuration
- `theme-settings-light.json.j2` - Light theme configuration

**Icons**: `roles/apps/vivaldi/files/{dark,light}-icons/`
- Custom SVG icons for browser buttons matching theme

**Output**:
- `extras/themes/vivaldi/cosmic-dark.zip`
- `extras/themes/vivaldi/cosmic-light.zip`

### 3. Theme Deployment

Themes are deployed via Ansible roles when you run:

```bash
jsys app vscode    # Installs cosmic-theme.vsix extension
jsys app vivaldi   # Installs Vivaldi theme ZIPs
```

**VSCode Deployment** (`roles/apps/vscode/tasks/main.yml`):
- Checks if theme VSIX exists
- Auto-generates if missing
- Installs via VSCode CLI

**Vivaldi Deployment** (`roles/apps/vivaldi/tasks/main.yml`):
- Generates theme files
- Copies to Vivaldi user data directory
- Updates Vivaldi configuration

## Workflows

### Updating Theme Colors

When you change your COSMIC desktop theme:

```bash
# 1. Extract new colors from COSMIC
jsys generate-cosmic-colors

# 2. Review color changes
git diff group_vars/all/auto-colors.yml

# 3. Regenerate all theme files
jsys generate-theme-files

# 4. Review theme changes
git diff extras/themes/

# 5. Deploy to applications
jsys app vscode
jsys app vivaldi

# 6. Commit changes (optional)
cd ~/dev/iac/desktoperator
just -f justfiles/git commit
```

### Fresh Install Theme Setup

On a new machine after running `just run`:

```bash
# Themes are automatically generated and deployed
# But you can manually regenerate if needed:
jsys generate-cosmic-colors
jsys generate-theme-files
jsys app vscode
jsys app vivaldi
```

### Customizing Themes

#### VSCode Theme Customization

Edit the template files to adjust colors:

**Location**: `roles/apps/vscode/templates/cosmic-{dark,light}.json.j2`

**Examples**:

```jinja2
// Use COSMIC variable
"badge.background": "{{ theme_colors_dark.colors.accent.hex }}"

// Use hardcoded value for fine control
"list.inactiveSelectionBackground": "#94EBEB60"

// Combine for opacity
"editor.selectionBackground": "{{ theme_colors_dark.colors.accent.hex }}40"
```

After editing, regenerate:
```bash
jsys generate-theme-files
jsys app vscode
```

#### Vivaldi Theme Customization

Edit: `roles/apps/vivaldi/templates/theme-settings-{dark,light}.json.j2`

```jinja2
{
  "colorAccentBg": "{{ theme_colors_dark.colors.primary.hex }}",
  "colorBg": "{{ theme_colors_dark.colors.primary.hex }}",
  "colorHighlightBg": "{{ theme_colors_dark.colors.accent.hex }}"
}
```

After editing:
```bash
jsys generate-theme-files
jsys app vivaldi
```

## File Structure

```
desktoperator/
├── scripts/
│   ├── generate-cosmic-colors.sh      # Extract colors from COSMIC
│   ├── extract-cosmic-colors.sh       # Color conversion library
│   ├── generate-theme-files.sh        # Orchestrate all theme generation
│   ├── generate-vscode-themes.sh      # VSCode VSIX generation
│   └── generate-vivaldi-themes.sh     # Vivaldi ZIP generation
│
├── group_vars/all/
│   └── auto-colors.yml                # Auto-generated color variables
│
├── roles/apps/vscode/templates/
│   ├── cosmic-dark.json.j2            # Dark theme template
│   ├── cosmic-light.json.j2           # Light theme template
│   ├── package.json.j2                # Extension manifest
│   └── vscodeignore.j2                # Build exclusions
│
├── roles/apps/vivaldi/templates/
│   ├── theme-settings-dark.json.j2    # Dark theme template
│   └── theme-settings-light.json.j2   # Light theme template
│
├── roles/apps/vivaldi/files/
│   ├── dark-icons/                    # SVG icons for dark theme
│   └── light-icons/                   # SVG icons for light theme
│
└── extras/themes/
    ├── vscode/
    │   └── cosmic-theme.vsix          # Generated VSCode extension
    └── vivaldi/
        ├── cosmic-dark.zip            # Generated dark theme
        └── cosmic-light.zip           # Generated light theme
```

## Available Colors

Colors are extracted from COSMIC and available as Ansible variables:

```yaml
theme_colors_dark:
  colors:
    accent:      { hex: "#63d0df", r: 99, g: 208, b: 223 }  # Cyan highlight
    success:     { hex: "#92cf9c", r: 146, g: 207, b: 156 } # Green
    warning:     { hex: "#f7e062", r: 247, g: 224, b: 98 }  # Yellow
    destructive: { hex: "#fda1a0", r: 253, g: 161, b: 160 } # Red
    background:  { hex: "#1b1b1b", r: 27, g: 27, b: 27 }    # Darkest
    primary:     { hex: "#272727", r: 39, g: 39, b: 39 }    # Dark gray
    secondary:   { hex: "#343434", r: 52, g: 52, b: 52 }    # Medium gray
    text_primary:   { hex: "#e0e0e0", r: 224, g: 224, b: 224 } # Light text
    text_secondary: { hex: "#909090", r: 144, g: 144, b: 144 } # Muted text
    text_tertiary:  { hex: "#808080", r: 128, g: 128, b: 128 } # Inactive text

theme_colors_light:
  colors:
    accent:      { hex: "#63d0df", r: 99, g: 208, b: 223 }  # Same as dark!
    success:     { hex: "#185529", r: 24, g: 85, b: 41 }
    warning:     { hex: "#534800", r: 83, g: 72, b: 0 }
    destructive: { hex: "#78292e", r: 120, g: 41, b: 46 }
    background:  { hex: "#d7d7d7", r: 215, g: 215, b: 215 }
    primary:     { hex: "#ebebeb", r: 235, g: 235, b: 235 }
    secondary:   { hex: "#fcfcfc", r: 252, g: 252, b: 252 }
    text_primary:   { hex: "#202020", r: 32, g: 32, b: 32 }
    text_secondary: { hex: "#505050", r: 80, g: 80, b: 80 }
    text_tertiary:  { hex: "#707070", r: 112, g: 112, b: 112 }
```

**Note**: Accent color is intentionally the same in both themes to match COSMIC window borders.

## Troubleshooting

### Colors Not Updating

**Problem**: Generated themes still use old colors.

**Solution**:
```bash
# Regenerate colors from COSMIC
jsys generate-cosmic-colors

# Check that auto-colors.yml was updated
git diff group_vars/all/auto-colors.yml

# Regenerate themes
jsys generate-theme-files

# Force reinstall
jsys app vscode
```

### VSCode Theme Not Showing

**Problem**: VSCode doesn't show the COSMIC theme.

**Solution**:
```bash
# Check if VSIX was generated
ls -la extras/themes/vscode/cosmic-theme.vsix

# Manually install
code --install-extension extras/themes/vscode/cosmic-theme.vsix

# Then in VSCode: Preferences → Theme → COSMIC Dark/Light
```

### Vivaldi Theme Not Applying

**Problem**: Vivaldi shows old theme colors.

**Solution**:
```bash
# Regenerate and redeploy
jsys generate-theme-files
jsys app vivaldi

# Restart Vivaldi
# Theme should auto-apply on next launch
```

### Build Errors

**Problem**: `vsce package` fails when generating VSCode theme.

**Solution**:
```bash
# Ensure vsce is installed
npm list -g @vscode/vsce

# If not installed
sudo npm install -g @vscode/vsce

# Regenerate
jsys generate-theme-files
```

## Advanced Usage

### Adding New Applications

To add theme support for another application:

1. **Create generation script**:
   ```bash
   scripts/generate-myapp-themes.sh
   ```

2. **Call from orchestrator**:
   ```bash
   # Edit scripts/generate-theme-files.sh
   echo "→ MyApp themes..."
   "${SCRIPT_DIR}/generate-myapp-themes.sh"
   ```

3. **Create Ansible role**:
   ```bash
   roles/apps/myapp/
   ├── tasks/main.yml        # Deployment logic
   ├── templates/
   │   └── theme.json.j2     # Theme template using auto-colors.yml
   └── defaults/main.yml     # Configuration
   ```

4. **Use generated colors**:
   ```jinja2
   {
     "background": "{{ theme_colors_dark.colors.background.hex }}",
     "foreground": "{{ theme_colors_dark.colors.text_primary.hex }}",
     "accent": "{{ theme_colors_dark.colors.accent.hex }}"
   }
   ```

### Excluding Files from COSMIC Capture

Some COSMIC config files should not be version controlled (like theme mode toggles):

**Edit**: `scripts/capture-cosmic-config.sh`

```bash
rsync -av \
    --exclude='com.system76.CosmicTheme.Dark/v1/is_dark' \
    --exclude='com.system76.CosmicTheme.Mode/v1/is_dark' \
    --exclude='your-excluded-file' \
    "$COSMIC_CONFIG_DIR/" "$DEST_DIR/"
```

This prevents dynamic/system-managed settings from being captured.

## See Also

- [COSMIC Desktop Configuration](cosmic-desktop.md)
- [Scripts Documentation](scripts.md)
