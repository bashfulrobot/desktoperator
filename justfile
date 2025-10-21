# Desktop Operator - Justfile (Day-to-Day Operations)
# Run 'just' to see all available commands
# NOTE: All recipes automatically target the current/local host
#
# Additional justfiles for periodic tasks:
#   just -f justfiles/maintenance  - Updates, Ansible maintenance
#   just -f justfiles/security     - Vault operations, security checks
#   just -f justfiles/git          - Commit, pull operations

# Set shell for all recipes
set shell := ["bash", "-uc"]

# Disable dotenv loading
set dotenv-load := false

# Define reusable helper functions
header_msg := '
header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}
'

success_msg := '
success() {
    echo "✓ $1"
}
'

error_msg := '
error() {
    echo "✗ Error: $1" >&2
}
'

# Default recipe - show help
default:
    @just --list --unsorted

# ============================================================================
# PLAYBOOK EXECUTION
# ============================================================================

# Run the complete playbook on this host
[group('playbook')]
run:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Running Full Playbook"
    echo "→ Executing ansible-playbook on $(hostname)..."
    ansible-playbook site.yml --limit $(hostname)
    success "Playbook completed successfully"

# Run with check mode (dry run)
[group('playbook')]
check:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}

    header "Ansible Dry Run (Check Mode)"
    echo "→ Running in check mode on $(hostname)..."
    ansible-playbook site.yml --limit $(hostname) --check --diff

# Run only system configuration
[group('playbook')]
system:
    ansible-playbook site.yml --limit $(hostname) --tags system

# Run only desktop configuration
[group('playbook')]
desktop:
    ansible-playbook site.yml --limit $(hostname) --tags desktop

# Run only application installations
[group('playbook')]
apps:
    ansible-playbook site.yml --limit $(hostname) --tags apps

# Run specific tag (e.g., just tag hostname, just tag fish) - use 'just tags' to see all
[group('playbook')]
tag TAG:
    ansible-playbook site.yml --limit $(hostname) --tags {{TAG}}

# Run specific app (e.g., just app firefox)
[group('playbook')]
app APP:
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{APP}}]"

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================

# Install specific package (e.g., just install firefox)
[group('packages')]
install PACKAGE:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Installing {{PACKAGE}}"
    echo "→ Installing {{PACKAGE}} on $(hostname)..."
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=present"
    success "{{PACKAGE}} installed successfully"

# Uninstall specific package (e.g., just uninstall zoom)
[group('packages')]
uninstall PACKAGE:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Uninstalling {{PACKAGE}}"
    echo "→ Removing {{PACKAGE}} from $(hostname)..."
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=absent"
    success "{{PACKAGE}} removed successfully"

# ============================================================================
# BOOTSTRAP
# ============================================================================

# Bootstrap this system (first-time setup, prompts for sudo password)
[group('bootstrap')]
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Bootstrapping System"
    echo "→ Running bootstrap on $(hostname)..."
    ansible-playbook bootstrap.yml --limit $(hostname) --tags bootstrap --ask-become-pass
    success "Bootstrap completed successfully"

# ============================================================================
# GIT & VERSION CONTROL
# ============================================================================

# Safe commit: encrypt vault files, verify security, then commit with AI
[group('git')]
commit:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Preparing Commit"

    echo "→ Step 1: Checking for vault files to encrypt..."
    # Find any unencrypted vault.yml files
    for vault_file in $(find inventory/group_vars inventory/host_vars -name "vault.yml" 2>/dev/null || true); do
        if [ -f "$vault_file" ]; then
            if ! head -1 "$vault_file" | grep -q '\$ANSIBLE_VAULT'; then
                echo "  Encrypting $vault_file..."
                ansible-vault encrypt "$vault_file"
                chmod 600 "$vault_file"
                git add "$vault_file"
            else
                echo "  ✓ $vault_file already encrypted"
            fi
        fi
    done

    echo ""
    echo "→ Step 2: Running security checks..."
    just -f justfiles/security check-git

    echo ""
    echo "→ Step 3: Creating commit with Claude..."
    claude -p "/commit --push"
    success "Commit process completed"

# Pull latest config from git and apply to this host
[group('git')]
pull:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Pulling Changes and Applying Configuration"
    echo "→ Pulling from origin/main..."
    git pull origin main
    echo "→ Applying configuration to $(hostname)..."
    ansible-playbook site.yml --limit $(hostname)
    success "Configuration updated successfully"

# ============================================================================
# TESTING & VALIDATION
# ============================================================================

# Run syntax check on all playbooks
[group('validation')]
syntax:
    @ansible-playbook site.yml --syntax-check

# Lint all Ansible files
[group('validation')]
lint:
    @ansible-lint . roles/

# List all hosts in inventory
[group('validation')]
hosts:
    @ansible-inventory --list

# Show this host's inventory details
[group('validation')]
info:
    @ansible-inventory --host $(hostname)

# Ping this host
[group('validation')]
ping:
    @ansible $(hostname) -m ping

# Show all tasks that would run on this host
[group('validation')]
tasks:
    @ansible-playbook site.yml --list-tasks --limit $(hostname)

# Show all tags available in playbooks
[group('validation')]
tags:
    @ansible-playbook site.yml --list-tags

# ============================================================================
# COSMIC DESKTOP
# ============================================================================

# Capture current COSMIC configuration to repository
[group('cosmic')]
cosmic-capture:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Capturing COSMIC Configuration"
    echo "→ Running capture script..."
    ./scripts/capture-cosmic-config.sh
    echo ""
    echo "Review changes with: git diff cosmic-config/"
    echo "Commit with: just commit"
    success "COSMIC configuration captured"

# Generate color variables from COSMIC themes
[group('cosmic')]
generate-cosmic-colors:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Generating Color Variables from COSMIC Themes"
    echo "→ Extracting Dark and Light theme colors..."
    ./scripts/generate-cosmic-colors.sh
    echo ""
    echo "Review changes with: git diff group_vars/all/auto-colors.yml"
    success "Color variables generated"

# Generate all theme files (VSCode, Vivaldi, etc.)
[group('cosmic')]
generate-theme-files:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Generating All COSMIC Theme Files"
    echo "→ Generating VSCode and Vivaldi themes..."
    ./scripts/generate-theme-files.sh
    echo ""
    echo "Review changes with: git diff extras/themes/"
    success "Theme files generated"

# Run only COSMIC desktop configuration
[group('cosmic')]
cosmic:
    ansible-playbook site.yml --limit $(hostname) --tags cosmic
