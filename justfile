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
    ansible-playbook playbooks/site.yml --limit $(hostname)

# Run with check mode (dry run)
check:
    ansible-playbook playbooks/site.yml --limit $(hostname) --check --diff

# === Targeted Runs ===

# Run only system configuration
system:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags system

# Run only desktop configuration
desktop:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags desktop

# Run only application installations
apps:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags apps

# Run specific tag (e.g., just tag hostname, just tag fish) - use 'just tags' to see all
tag TAG:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags {{TAG}}

# Run specific app (e.g., just app firefox)
app APP:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{APP}}]"

# === Package Management ===

# Install specific package (e.g., just install firefox)
install PACKAGE:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=present"

# Uninstall specific package (e.g., just uninstall zoom)
uninstall PACKAGE:
    ansible-playbook playbooks/site.yml --limit $(hostname) --tags apps -e "enabled_apps=[{{PACKAGE}}]" -e "app_states={{PACKAGE}}=absent"

# === Bootstrap ===

# Bootstrap this system (first-time setup)
bootstrap:
    ansible-playbook playbooks/bootstrap.yml --limit $(hostname) --tags bootstrap

# Bootstrap with sudo password prompt (for fresh systems without NOPASSWD sudo)
bootstrap-ask:
    ansible-playbook playbooks/bootstrap.yml --limit $(hostname) --tags bootstrap --ask-become-pass

# === Git & Version Control ===

# Safe commit: encrypt vault files, verify security, then commit with AI
commit:
    #!/usr/bin/env bash
    set -e

    echo "Step 1: Checking for vault files to encrypt..."
    # Find any unencrypted vault.yml files
    for vault_file in $(find group_vars host_vars -name "vault.yml" 2>/dev/null || true); do
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
    ansible-playbook playbooks/site.yml --limit $(hostname)

# === Testing & Validation ===

# Run syntax check on all playbooks
syntax:
    ansible-playbook playbooks/site.yml --syntax-check

# Lint all Ansible files
lint:
    ansible-lint playbooks/ roles/

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
    ansible-playbook playbooks/site.yml --list-tasks --limit $(hostname)

# Show all tags available in playbooks
tags:
    ansible-playbook playbooks/site.yml --list-tags
