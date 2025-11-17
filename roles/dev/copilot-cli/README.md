# GitHub Copilot CLI Role

Installs the GitHub Copilot CLI from the official npm registry.

## Overview

This role installs the `@github/copilot` package globally using npm. The GitHub Copilot CLI is an AI-powered terminal tool that brings GitHub's Copilot coding agent directly to your command line.

## Installation Method

- **Source**: Official npm registry
- **Package**: `@github/copilot`

## Features

- Terminal-native development with AI assistance
- GitHub integration for repositories, issues, and pull requests
- Agentic capabilities for planning and executing complex coding tasks
- MCP server support for extending functionality
- Preview-before-execution for all actions

## Requirements

- Node.js 22 or higher
- npm 10 or higher
- Active Copilot subscription

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `app_states['copilot-cli']` | `present` | Installation state (`present` or `absent`) |

## Dependencies

The role requires `npm` to be installed on the target system.

## Usage

### Install Copilot CLI

To include Copilot CLI in your setup, add it to your `common_apps` list in `roles/apps/defaults/main.yml`:

```yaml
common_apps:
  - copilot-cli

app_states:
  copilot-cli: present
```

Then run:

```bash
just run
# or
just apps
```

### Install Copilot CLI Only

```bash
just app copilot-cli
# or
ansible-playbook site.yml --tags copilot-cli
```

### Remove Copilot CLI

In your inventory or host_vars:

```yaml
app_states:
  copilot-cli: absent
```

Then run:

```bash
just apps
```

## Authentication

After installation, you'll need to authenticate:

1. **Interactive login**: Use the `/login` command within the CLI
2. **Personal Access Token**: Create a fine-grained PAT with "Copilot Requests" permission and set it via `GH_TOKEN` or `GITHUB_TOKEN` environment variable

## Tags

- `copilot-cli` - Run only Copilot CLI tasks
- `cli-tool` - Run all CLI tool related tasks
- `apps` - Run all application tasks
