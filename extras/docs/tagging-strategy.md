# Ansible Tagging Strategy

This document explains how tags work in this Ansible repository, how to use them for targeted app installation, and how they interact with state management.

## Core Principle

**Tags control WHAT runs, state variables control HOW it runs.**

- **Tags** = Inclusion/exclusion mechanism (use `--tags` or `--skip-tags`)
- **State variables** = Install vs remove logic (`present` or `absent` in `app_states`)
- These concerns are completely decoupled

## Tag Hierarchy

### Tier 1: Role-Level Tags (Broad Categories)

Defined in `site.yml` for entire roles:

```yaml
- role: apps
  tags: [apps]
- role: system
  tags: [system, core]
- role: desktop
  tags: [desktop, core]
```

### Tier 2: App-Level Tags (Individual Apps)

Defined in `roles/apps/tasks/main.yml` for each app:

```yaml
- import_role: {name: apps/slack}
  tags: [slack]

- import_role: {name: apps/vscode}
  tags: [vscode]

- import_role: {name: apps/br-email-pake}
  tags: [br-email]
```

**Tag Naming Rules:**
- Primary tag = app name (lowercase, hyphenated)
- No framework suffixes (e.g., `br-email` not `br-email-pake`)
- Aliases where useful (e.g., `salesforce` and `sfdc` both work)
- No category tags (removed: communication, browser, ai, etc.)

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

## Usage Examples

### Install Single App

Run a complete app installation (install + config + icons):

```bash
ansible-playbook site.yml --tags br-email
ansible-playbook site.yml --tags slack
ansible-playbook site.yml --tags vscode
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
   - Sudo/become (controlled by task's `become: yes`)

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
