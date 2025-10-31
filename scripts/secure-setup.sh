#!/usr/bin/env bash
set -euo pipefail

# Secure Setup Script
# Prompts for sensitive values and creates secure local files
# These files are .gitignored and never committed

echo "=================================="
echo "Desktop Operator - Secure Setup"
echo "=================================="
echo ""
echo "This script will create secure local files from your inputs."
echo "These files are automatically excluded from git via .gitignore."
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

# Function to prompt for password (hidden input)
prompt_password() {
    local prompt="$1"
    local var_name="$2"
    local password
    local password_confirm

    while true; do
        read -r -s -p "$prompt: " password
        echo ""
        read -r -s -p "Confirm $prompt: " password_confirm
        echo ""

        if [ "$password" == "$password_confirm" ]; then
            eval "$var_name='$password'"
            break
        else
            echo "Passwords don't match. Please try again."
        fi
    done
}

# Function to create secure file
create_secure_file() {
    local file_path="$1"
    local content="$2"
    local permissions="$3"

    echo "$content" > "$file_path"
    chmod "$permissions" "$file_path"
    echo "✓ Created: $file_path (permissions: $permissions)"
}

# === 1. Ansible Vault Password ===
echo ""
echo "Step 1: Ansible Vault Password"
echo "-------------------------------"

if [ -f ".vault_pass" ]; then
    echo "✓ .vault_pass already exists"
    read -r -p "Recreate it? (y/N): " recreate
    if [[ ! "$recreate" =~ ^[Yy]$ ]]; then
        SKIP_VAULT_PASS=true
    fi
fi

if [ "${SKIP_VAULT_PASS:-false}" != "true" ]; then
    echo ""
    echo "Choose vault password source:"
    echo "1) Enter manually"
    echo "2) Generate random (recommended)"
    echo "3) Retrieve from 1Password"
    read -r -p "Choice [2]: " vault_choice
    vault_choice=${vault_choice:-2}

    case $vault_choice in
        1)
            prompt_password "Ansible Vault Password" VAULT_PASSWORD
            create_secure_file ".vault_pass" "$VAULT_PASSWORD" "600"
            ;;
        2)
            VAULT_PASSWORD=$(openssl rand -base64 32)
            create_secure_file ".vault_pass" "$VAULT_PASSWORD" "600"
            echo ""
            echo "IMPORTANT: Save this vault password securely!"
            echo "Vault Password: $VAULT_PASSWORD"
            echo ""
            read -r -p "Press Enter after you've saved this password..."
            ;;
        3)
            if command -v op &> /dev/null; then
                eval "$(op signin)"
                VAULT_PASSWORD=$(op read "op://Private/Ansible Vault/password")
                create_secure_file ".vault_pass" "$VAULT_PASSWORD" "600"
            else
                echo "1Password CLI not found. Install it first or choose another option."
                exit 1
            fi
            ;;
    esac
fi

# === 2. Vault File ===
echo ""
echo "Step 2: Encrypted Vault File"
echo "-----------------------------"

if [ -f "group_vars/all/vault.yml" ]; then
    echo "✓ vault.yml already exists"
    # Check if it's encrypted
    if head -1 "group_vars/all/vault.yml" | grep -q "\$ANSIBLE_VAULT"; then
        echo "✓ vault.yml is encrypted"
    else
        echo "⚠️  vault.yml exists but is NOT encrypted!"
        read -r -p "Encrypt it now? (Y/n): " encrypt_now
        if [[ ! "$encrypt_now" =~ ^[Nn]$ ]]; then
            ansible-vault encrypt group_vars/all/vault.yml
            chmod 600 group_vars/all/vault.yml
            echo "✓ vault.yml encrypted"
        fi
    fi
else
    echo "Creating vault.yml from template..."
    cp group_vars/all/vault.yml.example group_vars/all/vault.yml

    echo ""
    echo "Now you can:"
    echo "1) Edit vault.yml with your actual secrets: vim group_vars/all/vault.yml"
    echo "2) Then run this script again to encrypt it"
    echo ""
    read -r -p "Press Enter to open vault.yml in your editor..."

    ${EDITOR:-vim} group_vars/all/vault.yml

    echo ""
    read -r -p "Encrypt vault.yml now? (Y/n): " encrypt_now
    if [[ ! "$encrypt_now" =~ ^[Nn]$ ]]; then
        ansible-vault encrypt group_vars/all/vault.yml
        chmod 600 group_vars/all/vault.yml
        echo "✓ vault.yml encrypted and secured"
    fi
fi

# === 3. Additional Sensitive Files ===
echo ""
echo "Step 3: Additional Sensitive Files (Optional)"
echo "----------------------------------------------"

read -r -p "Create SSH config with sensitive hosts? (y/N): " create_ssh_config
if [[ "$create_ssh_config" =~ ^[Yy]$ ]]; then
    mkdir -p files/home/.ssh
    if [ ! -f "files/home/.ssh/config" ]; then
        cat > files/home/.ssh/config << 'EOF'
# SSH Config
# This file is .gitignored - safe to add sensitive hosts

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github

# Add your sensitive hosts below
EOF
        chmod 600 files/home/.ssh/config
        echo "✓ Created files/home/.ssh/config (template)"
        echo "  Edit it to add your sensitive hosts"
    else
        echo "✓ files/home/.ssh/config already exists"
    fi
fi

# === 4. Security Verification ===
echo ""
echo "Step 4: Security Verification"
echo "------------------------------"

# Check permissions
echo "Checking file permissions..."
[ -f ".vault_pass" ] && [ "$(stat -c %a .vault_pass)" = "600" ] && echo "✓ .vault_pass (600)" || echo "⚠️  .vault_pass has incorrect permissions"
[ -f "group_vars/all/vault.yml" ] && [ "$(stat -c %a group_vars/all/vault.yml)" = "600" ] && echo "✓ vault.yml (600)" || echo "⚠️  vault.yml has incorrect permissions"

# Check if vault is encrypted
if [ -f "group_vars/all/vault.yml" ]; then
    if head -1 "group_vars/all/vault.yml" | grep -q "\$ANSIBLE_VAULT"; then
        echo "✓ vault.yml is encrypted"
    else
        echo "⚠️  vault.yml is NOT encrypted!"
    fi
fi

# Check git status
echo ""
echo "Checking git status..."
if git status --porcelain | grep -qE '(vault\.yml$|\.vault_pass|password|secret|token|\.key$|\.pem$)'; then
    echo "⚠️  WARNING: Sensitive files detected in git staging area!"
    echo "Review with: git status"
else
    echo "✓ No sensitive files in git staging"
fi

# === 5. Summary ===
echo ""
echo "=================================="
echo "Secure Setup Complete!"
echo "=================================="
echo ""
echo "Security Checklist:"
[ -f ".vault_pass" ] && echo "✓ .vault_pass created" || echo "✗ .vault_pass missing"
[ -f "group_vars/all/vault.yml" ] && echo "✓ vault.yml exists" || echo "✗ vault.yml missing"
echo "✓ Files protected by .gitignore"
echo ""
echo "Git commit rules:"
echo "  ✓ vault.yml CAN be committed (when encrypted)"
echo "  ✗ .vault_pass should NEVER be committed"
echo "  ✓ vault.yml.example CAN be committed (it's a template)"
echo ""
echo "Before committing, always run:"
echo "  just check-git  # Verifies vault.yml is encrypted"
echo ""
echo "Next steps:"
echo "1. Verify settings: vim group_vars/all/settings.yml"
echo "2. Review inventory: vim inventory/hosts.yml"
echo "3. Run security check: just check-secrets"
echo "4. Bootstrap a host: just bootstrap <hostname>"
echo ""
