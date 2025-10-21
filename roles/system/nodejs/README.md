# Node.js Role

Installs Node.js and npm from the official NodeSource repository.

## Overview

This role installs Node.js using the official NodeSource binary distributions. This ensures you get modern, up-to-date versions of Node.js rather than the outdated versions in Ubuntu's default repositories.

## Installation Method

- **Source**: Official NodeSource repository
- **Package**: `nodejs` (includes npm)
- **Repository**: `https://deb.nodesource.com/`
- **GPG Key**: NodeSource signing key

## Features

- Installs from official NodeSource repository
- Configurable Node.js version (LTS recommended)
- Supports both installation and removal
- Automatic updates via apt
- Clean removal of repository and keys when absent
- Follows Ansible best practices

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nodejs_state` | `present` | Installation state (`present` or `absent`) |
| `nodejs_version` | `22` | Node.js major version (18, 20, 22, etc.) |

## Node.js Versions

Current LTS (Long Term Support) versions:
- **22.x** - Active LTS (recommended)
- **20.x** - Active LTS
- **18.x** - Maintenance LTS

See [NodeSource distributions](https://github.com/nodesource/distributions) for all available versions.

## Dependencies

The role automatically installs required dependencies:
- `ca-certificates` - SSL certificate validation
- `curl` - For downloading packages
- `gnupg` - For GPG key management

## Usage

### Install Node.js

Node.js will be installed automatically when included in the system role.

```bash
just run
# or
just system
```

### Install Node.js Only

```bash
ansible-playbook site.yml --tags nodejs
```

### Check Mode (Dry Run)

```bash
ansible-playbook site.yml --tags nodejs --check --diff
```

### Change Node.js Version

In your inventory or host_vars:

```yaml
nodejs_version: 20  # Use Node.js 20.x LTS
```

### Remove Node.js

In your inventory or host_vars:

```yaml
nodejs_state: absent
```

Then run:

```bash
just system
```

## What Gets Configured

### Installed

When `nodejs_state == 'present'`:
- NodeSource GPG key added to `/etc/apt/keyrings/nodesource.gpg`
- NodeSource repository added to `/etc/apt/sources.list.d/nodesource.list`
- Package `nodejs` installed (includes npm and npx)
- Repository configured for automatic updates

### Removed

When `nodejs_state == 'absent'`:
- Package `nodejs` removed
- NodeSource repository removed
- GPG key removed

## Post-Installation

After installation, you have access to:

1. **Node.js**
   ```bash
   node --version
   ```

2. **npm** (Node Package Manager)
   ```bash
   npm --version
   npm install -g <package>
   ```

3. **npx** (Node Package Runner)
   ```bash
   npx <package>
   ```

## Integration with Desktop Operator

Node.js integrates with other Desktop Operator features:

- **System-wide installation** - Available for all users
- **Automatic updates** - Via apt package manager
- **Version control** - Installation state tracked in inventory
- **Multi-host** - Easy deployment across all machines
- **Language servers** - Required by Helix for yaml-language-server

## Troubleshooting

### NodeSource Repository Not Accessible

Check the NodeSource repository is accessible:
```bash
curl -s https://deb.nodesource.com/node_22.x/dists/nodistro/Release
```

### GPG Key Issues

Manually verify the GPG key:
```bash
curl -s https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor
```

### Repository Not Found

Check repository configuration:
```bash
cat /etc/apt/sources.list.d/nodesource.list
apt-cache policy nodejs
```

### Wrong Version Installed

Verify the version variable:
```bash
grep nodejs_version roles/system/nodejs/defaults/main.yml
```

### Clean Reinstall

```bash
# Set to absent
ansible-playbook site.yml --tags nodejs -e "nodejs_state=absent"

# Set back to present
ansible-playbook site.yml --tags nodejs -e "nodejs_state=present"
```

## References

- [NodeSource Distributions](https://github.com/nodesource/distributions)
- [Node.js Official Website](https://nodejs.org/)
- [Node.js LTS Schedule](https://github.com/nodejs/release#release-schedule)
- [npm Documentation](https://docs.npmjs.com/)

## See Also

- [Go Role](../go/) - Go language support
- [Helix Role](../../apps/helix/) - Uses yaml-language-server via npm
- [System Role Documentation](../README.md) - Overview of all system roles
