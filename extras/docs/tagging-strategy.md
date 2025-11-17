# Ansible Tagging Strategy

This document explains how tags work in this Ansible repository, how to use them for targeted app installation, and how they interact with state management.

## Core Principle

**Tags control WHAT runs, state variables control HOW it runs.**

- **Tags** = Inclusion/exclusion mechanism (use `--tags` or `--skip-tags`)
- **State variables** = Install vs remove logic (`present` or `absent` in `app_states`)
- These concerns are completely decoupled

## Tag Hierarchy

**Tags match folder/file names exactly** - making them easy to discover and maintain.

### Visual Hierarchy

Use `just tags-tree` or `tree roles/ -d -L 2` to see the complete tag structure:

```
roles/
├── apps/              # Tag: apps (user applications)
│   ├── pake-builder/       # Tool: pake-builder
│   ├── pake-apps/          # Group: pake-apps (16 generated apps)
│   │   ├── br-email-pake/  # Specific: br-email-pake
│   │   └── github-pake/    # Specific: github-pake
│   ├── brave-builder/      # Tool: brave-builder
│   ├── brave-apps/         # Group: brave-apps (18 generated apps)
│   │   ├── br-email-brave/ # Specific: br-email-brave
│   │   └── github-brave/   # Specific: github-brave
│   ├── slack/              # Specific: slack
│   └── vscode/             # Specific: vscode
├── dev/               # Tag: dev (development tools)
│   ├── python/             # Specific: python
│   ├── git/                # Specific: git
│   ├── nodejs/             # Specific: nodejs, node, npm
│   ├── go/                 # Specific: go, golang
│   ├── helix/              # Specific: helix
│   ├── claude-code/        # Specific: claude-code
│   └── sitemcp/            # Specific: sitemcp
├── infra/             # Tag: infra (infrastructure tools)
│   ├── ansible/            # Specific: ansible
│   ├── docker/             # Specific: docker, containers
│   └── k8s/                # Specific: k8s, kubernetes
├── kong/              # Tag: kong (Kong & collaboration)
│   ├── slack/              # Specific: slack
│   ├── teams-for-linux/    # Specific: teams-for-linux, teams
│   ├── kong-cli/           # Specific: kong-cli, deck, kongctl
│   ├── insomnia/           # Specific: insomnia
│   └── instruqt-cli/       # Specific: instruqt-cli
├── desktop/           # Tag: desktop (desktop environment)
│   └── cosmic/             # Specific: cosmic
└── system/            # Tag: system (core system config)
    ├── fonts/              # Specific: fonts
    ├── iac/                # Specific: iac, terraform, gcloud
    ├── justfile/           # Specific: justfile
    └── libvirt/            # Specific: libvirt, virt
```

### Tier 1: Organizational Roles (Broad Scope)

Defined in `site.yml` - run entire categories:

```yaml
- role: apps
  tags: [apps]      # ALL user applications

- role: dev
  tags: [dev]       # ALL development tools

- role: infra
  tags: [infra]     # ALL infrastructure tools

- role: kong
  tags: [kong]      # ALL kong-related tools

- role: desktop
  tags: [desktop]   # Desktop environment

- role: system
  tags: [system]    # Core system config
```

### Tier 2: Sub-roles & Groups (Medium Scope)

Sub-roles and grouped apps within organizational folders:

```yaml
# Development tools (in dev/)
- include_role: {name: dev/python}
  tags: [dev, python]

- include_role: {name: dev/git}
  tags: [dev, git]

# Infrastructure tools (in infra/)
- include_role: {name: infra/docker}
  tags: [infra, docker]

# Generated app groups (in apps/)
- import_role: {name: apps/pake-apps/br-email-pake}
  tags: [pake-apps, br-email-pake]  # Both group and specific tags

- import_role: {name: apps/brave-apps/br-email-brave}
  tags: [brave-apps, br-email-brave]
```

### Tier 3: Specific Items (Targeted Scope)

Individual apps, tools, or configurations:

```yaml
# Individual apps
just tag slack             # Just Slack
just tag vscode            # Just VS Code

# Individual dev tools
just tag python            # Just Python
just tag git               # Just Git

# Individual infra tools
just tag docker            # Just Docker
just tag k8s               # Just Kubernetes tools

# Specific generated apps
just tag br-email-pake     # Just pake version of br-email
just tag br-email-brave    # Just brave version of br-email
```

### Tag Naming Rules

1. **Tags match folder/file names exactly**
   - Folder `roles/dev/python/` → tag `python`
   - Folder `roles/apps/pake-apps/br-email-pake/` → tag `br-email-pake`
   - File `roles/system/tasks/firewall.yml` → tag `firewall`

2. **Builder vs Generated Apps**
   - `pake-builder` = CLI tool to create pake apps
   - `pake-apps` = Group tag for all generated pake apps
   - `brave-builder` = CLI tool to create brave apps
   - `brave-apps` = Group tag for all generated brave apps

3. **Hierarchical Tags**
   - Broad: `dev` runs ALL dev tools
   - Medium: `pake-apps` runs ALL pake apps
   - Specific: `python` runs just Python

4. **Aliases**
   - Some tools have convenience aliases (e.g., `node` → `nodejs`, `golang` → `go`)
   - Salesforce apps: `salesforce` alias for `sfdc-pake` and `sfdc-brave`

## State Management

**File:** `roles/apps/defaults/main.yml`

```yaml
app_states:
  # Explicitly absent apps
  vivaldi: absent

  # Explicitly present apps
  slack: present
  vscode: present
  br-email: present

  # Apps not listed default to 'present' via | default('present')
```

**Host-specific overrides:** Use `inventory/host_vars/<hostname>.yml`

## Discovering Tags

**Quick reference:**
```bash
just tags-tree          # Visual hierarchy using tree command
just tags               # Flat list of all tags
tree roles/ -d -L 2     # See folder structure = tag names
```

## Usage Examples

### Install Single App

Run a complete app installation (install + config + icons):

```bash
ansible-playbook site.yml --tags slack
ansible-playbook site.yml --tags vscode
ansible-playbook site.yml --tags br-email-pake  # Tag matches folder name
```

### Install Multiple Specific Apps

```bash
ansible-playbook site.yml --tags "slack,vscode,firefox"
```

### Install All Apps

```bash
ansible-playbook site.yml --tags apps
```

### Exclude Specific Apps

```bash
# Install all apps except zoom and vivaldi
ansible-playbook site.yml --tags apps --skip-tags "zoom,vivaldi"
```

### Run Core System Only (Skip Apps)

```bash
ansible-playbook site.yml --skip-tags apps
```

### Run Everything

```bash
ansible-playbook site.yml
```

### With Vault Password

```bash
ansible-playbook site.yml --tags slack --ask-vault-pass
```

### Target Specific Host

```bash
ansible-playbook site.yml --tags vscode --limit qbert
```

## State-Based Installation/Removal

### Remove an App

1. Set state to `absent` in `roles/apps/defaults/main.yml`:
   ```yaml
   app_states:
     slack: absent
   ```

2. Run playbook with the app tag:
   ```bash
   ansible-playbook site.yml --tags slack
   ```

The app's removal tasks will run instead of installation tasks.

### Host-Specific States

Override app states per host in `inventory/host_vars/<hostname>.yml`:

```yaml
# inventory/host_vars/qbert.yml
app_states:
  zoom: absent          # Don't install zoom on qbert
  vscode: present       # Explicitly ensure vscode on qbert
```

## How It Works

### Import Pattern (Decoupled)

**File:** `roles/apps/tasks/main.yml`

```yaml
- name: Include Slack
  import_role:
    name: apps/slack
  tags: [slack]
  # NO when condition - tags control what runs
```

### Role Task Pattern (State-Aware)

**File:** `roles/apps/slack/tasks/main.yml`

```yaml
# Installation tasks
- name: Install Slack
  apt:
    deb: "/tmp/slack.deb"
    state: present
  when: app_states['slack'] | default('present') == 'present'

# Removal tasks
- name: Remove Slack
  apt:
    name: slack-desktop
    state: absent
  when: app_states['slack'] | default('present') == 'absent'
```

**Key Points:**
- No `when` conditions on `import_role` statements
- State checks inside role tasks: `app_states['app'] | default('present')`
- Default to `'present'` so tag-based runs work by default

## Reinstalling Packages (Force Reinstall)

### The Reinstall Tag

Some packages (like Pake apps) don't include version numbers in their filenames, which means Ansible can't detect when they've been updated. For these cases, we've implemented a `reinstall` tag that forces a clean reinstall.

**How it works:**
- Tasks tagged with `["never", "reinstall"]` only run when explicitly requested
- The uninstall task removes the package
- The install task (tagged with `["always"]`) then installs the updated package
- During normal runs, the uninstall is skipped and install only runs if package is missing

### Usage

**Force reinstall of a single Pake app:**
```bash
ansible-playbook site.yml --tags reinstall,br-email
```

**Force reinstall of multiple Pake apps:**
```bash
ansible-playbook site.yml --tags reinstall,br-email,github,asana
```

**Typical workflow after regenerating a .deb file:**
```bash
# 1. Regenerate the .deb file with updated content
create-web-app https://github.com GitHub

# 2. Force reinstall on target machine
ansible-playbook site.yml --tags reinstall,github
```

### Which Apps Support Reinstall?

Currently implemented for:
- **All Pake apps** (br-email, github, asana, sfdc, etc.)
- Any app role that includes tasks tagged with `["never", "reinstall"]`

### Implementation Details

Each Pake app role includes these tasks:

```yaml
# Uninstall task - only runs with --tags reinstall
- name: Uninstall app-name for reinstall
  apt:
    name: app-name
    state: absent
  become: true
  when: app_states['app-name'] | default('present') == 'present'
  tags: ["never", "reinstall"]

# Install task - always runs when included
- name: Install app-name .deb package
  apt:
    deb: "{{ role_path }}/files/app-name.deb"
    state: present
  become: true
  when: app_states['app-name'] | default('present') == 'present'
  tags: ["always"]
```

**Tag behavior:**
- `never` = Skip this task unless explicitly requested
- `reinstall` = Run when `--tags reinstall` is specified
- `always` = Run even during tag-filtered runs

## Pake Apps (Web-to-Desktop Framework)

Pake is just a framework for converting web apps to desktop apps. Tags use app names, not the framework:

```bash
# Correct (app name)
ansible-playbook site.yml --tags br-email
ansible-playbook site.yml --tags github
ansible-playbook site.yml --tags asana

# Wrong (don't include framework suffix)
ansible-playbook site.yml --tags br-email-pake  # ❌
```

**Available Pake Apps:**
- github, asana, avanti
- sfdc, salesforce (aliases)
- lucid-chart, lucidchart (aliases)
- br-email, kong-email
- br-calendar, kong-calendar
- br-drive, kong-drive
- aha, workday, konnect

## Flatpak Apps

Flatpak apps are now individual roles (not a loop), so they work exactly like other apps:

```bash
ansible-playbook site.yml --tags todoist
ansible-playbook site.yml --tags obsidian
ansible-playbook site.yml --tags kooha
```

## Complete App List

Run this to see all available app tags:

```bash
ansible-playbook site.yml --list-tags | grep apps/
```

Or view `roles/apps/tasks/main.yml` directly.

## Testing and Validation

### List Tasks Without Running

```bash
# See what would run
ansible-playbook site.yml --tags slack --list-tasks

# See all tasks with specific tag
ansible-playbook site.yml --tags vscode --list-tasks
```

### Dry Run (Check Mode)

```bash
# See what would change without actually changing it
ansible-playbook site.yml --tags slack --check --diff
```

### Syntax Validation

```bash
ansible-playbook site.yml --syntax-check
```

## Benefits of This Approach

1. **Consistency:** ALL apps can be targeted individually (including flatpaks)
2. **Predictability:** `--tags appname` always installs complete app + config
3. **Flexibility:** Mix and match apps, categories, exclusions
4. **Speed:** Target only what you need, skip unnecessary role processing
5. **Simplicity:** Tags = what runs, state = how it runs (decoupled)
6. **Self-Contained:** Each role runs in its entirety with full access to:
   - Global variables (`group_vars/all/`)
   - Vault secrets (`group_vars/all/vault.yml`)
   - Host-specific vars (`host_vars/`)
   - Sudo/become (controlled by task's `become: true`)

## Common Patterns

### New Machine Setup (Core Only)

```bash
# Bootstrap + core system + desktop
ansible-playbook site.yml --tags core
```

### Add Specific Apps to Existing Machine

```bash
# Just install slack and vscode
ansible-playbook site.yml --tags "slack,vscode"
```

### Update Specific App After Code Change

```bash
# Re-run just the app you modified
ansible-playbook site.yml --tags br-email
```

### Full System Reconfiguration

```bash
# Run everything
ansible-playbook site.yml
```

### Development Workflow

```bash
# Test single app changes
ansible-playbook site.yml --tags myapp --check --diff

# Apply if looks good
ansible-playbook site.yml --tags myapp
```

## Troubleshooting

### Tag Not Working

1. Verify tag exists:
   ```bash
   ansible-playbook site.yml --list-tags | grep "br-email"
   ```

2. Check if role has tasks:
   ```bash
   ansible-playbook site.yml --tags br-email --list-tasks
   ```

3. Validate syntax:
   ```bash
   ansible-playbook site.yml --syntax-check
   ```

### App Not Installing/Removing

1. Check app state in defaults:
   ```bash
   grep "br-email" roles/apps/defaults/main.yml
   ```

2. Check host-specific overrides:
   ```bash
   cat inventory/host_vars/$(hostname).yml | grep "br-email"
   ```

3. Run in verbose mode:
   ```bash
   ansible-playbook site.yml --tags br-email -v
   ```

### Need to See What Changed

```bash
# Use check mode with diff
ansible-playbook site.yml --tags slack --check --diff
```

## See Also

- [Ansible Architecture](ansible-architecture.md) - Overall repository structure
- [Getting Started](getting-started.md) - Initial setup guide
- [Vault Key Management](vault-key-management.md) - Working with secrets
