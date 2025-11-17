# Codex CLI Role

Installs the Codex CLI from the official npm registry.

## Overview

This role installs the `@openai/codex` package globally using npm so that the Codex CLI is available system-wide for automation and local workflows.

## Installation Method

- **Source**: Official npm registry
- **Package**: `@openai/codex`

## Features

- Installs from the official npm registry
- Supports both installation and removal
- Mirrors existing npm CLI patterns in this repository
- Configures Codex MCP servers pointing at SiteMCP-backed Kong documentation caches

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `app_states['codex-cli']` | `present` | Installation state (`present` or `absent`) |

## Dependencies

Requires Node.js and npm to be installed (handled by `roles/system/nodejs`).

## Usage

### Install Codex CLI

Ensure Codex CLI is included in `common_apps` or explicitly set in `app_states`:

```yaml
common_apps:
  - codex-cli

app_states:
  codex-cli: present
```

Then run:

```bash
just run
# or
just apps
```

### Install Codex CLI Only

```bash
just app codex-cli
# or
ansible-playbook site.yml --tags codex-cli
```

## Custom Commands

The role deploys custom slash commands to `~/.codex/prompts/`:

### `/prompts:commit`

Create conventional commits with emoji and optional push, tagging, or GitHub releases.

**Arguments:**
- `--push`: Push to remote repository after committing
- `--tag <level>`: Create semantic version tag (major|minor|patch)
- `--release`: Create GitHub release after tagging (requires --tag)
- `--pr`: Create a pull request after pushing (requires --push)

**Example usage:**
```bash
# Basic commit
codex /prompts:commit

# Commit and push
codex /prompts:commit --push

# Commit, tag, and create GitHub release
codex /prompts:commit --push --tag minor --release

# Commit, push, and create PR
codex /prompts:commit --push --pr
```

The commit command:
- Enforces conventional commit format with emojis
- GPG signs all commits
- Supports atomic commits for unrelated changes
- Integrates with Copilot CLI for GitHub operations
- Can invoke Claude or Copilot for peer review on complex changes

## MCP Servers

The role provisions `~/.codex/config.toml` so Codex automatically connects to a fleet
of SiteMCP servers that mirror critical Kong documentation sets. The server list
is sourced from `roles/apps/codex-cli/files/mcp-sites.json`, which is referenced by
both the Ansible template and `scripts/mcp-cache-update.sh` to keep cached content
and Codex launch configuration synchronized. Update that JSON file to add or remove
targets, then rerun the role after refreshing caches with the script.

### Automated Cache Updates

The role deploys a systemd user timer that automatically refreshes MCP site caches
daily at 9:00 AM. This ensures documentation remains current without manual intervention.

#### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `codex_cli_cache_update_enabled` | `true` | Enable/disable automated cache updates |
| `codex_cli_cache_timer_wake_system` | `false` | Wake system from suspend for updates (requires hardware support) |

#### Manual Cache Updates

Update caches manually using the helper script:

```bash
# Interactive mode (select specific sites)
./scripts/mcp-cache-update.sh

# Update all configured sites non-interactively
./scripts/mcp-cache-update.sh --all

# Update specific sites
./scripts/mcp-cache-update.sh "https://example.com/docs" "https://other.com/api"
```

#### Monitoring

Cache update logs are written to:
- **Journal**: `journalctl --user -u mcp-cache-update.service`
- **File**: `/var/log/mcp-cache/mcp-cache.log`

Check timer status:
```bash
systemctl --user status mcp-cache-update.timer
systemctl --user list-timers mcp-cache-update.timer
```

### Remove Codex CLI

```yaml
app_states:
  codex-cli: absent
```

Then run:

```bash
just apps
```

## Tags

- `codex-cli` - Run only Codex CLI tasks
- `cli-tool` - Run all CLI tool related tasks
- `apps` - Run all application tasks
