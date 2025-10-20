# Desktop Operator - Justfile (Day-to-Day Operations)
# Run 'just' to see all available commands
# NOTE: All recipes automatically target the current/local host
#
# Additional justfiles for periodic tasks:
#   just -f justfiles/maintenance  - Updates, Ansible maintenance
#   just -f justfiles/security     - Vault operations, security checks
#   just -f justfiles/git          - Commit, pull operations

# Default recipe - show help
default:
    @just --list

# === Full Playbook Runs ===

# Run the complete playbook on this host
run:
    ansible-playbook site.yml --limit $(hostname)

# Run with check mode (dry run)
check:
    ansible-playbook site.yml --limit $(hostname) --check --diff

# === Targeted Runs ===

# Run only system configuration
system:
    ansible-playbook site.yml --limit $(hostname) --tags system

# Run only desktop configuration
desktop:
    ansible-playbook site.yml --limit $(hostname) --tags desktop

# Run only application installations
apps:
    ansible-playbook site.yml --limit $(hostname) --tags apps

# Run specific tag (e.g., just tag hostname, just tag fish) - use 'just tags' to see all
tag TAG:
    ansible-playbook site.yml --limit $(hostname) --tags {{TAG}}

# Run specific app (e.g., just app firefox)
app APP:
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{APP}}]"

# === Package Management ===

# Install specific package (e.g., just install firefox)
install PACKAGE:
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=present"

# Uninstall specific package (e.g., just uninstall zoom)
uninstall PACKAGE:
    ansible-playbook site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=absent"

# === Bootstrap ===

# Bootstrap this system (first-time setup, prompts for sudo password)
bootstrap:
    ansible-playbook bootstrap.yml --limit $(hostname) --tags bootstrap --ask-become-pass

# === Git & Version Control ===

# Safe commit: encrypt vault files, verify security, then commit with AI
commit:
    #!/usr/bin/env bash
    set -e

    echo "Step 1: Checking for vault files to encrypt..."
    # Find any unencrypted vault.yml files
    for vault_file in $(find inventory/group_vars inventory/host_vars -name "vault.yml" 2>/dev/null || true); do
        if [ -f "$vault_file" ]; then
            if ! head -1 "$vault_file" | grep -q '\$ANSIBLE_VAULT'; then
                echo "Encrypting $vault_file..."
                ansible-vault encrypt "$vault_file"
                chmod 600 "$vault_file"
                git add "$vault_file"
            else
                echo "✓ $vault_file already encrypted"
            fi
        fi
    done

    echo ""
    echo "Step 2: Running security checks..."
    just -f justfiles/security check-git

    echo ""
    echo "Step 3: Creating commit with Claude..."
    claude -p "/commit --push"

# Pull latest config from git and apply to this host
pull:
    git pull origin main
    ansible-playbook site.yml --limit $(hostname)

# === Testing & Validation ===

# Run syntax check on all playbooks
syntax:
    ansible-playbook site.yml --syntax-check

# Lint all Ansible files
lint:
    ansible-lint . roles/

# List all hosts in inventory
hosts:
    ansible-inventory --list

# Show this host's inventory details
info:
    ansible-inventory --host $(hostname)

# Ping this host
ping:
    ansible $(hostname) -m ping

# Show all tasks that would run on this host
tasks:
    ansible-playbook site.yml --list-tasks --limit $(hostname)

# Show all tags available in playbooks
tags:
    ansible-playbook site.yml --list-tags

# === COSMIC Desktop ===

# Capture current COSMIC configuration to repository
cosmic-capture:
    @echo "Capturing COSMIC desktop configuration..."
    @./scripts/capture-cosmic-config.sh
    @echo ""
    @echo "Review changes with: git diff cosmic-config/"
    @echo "Commit with: just commit"

# Run only COSMIC desktop configuration
cosmic:
    ansible-playbook site.yml --limit $(hostname) --tags cosmic
