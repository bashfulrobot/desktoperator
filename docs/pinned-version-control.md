# Pinned Version Control - Design Plan

## Problem Statement

Currently, any software requiring **remote version checks** (GitHub releases, direct downloads, web scraping, etc.) operates without explicit version control. This includes:

- **GitHub Releases**: Checks API on every run
- **Direct Downloads**: Scrapes version from websites
- **Custom Binaries**: Downloads "latest" from URLs
- **AppImages**: Pulls newest version automatically
- **Standalone Installers**: Fetches current release

This approach has several issues:

1. **External Dependencies**: Every Ansible run requires internet connectivity and external API access
2. **API Rate Limits**: GitHub API (60/hour unauthenticated), other services have similar limits
3. **Unpredictable Updates**: Software updates automatically without explicit version control
4. **No Version History**: Can't see what version was previously installed or why it changed
5. **Lack of Control**: Updates happen implicitly rather than explicitly
6. **No Auditability**: Can't track when/why versions changed
7. **Network Failures**: Ansible fails if remote source is unavailable
8. **Inconsistent State**: Different machines might get different "latest" versions at different times

## Proposed Solution

**Pin all non-package-manager software explicitly in a central versions file**, similar to how Go is pinned. Only update when explicitly requested via a dedicated command.

### Core Principles

1. **Explicit over Implicit**: Versions only change when explicitly requested
2. **Central Version File**: Single source of truth for all pinned versions
3. **Version History**: Track current, previous, and available versions
4. **Opt-in Updates**: Dedicated command to check for and apply updates
5. **Auditability**: Git history shows exactly when/why versions changed

## Architecture

### Version Control File

**Location**: `inventory/group_vars/all/pinned_versions.yml`

**Structure**:
```yaml
---
# Pinned software versions
# Managed installations that don't use package managers
#
# Version tracking:
# - current: Currently deployed version (what Ansible installs)
# - previous: Last known previous version (for rollback reference)
# - available: Latest available version (updated via jsys check-versions)
# - source: Where to get the software (github, direct-download, etc.)
# - last_checked: When we last checked for updates (ISO 8601 timestamp)
# - last_updated: When the version was last changed (ISO 8601 timestamp)

pinned_software:
  # Development Tools
  just:
    current: "1.43.0"
    previous: "1.42.0"
    available: "1.43.0"
    source:
      type: github
      org: casey
      repo: just
      asset_pattern: "x86_64-unknown-linux-musl.tar.gz"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-09-27T10:00:00Z"

  helix:
    current: "24.7"
    previous: "24.6"
    available: "24.7"
    source:
      type: github
      org: helix-editor
      repo: helix
      asset_pattern: "x86_64.AppImage"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-09-20T14:00:00Z"

  zellij:
    current: "0.43.1"
    previous: "0.42.0"
    available: "0.43.1"
    source:
      type: github
      org: zellij-org
      repo: zellij
      asset_pattern: "x86_64-unknown-linux-musl.tar.gz"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-08-08T12:00:00Z"

  # Language Runtimes
  go:
    current: "1.25.3"
    previous: "1.25.2"
    available: "1.25.3"
    source:
      type: direct
      url_template: "https://go.dev/dl/go{{ version }}.linux-amd64.tar.gz"
      version_check_url: "https://go.dev/VERSION?m=text"
      version_check_method: "text_file"  # or: json_api, html_scrape, github_api, etc.
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-10-15T09:00:00Z"

  vivaldi:
    current: "7.0.3495.11"
    previous: "7.0.3494.15"
    available: "7.0.3495.11"
    source:
      type: deb
      url_template: "https://downloads.vivaldi.com/stable/vivaldi-stable_{{ version }}_amd64.deb"
      version_check_url: "https://vivaldi.com/download/"
      version_check_method: "html_scrape"
      version_regex: 'data-version="([0-9.]+)"'
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-10-10T11:00:00Z"

  claude-code:
    current: "2.0.24"
    previous: "2.0.23"
    available: "2.0.24"
    source:
      type: shell_script
      install_script_url: "https://install.claude.ai/linux"
      version_check_method: "installed_binary"  # Check ~/.claude/versions/
      version_command: "claude --version"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-10-06T16:00:00Z"

  starship:
    current: "1.23.0"
    previous: "1.22.0"
    available: "1.23.0"
    source:
      type: github
      org: starship
      repo: starship
      asset_pattern: "x86_64-unknown-linux-gnu.tar.gz"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-09-15T13:00:00Z"

  restic:
    current: "0.17.3"
    previous: "0.17.2"
    available: "0.17.3"
    source:
      type: github
      org: restic
      repo: restic
      asset_pattern: "linux_amd64.bz2"
    last_checked: "2025-10-20T15:00:00Z"
    last_updated: "2025-10-01T10:00:00Z"

  # Add more software as needed...

# Version update strategy
version_strategy:
  # How to handle version checks
  auto_check: false  # Don't automatically check for updates on every run

  # How to handle version updates
  auto_update: false  # Never automatically update, always explicit

  # Notification preferences
  notify_on_updates: true  # Show message when updates are available
```

### Supported Source Types

The system supports multiple installation methods, each with appropriate version checking:

#### 1. GitHub Releases
```yaml
source:
  type: github
  org: casey
  repo: just
  asset_pattern: "x86_64-unknown-linux-musl.tar.gz"
```
- **Install**: Download release asset from GitHub
- **Version Check**: GitHub API `/repos/{org}/{repo}/releases/latest`
- **Handler**: `roles/system/tasks/includes/install_github_release.yml`

#### 2. Direct Downloads
```yaml
source:
  type: direct
  url_template: "https://go.dev/dl/go{{ version }}.linux-amd64.tar.gz"
  version_check_url: "https://go.dev/VERSION?m=text"
  version_check_method: "text_file"
```
- **Install**: Direct download from templated URL
- **Version Check**: Fetch version from text file, JSON API, or HTML page
- **Handler**: `roles/system/tasks/includes/install_direct_download.yml`

#### 3. Debian/Ubuntu Packages (.deb)
```yaml
source:
  type: deb
  url_template: "https://downloads.vivaldi.com/stable/vivaldi-stable_{{ version }}_amd64.deb"
  version_check_url: "https://vivaldi.com/download/"
  version_check_method: "html_scrape"
  version_regex: 'data-version="([0-9.]+)"'
```
- **Install**: Download and install .deb package
- **Version Check**: Scrape HTML or check JSON API
- **Handler**: `roles/system/tasks/includes/install_deb_package.yml`

#### 4. Shell Script Installers
```yaml
source:
  type: shell_script
  install_script_url: "https://install.claude.ai/linux"
  version_check_method: "installed_binary"
  version_command: "claude --version"
```
- **Install**: Run installation script
- **Version Check**: Query installed binary or check installation directory
- **Handler**: `roles/system/tasks/includes/install_shell_script.yml`

#### 5. AppImages
```yaml
source:
  type: appimage
  url_template: "https://releases.example.com/app-{{ version }}-x86_64.AppImage"
  version_check_url: "https://api.example.com/latest"
  version_check_method: "json_api"
  version_json_path: "tag_name"
```
- **Install**: Download AppImage, make executable
- **Version Check**: JSON API, GitHub releases, or RSS feed
- **Handler**: `roles/system/tasks/includes/install_appimage.yml`

#### 6. Archive Extraction (tar.gz, zip, etc.)
```yaml
source:
  type: archive
  url_template: "https://releases.example.com/tool-{{ version }}.tar.gz"
  archive_format: "tar.gz"  # or: zip, tar.bz2, etc.
  binary_path_in_archive: "bin/tool"
  version_check_url: "https://releases.example.com/latest.json"
  version_check_method: "json_api"
  version_json_path: "version"
```
- **Install**: Download archive, extract binary
- **Version Check**: Various methods
- **Handler**: `roles/system/tasks/includes/install_archive.yml`

### Version Check Methods

Different `version_check_method` values supported:

#### 1. GitHub API
```yaml
version_check_method: "github_api"
# Automatically uses GitHub API for the specified org/repo
# Returns: tag_name from latest release
```

#### 2. Text File
```yaml
version_check_method: "text_file"
version_check_url: "https://go.dev/VERSION?m=text"
version_regex: "go([0-9.]+)"  # Optional: extract version from text
# Returns: First line or regex match from text file
```

#### 3. JSON API
```yaml
version_check_method: "json_api"
version_check_url: "https://api.example.com/latest"
version_json_path: "version"  # JSONPath to version field
# Returns: Value at specified JSON path
```

#### 4. HTML Scrape
```yaml
version_check_method: "html_scrape"
version_check_url: "https://example.com/download"
version_regex: 'data-version="([0-9.]+)"'
# Returns: First regex capture group from HTML
```

#### 5. RSS/Atom Feed
```yaml
version_check_method: "rss"
version_check_url: "https://github.com/org/repo/releases.atom"
version_regex: "v([0-9.]+)"  # Extract from first entry title
# Returns: Version from latest feed entry
```

#### 6. Installed Binary
```yaml
version_check_method: "installed_binary"
version_command: "tool --version"
version_regex: "v?([0-9.]+)"
# Returns: Version from command output
```

#### 7. Custom Script
```yaml
version_check_method: "custom_script"
version_check_script: |
  #!/bin/bash
  curl -s https://example.com/version | jq -r '.current'
# Returns: Script output (cleaned)
```

### Modified Installation Handlers

**Locations**:
- `roles/system/tasks/includes/install_github_release.yml`
- `roles/system/tasks/includes/install_direct_download.yml`
- `roles/system/tasks/includes/install_deb_package.yml`
- `roles/system/tasks/includes/install_shell_script.yml`
- `roles/system/tasks/includes/install_appimage.yml`
- `roles/system/tasks/includes/install_archive.yml`

**Key Changes**:
- Read version from `pinned_versions.yml` instead of checking GitHub API
- Only install/update if installed version != pinned version
- No GitHub API calls during normal runs
- Track installation metadata locally

**Logic**:
```yaml
- name: Get pinned version for {{ repo }}
  set_fact:
    pinned_version: "{{ pinned_software[repo].current }}"
    source_info: "{{ pinned_software[repo].source }}"

- name: Check currently installed version
  # Read from /var/lib/ansible/github_releases/<org>/<repo>/version.json
  # Compare with pinned_version

- name: Install/update if version mismatch
  when: installed_version != pinned_version
  # Download and install the pinned version
  # Update metadata with pinned version info
```

### Version Management Commands

#### 1. Check for Updates (No Changes)

**Command**: `jsys check-versions`

**Purpose**: Query upstream sources for available versions, update `available` field

**Process**:
1. Read `pinned_versions.yml`
2. For each software, query upstream (GitHub API, direct URL, etc.)
3. Update `available` field with latest version
4. Update `last_checked` timestamp
5. Show summary of available updates
6. **Commit changes** to `pinned_versions.yml` (only `available` and `last_checked` changed)

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Available Updates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Software          Current    Available   Action
─────────────────────────────────────────────────────────────────
just              1.43.0     1.44.0      Run: jsys update-version just
helix             24.7       24.7        ✓ Up to date
zellij            0.43.1     0.44.0      Run: jsys update-version zellij
go                1.25.3     1.26.0      Run: jsys update-version go

3 of 4 packages have updates available
Last checked: 2025-10-20 15:30:00

Changes written to: inventory/group_vars/all/pinned_versions.yml
Commit with: just commit
```

#### 2. Update Single Package Version

**Command**: `jsys update-version <package> [--to <version>]`

**Purpose**: Update pinned version for a single package

**Process**:
1. Read `pinned_versions.yml`
2. If `--to` specified, use that version; else use `available` version
3. Update `previous` = old `current`
4. Update `current` = new version
5. Update `last_updated` timestamp
6. Write back to `pinned_versions.yml`
7. Show what changed
8. Optionally run Ansible to deploy immediately

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Updating just
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Version change:
  Previous: 1.42.0
  Current:  1.43.0 → 1.44.0

→ Updated pinned_versions.yml
→ Ready to deploy with: jsys update-ansible-tags just

Deploy now? [y/N]:
```

#### 3. Update All Packages

**Command**: `jsys update-all-versions`

**Purpose**: Update all packages that have newer available versions

**Process**:
1. Read `pinned_versions.yml`
2. For each package where `available` > `current`:
   - Update `previous` = old `current`
   - Update `current` = `available`
   - Update `last_updated` timestamp
3. Write back to `pinned_versions.yml`
4. Show summary
5. Optionally run Ansible to deploy all

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Updating All Packages
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Packages to update:
  just:    1.43.0 → 1.44.0
  zellij:  0.43.1 → 0.44.0
  go:      1.25.3 → 1.26.0

→ Updated pinned_versions.yml
→ Ready to deploy with: jsys update-ansible

Deploy now? [y/N]:
```

#### 4. Show Version Status

**Command**: `jsys version-status [package]`

**Purpose**: Show detailed version information for package(s)

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  just - Version Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Installed:    1.43.0
Pinned:       1.43.0  ✓ Match
Available:    1.44.0  ⚠ Update available

Previous:     1.42.0
Last Updated: 2025-09-27 10:00:00 (24 days ago)
Last Checked: 2025-10-20 15:30:00 (30 minutes ago)

Source:
  Type:       GitHub Release
  Repo:       casey/just
  Asset:      x86_64-unknown-linux-musl.tar.gz

Metadata:
  /var/lib/ansible/github_releases/casey/just/version.json
  Published:  2025-09-27 09:45:00

Update:
  jsys update-version just
  jsys update-ansible-tags just
```

#### 5. Rollback to Previous Version

**Command**: `jsys rollback-version <package>`

**Purpose**: Rollback to previous version

**Process**:
1. Swap `current` and `previous`
2. Update `last_updated` timestamp
3. Deploy with Ansible

## Implementation Plan

### Phase 1: Foundation (Week 1)

**Tasks**:
1. Create `inventory/group_vars/all/pinned_versions.yml` with all current software
2. Create initial version metadata by reading from existing installations
3. Document structure and fields

**Deliverables**:
- `pinned_versions.yml` with complete current state
- Migration script to extract current versions

### Phase 2: Modified Ansible Handler (Week 2)

**Tasks**:
1. Create `roles/system/tasks/includes/github_release_pinned.yml`
2. Modify existing roles to use pinned versions instead of API checks
3. Ensure backward compatibility during transition
4. Test installation from pinned versions

**Deliverables**:
- New `github_release_pinned.yml` handler
- Updated roles (just, helix, zellij, etc.)
- Test results showing installations work

### Phase 3: Version Check Command (Week 3)

**Tasks**:
1. Create `jsys check-versions` command
2. Implement upstream version checking (GitHub API, direct URLs)
3. Update `pinned_versions.yml` with available versions
4. Create pretty output showing update status

**Deliverables**:
- `jsys check-versions` working command
- Automatic update of `available` field
- Clear output showing what's available

### Phase 4: Version Update Commands (Week 4)

**Tasks**:
1. Create `jsys update-version <package>` command
2. Create `jsys update-all-versions` command
3. Create `jsys version-status <package>` command
4. Create `jsys rollback-version <package>` command
5. Add interactive prompts for deployment

**Deliverables**:
- All version management commands working
- Interactive deployment workflow
- Documentation for each command

### Phase 5: Documentation & Migration (Week 5)

**Tasks**:
1. Update all documentation
2. Create migration guide from current system
3. Add examples and tutorials
4. Create troubleshooting guide

**Deliverables**:
- Complete documentation
- Migration completed
- Old system deprecated

## File Structure

```
inventory/group_vars/all/
├── pinned_versions.yml          # Central version control file
└── versions.yml                 # Legacy (deprecated after migration)

roles/system/tasks/includes/
├── github_release_pinned.yml    # New: Uses pinned versions
└── github_release.yml           # Old: Keep for backward compat initially

docs/
├── pinned-version-control.md    # This design document
├── version-management.md        # User guide (update for new system)
└── version-migration.md         # Migration guide from old to new

/var/lib/ansible/
└── pinned_software/             # Metadata storage
    └── <package>/
        └── metadata.json        # Installation metadata
```

## Benefits

### 1. Predictability
- Versions only change when explicitly requested
- No surprises from automatic updates
- Git history shows exactly when versions changed

### 2. Performance
- No GitHub API calls on every Ansible run
- Faster deployments
- No rate limit issues

### 3. Control
- Choose when to update
- Test updates before deploying
- Easy rollback to previous version

### 4. Auditability
- Complete version history in git
- Track who changed what when
- See why versions were updated (commit messages)

### 5. Reproducibility
- Exact versions in version control
- Can recreate any previous state
- Team members have identical environments

### 6. Flexibility
- Can pin different versions per host if needed
- Can test new versions before rolling out
- Can maintain multiple version branches

## Migration Strategy

### Step 1: Dual Mode
- Keep both systems running
- New software uses pinned versions
- Existing software continues with API checks

### Step 2: Extract Current State
- Script to read all `/var/lib/ansible/github_releases/` metadata
- Populate `pinned_versions.yml` with current versions
- Verify accuracy

### Step 3: Gradual Migration
- Migrate one software package at a time
- Test thoroughly
- Document any issues

### Step 4: Deprecation
- Once all software migrated, deprecate old system
- Remove `github_release.yml`
- Update documentation

### Step 5: Cleanup
- Remove old metadata directories
- Clean up old variables
- Archive old documentation

## Risks & Mitigations

### Risk: Manual Version Updates Required
- **Mitigation**: Create simple `jsys check-versions` command (one command to check all)
- **Mitigation**: Set up periodic reminder (weekly cron?)
- **Mitigation**: Show clear output of what needs updating

### Risk: Stale Versions
- **Mitigation**: `jsys check-versions` shows how old "last checked" is
- **Mitigation**: Alert if `last_checked` > 30 days
- **Mitigation**: Easy to run update check

### Risk: Missing Security Updates
- **Mitigation**: Security-critical software (browsers, etc.) should stay on package managers
- **Mitigation**: Weekly version check cadence
- **Mitigation**: Subscribe to security advisories for critical software

### Risk: Complex Rollback
- **Mitigation**: `jsys rollback-version` command makes it one-step
- **Mitigation**: Keep previous version in metadata
- **Mitigation**: Test rollback procedure

### Risk: Initial Setup Effort
- **Mitigation**: Phased migration (one package at a time)
- **Mitigation**: Automated extraction of current state
- **Mitigation**: Good documentation

## Success Metrics

1. **Zero unintended updates** - Versions only change when explicitly requested
2. **Fast deployments** - No GitHub API calls during normal Ansible runs
3. **Clear visibility** - Easy to see current/available versions
4. **Simple updates** - One command to check, one to update
5. **Git history** - All version changes tracked in commits

## Future Enhancements

### Version Validation
- Verify checksums of downloaded binaries
- GPG signature verification where available
- Alert on suspicious version changes

### Update Notifications
- Email/Slack notifications when updates available
- Dashboard showing update status
- Integration with monitoring systems

### Advanced Rollback
- Keep N previous versions on disk
- Quick rollback without re-download
- Automated rollback on failures

### Multi-Environment Support
- Different versions for dev/staging/prod
- Gradual rollout (canary deployments)
- Version matrices for testing

### Dependency Management
- Track dependencies between tools
- Warn about incompatible version combinations
- Suggest related updates

## Questions to Address

1. **How often to run `jsys check-versions`?**
   - Recommendation: Weekly manual check, or via cron
   - Could add to `jsys update-all` workflow

2. **Should we cache GitHub API responses?**
   - Yes, for `check-versions` command
   - Cache for 1 hour to avoid rate limits

3. **How to handle pre-release versions?**
   - Add `prerelease: bool` field to source config
   - Separate command: `jsys check-versions --include-prerelease`

4. **What about software with irregular release cycles?**
   - Track `last_checked` separately from `last_updated`
   - Allow manual version specification

5. **How to handle breaking changes?**
   - Add `notes` field for version-specific information
   - Could add `breaking_changes` URL reference

## Conclusion

This pinned version control system provides:
- ✅ Explicit version control
- ✅ No API rate limits during normal operations
- ✅ Complete auditability via git
- ✅ Simple update workflow
- ✅ Easy rollback capability
- ✅ Predictable, reproducible deployments

The phased migration approach allows gradual transition with minimal risk, while the simple command interface (`jsys check-versions`, `jsys update-version`) keeps the workflow intuitive.

**Next Steps**: Review this plan, refine as needed, then begin Phase 1 implementation.
