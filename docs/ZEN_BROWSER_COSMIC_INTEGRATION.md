# Zen Browser + COSMIC Desktop Integration

## Overview

This document outlines a future task to integrate Zen Browser's accent color with COSMIC desktop's active window hint color for a cohesive desktop experience.

## Goal

Set Zen Browser's `zen.theme.accent-color` to match COSMIC's active window hint color automatically.

## References

- **Zen Browser Config Flags**: https://docs.zen-browser.app/guides/about-config-flags
- **COSMIC Config Location**: `~/.config/cosmic/`

## Zen Browser Accent Color Setting

**Config Flag**: `zen.theme.accent-color`
**Type**: Hex color value (e.g., `#FF5733`)
**Description**: The color hex value of Zen's main accent color

## Implementation Plan

### Step 1: Locate COSMIC Active Window Hint Color

**TODO**: When COSMIC is installed, inspect `~/.config/cosmic/` to find:
- Which config file contains the active window hint color
- The exact key/path to the color value
- The format of the color value (hex, rgb, etc.)

**Likely locations to check**:
```bash
# List all cosmic config files
ls -la ~/.config/cosmic/

# Search for color-related settings
grep -r "hint" ~/.config/cosmic/
grep -r "active" ~/.config/cosmic/
grep -r "window" ~/.config/cosmic/
grep -r "accent" ~/.config/cosmic/
grep -r "#[0-9a-fA-F]\{6\}" ~/.config/cosmic/  # Search for hex colors
```

**Example file formats to look for**:
- `~/.config/cosmic/com.system76.CosmicComp/v1/theme.ron` (RON format)
- `~/.config/cosmic/theme.toml` (TOML format)
- `~/.config/cosmic/theme.json` (JSON format)

### Step 2: Parse the Color Value

Once the file and key are identified, create an Ansible task to:
1. Read the COSMIC config file
2. Parse the active window hint color value
3. Convert to hex format if needed (e.g., `rgb(255, 87, 51)` → `#FF5733`)

### Step 3: Configure Zen Browser

Create a task to set Zen Browser's accent color via one of these methods:

#### Option A: user.js File (Preferred for Flatpak)

```yaml
- name: Get COSMIC active window hint color
  # TODO: Add parsing logic based on Step 1 findings
  set_fact:
    cosmic_accent_color: "{{ parsed_color_value }}"

- name: Set Zen Browser accent color from COSMIC
  lineinfile:
    path: "{{ user.home }}/.var/app/io.github.zen_browser.zen/config/zen/profiles.ini"
    # NOTE: Need to find the actual profile directory first
    # Then modify: ~/.var/app/io.github.zen_browser.zen/config/zen/PROFILE_DIR/user.js
    line: 'user_pref("zen.theme.accent-color", "{{ cosmic_accent_color }}");'
    create: yes
  when: app_states['zen-browser'] | default('present') == 'present'
```

#### Option B: prefs.js File (More fragile, gets overwritten)

Similar approach but modify `prefs.js` instead (not recommended as browser overwrites this)

#### Option C: policies.json (Enterprise-style, may not work for flatpak)

Create a policies file to set preferences system-wide.

### Step 4: Handle Profile Detection

Zen Browser (like Firefox) uses random profile directories:
```
~/.var/app/io.github.zen_browser.zen/config/zen/
├── profiles.ini
└── abc123de.default/
    ├── prefs.js
    └── user.js
```

**Task**: Parse `profiles.ini` to find the active/default profile directory.

## Implementation Steps for Future

1. **Install COSMIC desktop on a test system**
2. **Inspect COSMIC config files** to find active window hint color
3. **Document the exact file path and key name**
4. **Create Ansible role**: `roles/apps/zen-browser/tasks/cosmic-integration.yml`
5. **Add conditional import** in `roles/apps/zen-browser/tasks/main.yml`:
   ```yaml
   - name: Configure COSMIC integration
     import_tasks: cosmic-integration.yml
     when:
       - app_states['zen-browser'] | default('present') == 'present'
       - cosmic_desktop_installed | default(false)
   ```
6. **Test on system with COSMIC installed**
7. **Add to settings.yml** (optional):
   ```yaml
   zen_browser:
     sync_accent_with_cosmic: true
   ```

## Example COSMIC Config Structure (Hypothetical)

**Hypothetical** `~/.config/cosmic/com.system76.CosmicComp/v1/theme.ron`:
```ron
(
    window: (
        active_hint: Rgb(255, 87, 51),
        inactive_hint: Rgb(128, 128, 128),
        // ... other settings
    ),
)
```

Or **hypothetical** TOML format:
```toml
[window]
active_hint_color = "#FF5733"
inactive_hint_color = "#808080"
```

## Testing Commands

Once implemented, verify with:

```bash
# Check COSMIC color setting
# TODO: Add actual command once file location is known

# Check Zen Browser setting (flatpak)
grep "zen.theme.accent-color" ~/.var/app/io.github.zen_browser.zen/config/zen/*/user.js

# Verify colors match
echo "COSMIC color: $COSMIC_COLOR"
echo "Zen color: $ZEN_COLOR"
```

## Notes

- **Flatpak considerations**: Zen Browser as flatpak stores config in `~/.var/app/io.github.zen_browser.zen/`
- **Native considerations**: Native Zen would use `~/.zen/` or similar
- **Profile management**: Need to handle multiple profiles or detect default
- **Color format conversion**: May need to convert between RGB, hex, or other formats
- **Watch for changes**: Consider using `inotify` or similar to auto-update when COSMIC theme changes

## Alternative Approach: Stylix Integration

If using Stylix/home-manager (which you might be migrating from), could potentially:
1. Use Stylix to manage both COSMIC and Zen Browser themes
2. Set a single accent color that propagates to both
3. Let Stylix handle the color format conversions

## Status

🟡 **Documented - Awaiting COSMIC Installation**

This feature is documented and ready to implement once:
1. COSMIC desktop is installed on the system
2. Config file structure can be inspected
3. Active window hint color location is confirmed

---

**Created**: 2025-01-17
**Last Updated**: 2025-01-17
**Priority**: Low (awaiting COSMIC migration)
**Complexity**: Medium (requires parsing COSMIC config + Firefox profile detection)
