# Firefox Browser Role

Ansible role for configuring Firefox browser with GNOME-style custom CSS theming.

**Note:** Firefox comes pre-installed with Pop!_OS. This role only manages configuration and custom CSS, not installation.

## Features

- Deploys custom CSS for GNOME-style rounded corners
- Configures vertical tabs support
- Customizes new tab page styling
- Auto-detects Firefox profile directory

## Custom CSS

This role includes custom CSS from [bashfulrobot/firefox-custom-css](https://github.com/bashfulrobot/firefox-custom-css) that provides:

### Visual Design
- 12px window radius with rounded corners
- 8px URL bar with rounded buttons
- Compact toolbar with reduced padding
- GNOME-integrated appearance

### Features
- **Hidden default tab bar** - Maximizes screen space
- **Vertical tabs** - Enabled by default (required when tab bar is hidden)
- **Rounded navigation buttons** - Back, forward, reload, etc.
- **Custom new tab page** - Cleaner dark theme styling
- **Optimized sidebar integration**

## Configuration

### Variables

Defined in `defaults/main.yml`:

```yaml
# Firefox installation state (present/absent)
firefox_state: present

# Enable custom CSS (GNOME-style rounded corners)
firefox_custom_css_enabled: true

# Enable vertical tabs (required when using custom CSS that hides tab bar)
firefox_vertical_tabs_enabled: true

# Firefox profile directory (auto-detected if not set)
firefox_profile_dir: ""
```

### Custom CSS Files

- `files/userChrome.css` - UI customization (rounded corners, hidden tab bar)
- `files/userContent.css` - New tab page styling

## Usage

### Include in Playbook

The role is automatically included when Firefox is in the `common_apps` list or `app_states`:

```yaml
# roles/apps/defaults/main.yml
common_apps:
  - firefox

app_states:
  firefox: present
```

### Run with Tags

```bash
# Configure Firefox custom CSS
just run --tags firefox

# Run full apps role
just run --tags apps
```

### Disable Custom CSS on Specific Hosts

In `host_vars/<hostname>.yml`:

```yaml
# Disable Firefox custom CSS configuration
app_states:
  firefox: absent

# Or just disable custom CSS but keep other settings
firefox_custom_css_enabled: false
```

## Profile Detection

The role automatically finds your Firefox profile directory by searching for:
1. `*.default-release` profiles (modern Firefox)
2. `*.default` profiles (fallback)

You can override this by setting `firefox_profile_dir` in your variables.

## Important Notes

### Vertical Tabs Requirement

The custom CSS **hides the default tab bar**, making tabs invisible unless vertical tabs are enabled. This is handled automatically by the role through the `sidebar.verticalTabs` preference.

### Firefox Preferences

The role creates/modifies `user.js` in your Firefox profile to enable:
- `toolkit.legacyUserProfileCustomizations.stylesheets` - Enables custom CSS
- `sidebar.verticalTabs` - Enables vertical tabs

### First Run

After deployment:
1. Close Firefox completely if it's running
2. Launch Firefox - custom CSS will be applied
3. Vertical tabs will be available in the sidebar

## File Structure

```
roles/apps/firefox/
├── defaults/
│   └── main.yml          # Default variables
├── files/
│   ├── userChrome.css    # UI styling
│   └── userContent.css   # New tab page styling
├── tasks/
│   └── main.yml          # Installation and configuration tasks
└── README.md             # This file
```

## 1Password Integration

Firefox is natively supported by 1Password without requiring custom configuration.

## Customization

### Disable Custom CSS

Set in your variables:

```yaml
firefox_custom_css_enabled: false
```

### Disable Vertical Tabs

Set in your variables:

```yaml
firefox_vertical_tabs_enabled: false
```

Note: Disabling vertical tabs while using the custom CSS is not recommended, as the default tab bar will be hidden.

### Modify CSS

Edit the CSS files in `roles/apps/firefox/files/`:
- Adjust corner radius values
- Customize colors
- Modify button roundness

## License

Custom CSS from [bashfulrobot/firefox-custom-css](https://github.com/bashfulrobot/firefox-custom-css) - MIT License
