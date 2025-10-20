# Version Management Guide

This document explains how software versions are managed, pinned, and updated in the desktoperator system.

## Overview

The system uses a **hybrid version strategy**:

1. **Pinned versions** - Specified in configuration files (reproducible builds)
2. **Latest versions** - Always pull latest (staying current)
3. **Automatic tracking** - GitHub releases tracked with metadata

## Version Strategy Configuration

Located in: `inventory/group_vars/all/versions.yml`

```yaml
---
# Version pinning for packages and tools
# Set version_strategy in settings.yml to control behavior
# - 'latest': Always use latest version (version specs here are ignored)
# - 'pinned': Use versions specified below

# Ansible version (managed via apt from PPA)
ansible_version: "latest"

# Python packages (optional development tools)
python_package_versions:
  ansible-lint: "latest"
  yamllint: "latest"

# Application versions
app_versions:
  code: "latest"
  slack-desktop: "latest"
```

## Software Categories

### 1. GitHub Release Installations

**How it works:**
- Uses `roles/system/tasks/includes/github_release.yml`
- Downloads from GitHub releases
- Tracks metadata in `/var/lib/ansible/github_releases/<org>/<repo>/version.json`
- Automatically checks for updates

**Installed software:**
- just (casey/just)
- helix (helix-editor/helix)
- zellij (zellij-org/zellij)
- And more...

**Metadata stored:**
```json
{
  "tag_name": "v1.43.0",
  "published_at": "2024-10-15T12:00:00Z",
  "html_url": "https://github.com/casey/just/releases/tag/1.43.0"
}
```

**View versions:**
```bash
jsys managed-versions
```

**Example output:**
```
GitHub Release Installations:
─────────────────────────────────────────────────────────
  just                 v1.43.0 (installed: 2024-10-15)
  helix                24.7 (installed: 2024-09-20)
  zellij               v0.43.1 (installed: 2024-10-01)
```

### 2. Pinned Version Software

**How it works:**
- Version specified in role defaults or versions.yml
- Ansible ensures specific version is installed
- Manual update required (change version, re-run Ansible)

**Examples:**

**Go Language** (`roles/system/go/defaults/main.yml`):
```yaml
go_version: "1.25.3"
go_download_url: "https://go.dev/dl/go{{ go_version }}.linux-amd64.tar.gz"
```

**To update Go:**
1. Edit `roles/system/go/defaults/main.yml`
2. Change `go_version: "1.25.3"` to new version
3. Run: `just system` or `jsys update-ansible --tags go`

### 3. Package Manager Software (APT/Flatpak/npm)

**How it works:**
- Usually set to "latest"
- Updated via package manager commands
- Versions controlled by upstream repositories

**Update commands:**
```bash
jsys update-apt        # Update all APT packages
jsys update-flatpak    # Update Flatpak apps
jsys update-npm        # Update global npm packages
jsys update-all        # Update everything
```

## Checking Versions

### Quick Development Tools Check
```bash
jsys versions
```

**Output:**
```
Languages & Runtimes:
  Go:         go version go1.25.3 linux/amd64
  Node:       not installed
  Python:     Python 3.12.0

Development Tools:
  Ansible:    ansible [core 2.18.10]
  Helix:      helix 24.7
  VS Code:    1.95.0
  just:       just 1.43.0

Terminal Tools:
  Zellij:     zellij 0.43.1
  Starship:   starship 1.20.1
  Fish:       fish, version 3.7.1
```

### Full Ansible-Managed Software
```bash
jsys managed-versions
```

**Output:**
```
GitHub Release Installations:
─────────────────────────────────────────────────────────
  just                 v1.43.0 (installed: 2024-10-15)
  helix                24.7 (installed: 2024-09-20)
  zellij               v0.43.1 (installed: 2024-10-01)

Pinned Versions (from versions.yml):
─────────────────────────────────────────────────────────
  Go:         1.25.3
  Ansible:    latest

  Strategy:   See inventory/group_vars/all/versions.yml
```

### Check for Available Updates
```bash
jsys check-updates
```

Runs Ansible in check mode to find what would be updated without making changes.

## Updating Software

### Update Everything
```bash
jsys update-all
```

Runs all update tasks in sequence:
- APT packages
- Flatpak apps
- npm packages
- Go tools
- Ansible-managed configuration

### Update Specific Categories
```bash
jsys update-apt              # Only APT packages
jsys update-flatpak          # Only Flatpak apps
jsys update-npm              # Only npm packages
jsys update-go               # Only Go language servers
jsys update-ansible          # Only Ansible-managed config
jsys update-ansible-tags go  # Only Go (specific tag)
```

### Update Pinned Version Software

**Example: Updating Go**

1. **Check current version:**
   ```bash
   jsys versions | grep Go
   # Go:  go version go1.25.3 linux/amd64
   ```

2. **Check latest version:**
   Visit https://go.dev/VERSION?m=text or:
   ```bash
   curl -s https://go.dev/VERSION?m=text | head -1
   ```

3. **Update configuration:**
   ```bash
   hx roles/system/go/defaults/main.yml
   # Change: go_version: "1.25.3"
   # To:     go_version: "1.26.0"
   ```

4. **Deploy update:**
   ```bash
   jsys update-ansible-tags go
   ```

5. **Verify:**
   ```bash
   jsys versions | grep Go
   # Go:  go version go1.26.0 linux/amd64
   ```

## Version Pinning Strategy

### When to Pin Versions

✅ **DO pin** when:
- Stability is critical
- Known issues with latest version
- Team needs consistent environment
- Reproducible builds required
- Software has breaking changes between versions

❌ **DON'T pin** when:
- Security updates are critical (browsers, system tools)
- Software has rapid release cycle
- Backwards compatibility is strong
- You want latest features

### Current Strategy

**Pinned:**
- Go language (1.25.3)
  - Reason: Stable language server, known compatibility

**Latest:**
- Ansible (from PPA)
  - Reason: Need latest features and security fixes
- APT packages (from Ubuntu repos)
  - Reason: Ubuntu handles compatibility
- GitHub releases (auto-update to latest)
  - Reason: Development tools, want latest features
- Flatpak apps
  - Reason: Sandboxed, safe to auto-update

## Automation

### Automatic Update Checks

Create a cron job or systemd timer:

```bash
# Check for updates daily at 9 AM
0 9 * * * jsys check-updates
```

### Automatic Updates (Use with caution!)

```bash
# Update everything daily at 3 AM
0 3 * * * jsys update-all
```

**Warning:** Only do this if you're comfortable with automatic updates. Test in development first!

## Rollback Procedures

### GitHub Release Software

The Ansible playbook stores version metadata. To rollback:

1. Find the state file:
   ```bash
   sudo cat /var/lib/ansible/github_releases/<org>/<repo>/version.json
   ```

2. Edit your role to pin to specific version:
   ```yaml
   - name: Install just
     include_tasks: roles/system/tasks/includes/github_release.yml
     vars:
       version: "tags/1.42.0"  # Pin to specific version
   ```

3. Re-run Ansible:
   ```bash
   jsys update-ansible-tags <tag>
   ```

### Pinned Version Software

Simply edit the version file and re-run Ansible:

```bash
# Rollback Go from 1.26.0 to 1.25.3
hx roles/system/go/defaults/main.yml
# Change go_version back
jsys update-ansible-tags go
```

### APT Packages

```bash
# Show available versions
apt list -a <package-name>

# Install specific version
sudo apt install <package-name>=<version>

# Hold at current version (prevent updates)
sudo apt-mark hold <package-name>

# Remove hold
sudo apt-mark unhold <package-name>
```

## Best Practices

1. **Document version pins** - Add comments explaining why a version is pinned
2. **Test updates** - Run `jsys check-updates` before `jsys update-all`
3. **Review changes** - Use `jsys update-ansible-check` to preview Ansible changes
4. **Pin conservatively** - Only pin when necessary, default to latest
5. **Update regularly** - Don't let pinned versions get too stale
6. **Track dependencies** - Some tools depend on specific versions of others

## Troubleshooting

### "Version mismatch" errors

If Ansible reports version mismatch:
```bash
# Force reinstall
just system --tags <tag>
```

### Missing version metadata

If metadata is missing from `/var/lib/ansible/github_releases/`:
```bash
# Metadata will be recreated on next run
jsys update-ansible-tags <tag>
```

### Can't find latest version

GitHub API rate limit might be hit:
```bash
# Check rate limit
curl -s https://api.github.com/rate_limit
```

Authenticated requests have higher limits. Add GitHub token to Ansible vault if needed.

## Summary

**Quick Reference:**

| Command | Purpose |
|---------|---------|
| `jsys versions` | Show development tool versions |
| `jsys managed-versions` | Show all Ansible-managed software |
| `jsys check-updates` | Check for available updates |
| `jsys update-all` | Update everything |
| `jsys update-ansible` | Update Ansible-managed config |
| Edit `roles/*/defaults/main.yml` | Change pinned versions |
| Edit `inventory/group_vars/all/versions.yml` | Set version strategy |

**Files to know:**

| File | Purpose |
|------|---------|
| `inventory/group_vars/all/versions.yml` | Global version strategy |
| `roles/system/go/defaults/main.yml` | Go version |
| `/var/lib/ansible/github_releases/` | GitHub release metadata |
| `roles/system/tasks/includes/github_release.yml` | GitHub install logic |
