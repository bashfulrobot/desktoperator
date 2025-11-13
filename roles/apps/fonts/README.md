# Fonts Role

Manages system and user font installations with automatic caching.

## Features

- Nerd Fonts installation from GitHub releases
- Direct URL font downloads (FontAwesome, Inter, etc.)
- Google Fonts from Google Fonts repository
- GitHub-hosted fonts from various repositories
- Automatic version tracking and updates
- Comprehensive font cache management

## Font Sources

### Nerd Fonts
Installed from [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) releases.

### Direct URL Fonts
Downloaded from direct URLs (releases or CDN).

### Google Fonts
Downloaded from [google/fonts](https://github.com/google/fonts) repository.

### GitHub Fonts
Downloaded from various GitHub repositories (e.g., SF Pro, Helvetica, Operator Mono Lig).

## Font Caching

The role ensures fonts are properly cached after installation or removal:

1. **System-wide cache**: Updates `/var/cache/fontconfig` for all users
2. **User-specific cache**: Updates `~/.cache/fontconfig` for the configured user
3. **Automatic verification**: Checks that fonts are available in `fc-list` after installation

### Cache Update Triggers

Font caches are automatically rebuilt when:
- Any font is installed or updated
- Any font is removed
- A handler is notified with `"Rebuild font caches"`

### Manual Cache Updates

To manually rebuild font caches:

```bash
# System-wide
sudo fc-cache -f -v

# User-specific
fc-cache -f -v
```

### Using Handlers in Other Roles

Other roles can trigger font cache updates by notifying the handler:

```yaml
- name: Install custom font
  ansible.builtin.copy:
    src: MyCustomFont.ttf
    dest: /usr/local/share/fonts/MyCustomFont.ttf
  notify: "Rebuild font caches"
```

## Adding New Fonts

### Add a Nerd Font

Edit `defaults/main.yml`:

```yaml
nerd_fonts:
  - name: "FontName"
    version: "{{ nerd_fonts_default_version }}"
```

### Add a GitHub Font

Edit `defaults/main.yml`:

```yaml
github_fonts:
  - name: "FontName"
    repo: "user/repo"
    branch: "master"
    base_path: "fonts"  # Optional
    files:
      - "Font-Regular.ttf"
      - "Font-Bold.ttf"
```

### Add a Google Font

Edit `defaults/main.yml`:

```yaml
google_fonts:
  - name: "FontName"
    font_path: "ofl/fontname"
    files:
      - "FontName-Regular.ttf"
      - "FontName-Bold.ttf"
```

## Installed Fonts

### Iosevka Family
- **Iosevka Nerd Font** - Default variant for code editors, narrow and space-efficient
- **IosevkaTerm Nerd Font** - Optimized for terminal emulators with adjusted metrics
  - Both variants include ligatures, extensive stylistic sets, and Nerd Font symbols

### Other Programming Fonts
- **Fira Code Nerd Font** - Popular programming font with comprehensive ligature support
- **JetBrains Mono Nerd Font** - Programming font with ligatures
- **Victor Mono Nerd Font** - Programming font with cursive italics
- **Operator Mono Lig** - Premium programming font with ligatures and beautiful italics

### UI & System Fonts
- **SF Pro** - Apple's San Francisco font family
- **Work Sans** - Geometric sans-serif
- **FontAwesome** - Icon font
- **Inter** - UI font family
- And more...

## Iosevka Variants Explained

Iosevka comes in multiple variants optimized for different use cases:

| Variant | Best For | Spacing | Ligatures | Use Case |
|---------|----------|---------|-----------|----------|
| **Iosevka** | Code editors | Default | Yes (`calt`) | VSCode, Helix (standalone) |
| **IosevkaTerm** | Terminal emulators | Optimized for terminals | Yes (`calt`) | Cosmic Terminal, for Helix in terminal |
| **Iosevka Fixed** | Strict monospace | Tighter | Yes | Special cases |

### Which Variant to Use

- **VSCode**: Use **Iosevka Nerd Font** (Default variant) - optimized for code editors
- **Cosmic Terminal**: Use **IosevkaTerm Nerd Font Mono** - optimized for terminal emulators
- **Helix in Terminal**: Benefits from **IosevkaTerm** via Cosmic Terminal
- **Standalone Helix**: Can use either variant

### Ligature Configuration

Iosevka uses OpenType features for ligatures:
- **`calt`** (default): Enables contextual alternates and standard ligatures
- **`dlig`**: Enables discretionary ligatures (optional, additional)
- **`calt off`**: Disables all ligatures

Most users should keep the default `calt` setting.

## Font Verification

After installation, the role verifies fonts are cached:

```bash
fc-list | grep -i "FontName"
```

This ensures applications can immediately use the newly installed fonts without requiring a logout or reboot.
