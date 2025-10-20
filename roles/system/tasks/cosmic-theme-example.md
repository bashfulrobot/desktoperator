# Using COSMIC Theme Colors in Other Roles

After the `cosmic-theme.yml` tasks run, the `theme_colors` variable is available to all subsequent roles.

## Available in Ansible as Variable

Colors are extracted in-memory during each Ansible run (not persisted to disk).

The `theme_colors` fact contains the parsed JSON:

```yaml
theme_colors:
  metadata:
    name: "cosmic-dark"  # or "cosmic-light"
    mode: "Dark"         # or "Light"
    is_dark: true        # or false
    generated: "2025-10-19 23:56:54"
  colors:
    accent:
      hex: "#63d0df"
      rgb:
        string: "rgb(99, 208, 223)"
        r: 99
        g: 208
        b: 223
      # ... hsl, hsv, cmyk, rgba
    success: { ... }
    warning: { ... }
    destructive: { ... }
    background: { ... }
    primary: { ... }
    secondary: { ... }
```

## Usage Examples

### Example 1: Use accent color in a template

**Template:** `roles/myapp/templates/config.j2`
```css
.accent {
  color: {{ theme_colors.colors.accent.hex }};
  background: {{ theme_colors.colors.background.hex }};
}
```

### Example 2: Conditional logic based on theme mode

```yaml
- name: Configure dark mode
  template:
    src: "{{ 'dark.conf.j2' if theme_colors.metadata.is_dark else 'light.conf.j2' }}"
    dest: "{{ user.home }}/.config/myapp/theme.conf"
```

### Example 3: Use specific color format

```yaml
- name: Set terminal colors
  template:
    src: terminal.j2
    dest: "{{ user.home }}/.config/terminal/colors.conf"
  vars:
    # RGB values for terminal emulator
    accent_r: "{{ theme_colors.colors.accent.rgb.r }}"
    accent_g: "{{ theme_colors.colors.accent.rgb.g }}"
    accent_b: "{{ theme_colors.colors.accent.rgb.b }}"
```

### Example 4: Generate app-specific color scheme

```yaml
- name: Create application color palette
  copy:
    content: |
      # Generated from COSMIC theme: {{ theme_colors.metadata.name }}
      PRIMARY={{ theme_colors.colors.accent.hex }}
      SUCCESS={{ theme_colors.colors.success.hex }}
      WARNING={{ theme_colors.colors.warning.hex }}
      ERROR={{ theme_colors.colors.destructive.hex }}
      BG={{ theme_colors.colors.background.hex }}
    dest: "{{ user.home }}/.config/myapp/colors.env"
```

## Manual Color Inspection

The script is installed system-wide for manual inspection:

```bash
# View all colors in JSON format
extract-cosmic-colors | jq '.'

# Get specific color
extract-cosmic-colors | jq -r '.colors.accent.hex'

# Save to file if needed for external tools
extract-cosmic-colors > /tmp/theme-colors.json
```
