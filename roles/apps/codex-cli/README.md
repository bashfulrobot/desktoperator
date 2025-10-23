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
