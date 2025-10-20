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
   ```

3. **Configure VSCode**
   - Settings sync via GitHub/Microsoft account
   - Manual configuration in `~/.config/Code/User/settings.json`

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
