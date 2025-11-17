# VLC Media Player Role

Installs and configures VLC media player with DVD playback support.

## Overview

This role installs VLC media player along with necessary plugins and DVD playback support (libdvdcss2) for playing encrypted DVDs.

## Features

- Installs VLC media player with plugins
- Configures DVD playback support (libdvd-pkg/libdvdcss2)
- Verifies VLC installation
- Supports removal/cleanup

## DVD Playback Support

This role automatically configures DVD playback by:
1. Installing `libdvd-pkg`
2. Running `dpkg-reconfigure libdvd-pkg` to download and install libdvdcss2
3. This enables playback of encrypted commercial DVDs

Reference: https://help.ubuntu.com/community/RestrictedFormats/PlayingDVDs

## Configuration

Edit `defaults/main.yml` to customize:

### Disable DVD Support

```yaml
vlc_dvd_support: false
```

### Remove VLC

```yaml
vlc_state: absent
```

## Requirements

- Ubuntu/Debian-based system
- Internet connection (for libdvdcss2 download during DVD configuration)

## Variables

See `defaults/main.yml` for all available variables.

## Tags

Use with system tags:
```bash
ansible-playbook site.yml --tags vlc
ansible-playbook site.yml --tags media
```

## Dependencies

None - this is a standalone role.
