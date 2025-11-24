# Goose Role

Installs [Goose](https://github.com/block/goose) - an AI-powered development agent from Block.

## Description

Goose is installed via the official CLI installer method, downloading precompiled binaries from GitHub releases. The binary is installed to `~/.local/bin/goose` and supports self-updates via the `goose update` command.

## Configuration

Default variables in `defaults/main.yml`:

```yaml
# Version to install - update this to upgrade
goose_version: "1.15.0"

# Use latest version from GitHub releases (overrides goose_version)
goose_use_latest: false
```

## Usage

### Install specific version (default)

Set `goose_version` in `defaults/main.yml` to the desired version:

```yaml
goose_version: "1.15.0"
goose_use_latest: false
```

### Install latest version

Set `goose_use_latest` to `true` in `defaults/main.yml` or override in host_vars:

```yaml
goose_use_latest: true
```

This will automatically fetch and install the latest release from GitHub.

## Updating Goose

### Manual version update

1. Check GitHub releases: https://github.com/block/goose/releases
2. Update `goose_version` in `defaults/main.yml`
3. Run the playbook: `ansible-playbook desktop.yml --tags goose`

### Automatic latest version

Set `goose_use_latest: true` and Goose will be updated to the latest release on each playbook run.

## Tags

- `dev` - General development tools tag
- `goose` - Specific to Goose installation

## State Management

Controlled via `app_states['goose']` (defined in `roles/apps/defaults/main.yml`):

- `present` - Install Goose (default)
- `absent` - Remove Goose completely

## Implementation Details

- Downloads precompiled binary archive from GitHub releases
- Extracts to `~/.local/bin/goose`
- Checks installed version using `goose --version`
- Only downloads and installs if version differs
- Cleans up downloaded archive after installation
- Supports both pinned versions and latest tracking
- Supports x86_64 and aarch64 architectures
- User can update manually via `goose update` command

## Self-Updating

Once installed, Goose supports self-updating:

```bash
goose update
```

This allows for quick updates without running the full Ansible playbook.
