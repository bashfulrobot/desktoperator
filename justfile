# Desktop Operator - Bootstrap Justfile
# Run 'just' to see all available commands
#
# PURPOSE: This justfile is for INITIAL SETUP ONLY
# After bootstrap, use 'jsys' for all daily operations
#
# Bootstrap workflow:
#   1. just bootstrap  - Install Ansible and dependencies
#   2. just run        - Apply initial configuration
#   3. jsys ...        - All future operations via jsys
#
# Specialized workflows (less common):
#   just -f justfiles/security     - Vault operations, security checks
#   just -f justfiles/git          - Advanced git operations
#   just -f justfiles/maintenance  - Ansible maintenance tasks

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

# Default recipe - show help and next steps
default:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "  Desktop Operator - Bootstrap & Initial Setup"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "INITIAL SETUP (run once):"
    @echo "  just bootstrap  - Install Ansible and system dependencies"
    @echo "  just run        - Apply full configuration (after bootstrap)"
    @echo "  just check      - Dry run to preview changes"
    @echo ""
    @echo "DAILY OPERATIONS (use jsys instead):"
    @echo "  jsys --list     - See all system management commands"
    @echo ""
    @echo "SPECIALIZED WORKFLOWS:"
    @echo "  just -f justfiles/security --list"
    @echo "  just -f justfiles/git --list"
    @echo "  just -f justfiles/maintenance --list"
    @echo ""

# ============================================================================
# BOOTSTRAP & INITIAL SETUP
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
    echo ""
    echo "Next steps:"
    echo "  1. Review inventory/host_vars/$(hostname)/ and customize settings"
    echo "  2. Run 'just check' to preview changes"
    echo "  3. Run 'just run' to apply configuration"
    echo "  4. After initial setup, use 'jsys' for all daily operations"

# Run the complete playbook on this host (initial setup)
[group('bootstrap')]
run:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}
    {{ success_msg }}

    header "Running Initial Configuration"
    echo "→ Executing ansible-playbook on $(hostname)..."
    ansible-playbook site.yml --limit $(hostname)
    success "Configuration applied successfully"
    echo ""
    echo "Initial setup complete!"
    echo ""
    echo "Daily operations are now available via 'jsys':"
    echo "  jsys --list               - See all commands"
    echo "  jsys update-all           - Update everything"
    echo "  jsys update-ansible       - Re-apply Ansible config"
    echo "  jsys generate-cosmic-colors  - Update theme colors"

# Run with check mode (dry run to preview changes)
[group('bootstrap')]
check:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ header_msg }}

    header "Ansible Dry Run (Check Mode)"
    echo "→ Running in check mode on $(hostname)..."
    ansible-playbook site.yml --limit $(hostname) --check --diff

# ============================================================================
# DEVELOPMENT / TESTING
# ============================================================================

# Run syntax check on all playbooks
[group('dev')]
syntax:
    @ansible-playbook site.yml --syntax-check

# Lint all Ansible files
[group('dev')]
lint:
    @ansible-lint . roles/

# List all hosts in inventory
[group('dev')]
hosts:
    @ansible-inventory --list

# Show this host's inventory details
[group('dev')]
info:
    @ansible-inventory --host $(hostname)

# Ping this host
[group('dev')]
ping:
    @ansible $(hostname) -m ping

# Show all tasks that would run on this host
[group('dev')]
tasks:
    @ansible-playbook site.yml --list-tasks --limit $(hostname)

# Show all tags available in playbooks
[group('dev')]
tags:
    @ansible-playbook site.yml --list-tags
