# XDG File Associations Role

Manages default applications for file types using XDG MIME type associations on Linux desktops.

## Overview

This role configures which applications open specific file types by managing XDG MIME type associations. It creates and maintains the `~/.config/mimeapps.list` file and custom MIME type definitions.

## Features

- Sets default applications for file types using XDG standards
- Manages custom MIME types for file extensions not in the system database
- Configures both Markdown and code/config file associations
- Validates that required desktop files exist

## Default Associations

### Markdown Files → Typora
- `.md` files (text/markdown, text/x-markdown)

### Code/Config Files → VS Code
- **Shell scripts**: `.sh`
- **YAML**: `.yml`, `.yaml`
- **JSON**: `.json`
- **TOML**: `.toml`
- **Fish shell**: `.fish`
- **JavaScript/TypeScript**: `.js`, `.ts`, `.jsx`, `.tsx`
- **Go**: `.go`
- **Nix**: `.nix`
- **Python**: `.py`
- **Rust**: `.rs`
- **Ruby**: `.rb`
- **C/C++**: `.c`, `.h`, `.cpp`, `.hpp`, `.cc`, `.cxx`
- **C#**: `.cs`
- **Java**: `.java`
- **PHP**: `.php`
- **Lua**: `.lua`
- **Perl**: `.pl`
- **PowerShell**: `.ps1`
- **Terraform/HCL**: `.tf`, `.tfvars`, `.hcl`
- **Docker**: `Dockerfile`
- **Makefiles**: `Makefile`
- **CSS**: `.css`
- **Jinja2 templates**: `.j2`
- **Desktop files**: `.desktop`
- **Git config**: `.gitignore`, `.gitattributes`
- **Ansible lint**: `.ansible-lint`
- **Config files**: `.ini`, `.cfg`, `.conf`
- **Text files**: `.txt`
- **Plain text** (no extension)

### Browser-Based Files → Brave
- HTML files: `.html`, `.htm`, `.xhtml`
- XML files: `.xml`
- SVG files: `.svg`
- Web images: `.webp`
- Web archives: `.mhtml`
- URL handlers: `http://`, `https://`, `ftp://`

### PDF Files → Okular
- PDF documents: `.pdf`

### Video Files → VLC
- `.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.mpg`, `.mpeg`, `.3gp`, `.ogv`, `.ts`

### Archive Files → File Roller
- `.zip`, `.tar`, `.tar.gz`, `.tgz`, `.tar.bz2`, `.tar.xz`, `.7z`, `.rar`, `.deb`, `.rpm`

## Requirements

- Typora installed with desktop file at `/usr/share/applications/typora.desktop`
- VS Code installed with desktop file at `/usr/share/applications/code.desktop`
- Brave browser installed with desktop file at `/usr/share/applications/brave-browser.desktop`
- Okular installed with desktop file at `/usr/share/applications/org.kde.okular.desktop`
- VLC installed with desktop file at `/usr/share/applications/vlc.desktop` (installed by `system/vlc` role)
- File Roller installed with desktop file at `/usr/share/applications/org.gnome.FileRoller.desktop` (installed as core package)
- `xdg-utils` package for `xdg-mime` command
- `update-mime-database` and `update-desktop-database` commands

## Configuration

### Changing Default Applications

Application preferences are defined in **`inventory/group_vars/all/settings.yml`**.

Edit that file to switch default applications:

```yaml
# inventory/group_vars/all/settings.yml
xdg_preferred_apps:
  markdown_editor: typora.desktop          # Change to code.desktop, ghostwriter.desktop, etc.
  code_editor: code.desktop                # Change to helix.desktop, nvim.desktop, etc.
  web_browser: brave-browser.desktop       # Change to google-chrome.desktop, firefox.desktop, etc.
  pdf_viewer: org.kde.okular.desktop       # Change to evince.desktop, etc.
  video_player: vlc.desktop                # Change to mpv.desktop, org.gnome.Totem.desktop, etc.
  archive_manager: org.gnome.FileRoller.desktop  # Change to org.kde.ark.desktop, xarchiver.desktop, etc.
```

**Example:** To switch from Brave to Chrome globally:
```yaml
# Edit inventory/group_vars/all/settings.yml
xdg_preferred_apps:
  web_browser: google-chrome.desktop
```

**Example:** To switch from VS Code to Helix for a specific host:
```yaml
# Create inventory/host_vars/myhost.yml
xdg_preferred_apps:
  code_editor: helix.desktop
```

**Example:** To override for a specific group:
```yaml
# Create inventory/group_vars/developers/settings.yml
xdg_preferred_apps:
  code_editor: helix.desktop
  web_browser: firefox.desktop
```

### Adding New File Type Associations

To add new file type associations, edit the role's `defaults/main.yml`:

**Add new application category:**
```yaml
# roles/system/xdg-associations/defaults/main.yml
xdg_associations:
  my_app:
    desktop_file: myapp.desktop
    mime_types:
      - application/x-custom
      - text/x-custom
```

**Add custom MIME types:**
```yaml
# roles/system/xdg-associations/defaults/main.yml
xdg_custom_mime_types:
  - extension: .custom
    mime_type: application/x-custom
```

## Files Generated

- `~/.config/mimeapps.list` - Default application associations
- `~/.local/share/mime/packages/custom-file-types.xml` - Custom MIME type definitions

## Testing

After running the role, verify associations:

```bash
# Check MIME type for a file
xdg-mime query filetype file.md

# Check default application for a MIME type
xdg-mime query default text/markdown

# Open a file with default application
xdg-open test.md
```

## Dependencies

None - this is a standalone role.

## Tags

None currently defined.

## Variables

See `defaults/main.yml` for all available variables.

## Notes

- Changes are applied per-user based on the `user.name` variable
- The role verifies that required desktop files exist but does not fail if missing
- MIME database is updated only when custom MIME types change
- Desktop database is updated when mimeapps.list changes
