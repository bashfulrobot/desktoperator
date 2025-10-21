# Justfile Architecture

This document describes the hybrid justfile architecture used for managing system operations and project development.

## Overview

The architecture uses a **hybrid approach** with clear separation of concerns:

- **`jsys`** - System-level operations (requires sudo, affects whole system)
- **`just`** - Project-level operations (local to repository, no sudo)
- **`just -f justfiles/*`** - Specialized workflows (security, git, maintenance)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ SYSTEM OPERATIONS (jsys)                                     │
│ /usr/local/bin/jsys → /usr/local/share/just/system.just     │
├─────────────────────────────────────────────────────────────┤
│ system.just (main, imports modules)                          │
│   ├─ modules/updates.just      → System package updates     │
│   ├─ modules/maintenance.just  → System cleanup & health    │
│   ├─ modules/generators.just   → Theme generation           │
│   └─ modules/info.just         → System diagnostics         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PROJECT OPERATIONS (just)                                    │
│ ~/dev/iac/desktoperator/justfile                            │
├─────────────────────────────────────────────────────────────┤
│ Groups:                                                      │
│   [playbook]   → Ansible playbook execution                 │
│   [packages]   → Package install/uninstall                  │
│   [bootstrap]  → System bootstrap                           │
│   [git]        → Git operations (commit, pull)              │
│   [validation] → Testing & validation                       │
│   [cosmic]     → COSMIC desktop management                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SPECIALIZED WORKFLOWS                                        │
│ ~/dev/iac/desktoperator/justfiles/*                         │
├─────────────────────────────────────────────────────────────┤
│ justfiles/git         → Advanced git operations             │
│ justfiles/security    → Vault & security management         │
│ justfiles/maintenance → Ansible maintenance tasks           │
└─────────────────────────────────────────────────────────────┘
```

## Command Reference

### System Operations (`jsys`)

**Updates:**
```bash
jsys update-all              # Update everything
jsys update-apt              # Update APT packages
jsys update-flatpak          # Update Flatpak apps
jsys update-npm              # Update npm packages
jsys update-go               # Update Go tools
jsys update-ansible          # Run Ansible playbook
```

**Maintenance:**
```bash
jsys clean-system            # Clean system (cache, logs, etc)
jsys disk-usage              # Check disk usage
jsys health-check            # System health check
```

**Generators:**
```bash
jsys generate-cosmic-colors  # Extract COSMIC theme colors
jsys generate-theme-files    # Generate all app themes (VSCode, Vivaldi)
```

**Information:**
```bash
jsys system-info             # Show system information
jsys versions                # Show installed software versions
jsys ansible-tags            # List Ansible tags
```

### Project Operations (`just`)

**Playbook Execution:**
```bash
just run                     # Run full playbook
just check                   # Dry run (check mode)
just system                  # Run system config only
just desktop                 # Run desktop config only
just apps                    # Run apps only
just tag <TAG>               # Run specific tag
```

**Package Management:**
```bash
just install <PACKAGE>       # Install package
just uninstall <PACKAGE>     # Uninstall package
```

**Git Operations:**
```bash
just commit                  # Safe commit (vault checks + AI)
just pull                    # Pull and apply config
```

**Validation:**
```bash
just syntax                  # Syntax check
just lint                    # Lint playbooks
just tasks                   # List tasks
just tags                    # List tags
```

**COSMIC:**
```bash
just cosmic-capture          # Capture COSMIC config
just cosmic                  # Deploy COSMIC config
```

### Specialized Workflows

**Git (Advanced):**
```bash
just -f justfiles/git status              # Git status with vault context
just -f justfiles/git diff                # View diff
just -f justfiles/git rebase-interactive  # Interactive rebase
```

**Security:**
```bash
just -f justfiles/security vault-edit           # Edit vault
just -f justfiles/security vault-view           # View vault
just -f justfiles/security check-git            # Security check before commit
just -f justfiles/security fix-permissions      # Fix file permissions
```

**Maintenance:**
```bash
just -f justfiles/maintenance update-ansible    # Update Ansible itself
just -f justfiles/maintenance update-collections # Update collections
just -f justfiles/maintenance version           # Show Ansible version
```

## Design Principles

### 1. Modular Structure (jsys)

The system justfile uses a modular architecture:

- **Main file** (`system.just`) - Contains only configuration and imports
- **Module files** (`modules/*.just`) - Focused, single-purpose modules
- **Shared helpers** - Defined once in main, available to all modules

**Benefits:**
- Easy to extend (add new modules)
- Easy to maintain (edit specific domains)
- Clear organization (grouped by purpose)
- Manageable file sizes (~100-200 lines per module)

### 2. Clear Separation of Concerns

**System (`jsys`):**
- Requires sudo/root access
- Affects entire system
- Package manager updates
- System-wide configuration
- Health checks

**Project (`just`):**
- No sudo required
- Local to repository
- Ansible operations
- Git operations
- Development tasks

**Specialized (`just -f justfiles/*`):**
- Complex workflows
- Domain expertise required
- Less frequently used
- Advanced operations

### 3. Consistent UX

All justfiles share:
- Helper functions (header, success, error)
- Visual formatting (headers, arrows, checkmarks)
- Error handling (`set -euo pipefail`)
- Recipe groups for organization
- Clear, descriptive names

### 4. Best Practices

**Error Handling:**
```justfile
recipe:
    #!/usr/bin/env bash
    set -euo pipefail           # Exit on error, undefined vars, pipe failures
    {{ header_msg }}            # Load header function
    {{ success_msg }}           # Load success function
    {{ error_msg }}             # Load error function

    header "Doing Something"
    echo "→ Step 1..."
    command || { error "Failed"; exit 1; }
    success "Completed"
```

**Recipe Groups:**
```justfile
[group('updates')]
update-apt:
    # Recipe implementation

[group('updates')]
update-npm:
    # Recipe implementation
```

**Visual Feedback:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Running Full Playbook
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Executing ansible-playbook on qbert...
[command output]
✓ Playbook completed successfully
```

## Adding New Functionality

### To `jsys` (System Operations)

1. Determine the appropriate module (updates, maintenance, generators, info)
2. Edit the module template: `roles/system/justfile/templates/modules/<module>.just.j2`
3. Add your recipe with proper grouping and error handling
4. Deploy with: `just system` or `jsys update-ansible --tags system`

**Example:**
```justfile
# In modules/maintenance.just.j2
[group('maintenance')]
new-maintenance-task:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "New Maintenance Task"
    echo "→ Doing something..."
    sudo some-command
    success "Task completed"
```

### To Project `justfile`

1. Edit: `justfile`
2. Add to appropriate group or create new group
3. Use helper functions for consistency
4. Test with: `just <recipe>`

### To Specialized Justfiles

1. Edit: `justfiles/git`, `justfiles/security`, or `justfiles/maintenance`
2. Follow same patterns as main justfile
3. Test with: `just -f justfiles/<name> <recipe>`

## File Locations

**System (deployed by Ansible):**
- `/usr/local/share/just/system.just` - Main system justfile
- `/usr/local/share/just/modules/*.just` - Module justfiles
- `/usr/local/bin/jsys` - Wrapper command

**Project (in repository):**
- `justfile` - Main project justfile
- `justfiles/git` - Git operations
- `justfiles/security` - Security operations
- `justfiles/maintenance` - Maintenance operations

**Templates (Ansible):**
- `roles/system/justfile/templates/system.just.j2` - Main template
- `roles/system/justfile/templates/modules/*.just.j2` - Module templates
- `roles/system/justfile/tasks/main.yml` - Deployment tasks
- `roles/system/justfile/defaults/main.yml` - Configuration

## Maintenance

**Updating jsys:**
1. Edit templates in `roles/system/justfile/templates/`
2. Run: `just system` to deploy
3. Test: `jsys --list` and run recipes

**Updating project justfile:**
1. Edit `justfile` directly
2. Test: `just --list` and run recipes
3. Commit changes

**Updating specialized justfiles:**
1. Edit `justfiles/*` directly
2. Test: `just -f justfiles/<name> --list`
3. Commit changes
