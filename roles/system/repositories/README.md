# Ubuntu Restricted Extras Role

Installs ubuntu-restricted-extras package for media codec and font support.

## Features

- ✅ Installs ubuntu-restricted-extras package
- ✅ Automatic EULA acceptance for Microsoft Core Fonts
- ✅ Configurable install/remove state

## What is ubuntu-restricted-extras?

Ubuntu-restricted-extras is a meta-package that installs commonly used media codecs and fonts:

- **Media Codecs**: MP3, MP4, AVI, MPEG-4, and other multimedia formats
- **Microsoft Core Fonts**: Times New Roman, Arial, etc.
- **Flash Plugin**: Adobe Flash (if still needed)
- **DVD Playback**: libdvdread and related libraries
- **RAR Support**: Archive extraction for .rar files

## Variables

### `ubuntu_restricted_extras_state`

Control installation of ubuntu-restricted-extras package:

```yaml
ubuntu_restricted_extras_state: present  # or 'absent'
```

Default: `present`

## Tags

- `repositories` - All tasks in this role
- `repos` - Alias for repositories
- `restricted-extras` - Ubuntu restricted extras
- `apt` - APT-related tasks

## Usage

### Install ubuntu-restricted-extras (default)

```bash
ansible-playbook site.yml --tags restricted-extras
```

### Skip installation

```yaml
# In inventory/host_vars/hostname.yml
ubuntu_restricted_extras_state: absent
```

## Dependencies

None. This role works on both vanilla Ubuntu and Pop!_OS.

## Example Playbook

```yaml
- hosts: all
  roles:
    - role: system/repositories
      vars:
        ubuntu_restricted_extras_state: present
```
