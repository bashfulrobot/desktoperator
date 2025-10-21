# Gemini CLI Role

Installs the Gemini CLI from the official npm registry.

## Overview

This role installs the `@google/gemini-cli` package globally using npm. This ensures you always have the latest version available in your system's PATH.

## Installation Method

- **Source**: Official npm registry
- **Package**: `@google/gemini-cli`

## Features

- Installs from the official npm registry
- Supports both installation and removal
- Follows Ansible best practices

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `app_states['gemini-cli']` | `present` | Installation state (`present` or `absent`) |

## Dependencies

The role requires `npm` to be installed on the target system.

## Usage

### Install Gemini CLI

To include Gemini CLI in your setup, add it to your `common_apps` list in `roles/apps/defaults/main.yml`:

```yaml
common_apps:
  - gemini-cli

app_states:
  gemini-cli: present
```

Then run:

```bash
just run
# or
just apps
```

### Install Gemini CLI Only

```bash
just app gemini-cli
# or
ansible-playbook site.yml --tags gemini-cli
```

### Remove Gemini CLI

In your inventory or host_vars:

```yaml
app_states:
  gemini-cli: absent
```

Then run:

```bash
just apps
```

## Tags

- `gemini-cli` - Run only Gemini CLI tasks
- `cli-tool` - Run all CLI tool related tasks
- `apps` - Run all application tasks
