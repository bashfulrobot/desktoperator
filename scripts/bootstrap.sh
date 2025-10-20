#!/usr/bin/env bash
set -euo pipefail

# Desktop Operator Bootstrap Script
# This script prepares a fresh Ubuntu system to run Ansible

echo "=================================="
echo "Desktop Operator Bootstrap"
echo "=================================="
echo ""

# Check if running on Ubuntu or Pop!_OS
if ! grep -qE "(Ubuntu|Pop)" /etc/os-release; then
    echo "ERROR: This script is designed for Ubuntu-based systems only (Ubuntu, Pop!_OS)."
    exit 1
fi

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install minimal dependencies
echo "Installing minimal dependencies..."
sudo apt-get install -y software-properties-common git curl

# Add Ansible PPA and install Ansible
echo "Adding Ansible PPA..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

echo "Installing Ansible..."
sudo apt-get install -y ansible

# Install just command runner
echo "Installing just..."
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# Install 1Password CLI and Desktop for vault password retrieval
echo "Installing 1Password (Desktop + CLI)..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt-get update
sudo apt-get install -y 1password 1password-cli restic

# Install autorestic
echo "Installing autorestic..."
curl -fsSL https://raw.githubusercontent.com/cupcakearmy/autorestic/master/install.sh -o /tmp/autorestic-install.sh
sudo bash /tmp/autorestic-install.sh
rm /tmp/autorestic-install.sh
# Clean up .bz2 file if it exists
sudo rm -f /usr/local/bin/autorestic.bz2

# Clone the repository (if not already cloned)
# Default location: ~/dev/iac/desktoperator
REPO_DIR="${DESKTOPERATOR_DIR:-$HOME/dev/iac/desktoperator}"

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning desktoperator repository to $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone https://github.com/bashfulrobot/desktoperator.git "$REPO_DIR"
else
    echo "Repository already exists at $REPO_DIR"
fi

cd "$REPO_DIR"

# Launch 1Password GUI for authentication
echo ""
echo "==================================="
echo "1Password Authentication"
echo "==================================="
echo ""
echo "Launching 1Password desktop application..."
echo ""

# Launch 1Password in the background
1password &
ONEPASSWORD_PID=$!

echo "Please complete the following steps:"
echo ""
echo "1. Sign in to 1Password desktop application"
echo "2. Enable CLI integration:"
echo "   • Go to Settings → Developer"
echo "   • Enable 'Connect with 1Password CLI'"
echo "   • Authorize CLI access when prompted"
echo ""
echo "Once you've signed in and enabled CLI integration,"
read -p "press Enter to continue..."

# Wait a moment for CLI integration to be ready
sleep 2

# Retrieve vault password and save to .vault_pass
echo ""
echo "Retrieving vault password from 1Password..."
op read "op://Personal/desktoperator-bootstrap/ansible-vault" > .vault_pass
chmod 600 .vault_pass
echo "✓ Vault password saved to .vault_pass (permissions: 600)"

# Optional: Configure restic/autorestic
echo ""
echo "==================================="
echo "Restic/Autorestic Configuration"
echo "==================================="
echo ""
echo "Would you like to configure restic backup now?"
echo "This will create the autorestic configuration file."
echo "You can also do this later with Ansible."
echo ""
read -p "Configure restic now? [y/N]: " CONFIGURE_RESTIC

if [[ "$CONFIGURE_RESTIC" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Retrieving B2 credentials from 1Password..."

    # Retrieve B2 credentials from 1Password
    B2_ACCOUNT_ID=$(op read "op://Personal/desktoperator-bootstrap/b2_account_id" 2>/dev/null || echo "")
    B2_ACCOUNT_KEY=$(op read "op://Personal/desktoperator-bootstrap/b2_account_key" 2>/dev/null || echo "")
    B2_BUCKET=$(op read "op://Personal/desktoperator-bootstrap/b2_repository" 2>/dev/null || echo "")
    RESTIC_PASSWORD=$(op read "op://Personal/desktoperator-bootstrap/restic_password" 2>/dev/null || echo "")

    if [ -z "$B2_ACCOUNT_ID" ] || [ -z "$B2_ACCOUNT_KEY" ] || [ -z "$B2_BUCKET" ] || [ -z "$RESTIC_PASSWORD" ]; then
        echo "⚠️  Could not retrieve all credentials from 1Password."
        echo "Please ensure the following fields exist in 'op://Personal/desktoperator-bootstrap':"
        echo "  - b2_account_id"
        echo "  - b2_account_key"
        echo "  - b2_repository"
        echo "  - restic_password"
        echo ""
        echo "Skipping restic configuration. You can configure it later with Ansible."
    else
        mkdir -p "$HOME/.config/autorestic"

        cat > "$HOME/.config/autorestic/autorestic.yml" <<EOF
---
version: 2

backends:
  b2:
    type: b2
    path: '${B2_BUCKET}:/$(hostname)'
    key: '${RESTIC_PASSWORD}'
    env:
      B2_ACCOUNT_ID: '${B2_ACCOUNT_ID}'
      B2_ACCOUNT_KEY: '${B2_ACCOUNT_KEY}'

locations:
  home:
    from: '$HOME'
    to:
      - b2

    cron: '0 2 * * *'

    options:
      backup:
        exclude-file:
          - '$HOME/.config/autorestic/exclude'

      forget:
        keep-last: 5
        keep-hourly: 24
        keep-daily: 7
        keep-weekly: 4
        keep-monthly: 6
        keep-yearly: 2

    hooks:
      success:
        - 'echo "\$(date): Backup completed successfully" >> $HOME/.local/share/autorestic/backup.log'

      failure:
        - 'echo "\$(date): Backup FAILED" >> $HOME/.local/share/autorestic/backup-failures.log'
EOF

        chmod 600 "$HOME/.config/autorestic/autorestic.yml"

        # Create basic exclude file
        cat > "$HOME/.config/autorestic/exclude" <<EOF
.cache/
**/.cache/
**/node_modules/
**/target/
**/dist/
**/build/
Downloads/
**/.Trash/
EOF

        mkdir -p "$HOME/.local/share/autorestic"

        echo "✓ Autorestic configuration created"
        echo ""
        echo "Next steps for restic:"
        echo "  1. Initialize repository: autorestic exec -a -- init"
        echo "  2. Create first backup: autorestic backup -a"
        echo "  3. Ansible will manage the configuration going forward"
    fi
else
    echo "Skipping restic configuration."
    echo "You can configure it later by running Ansible with the restic role."
fi

# Check vault.yml status
echo ""
if [ -f "inventory/group_vars/all/vault.yml" ]; then
    echo "✓ Vault file already exists (cloned from repository)"
    chmod 600 inventory/group_vars/all/vault.yml
elif [ -f "group_vars/all/vault.yml" ]; then
    echo "✓ Vault file already exists"
    chmod 600 group_vars/all/vault.yml
else
    echo "Creating initial vault file..."
    echo "⚠️  Note: For existing installations, vault.yml should be in the repository."

    if [ -f "group_vars/all/vault.yml.example" ]; then
        cp group_vars/all/vault.yml.example group_vars/all/vault.yml
        echo "Please edit group_vars/all/vault.yml with your actual secrets, then we'll encrypt it."
        read -p "Press Enter when you've added your secrets to vault.yml..."

        # Encrypt the vault file
        ansible-vault encrypt group_vars/all/vault.yml
        chmod 600 group_vars/all/vault.yml
        echo "✓ Vault file encrypted and secured (permissions: 600)"
    else
        echo "⚠️  Warning: vault.yml.example not found. You'll need to create vault.yml manually."
    fi
fi

# Verify no sensitive files are staged for git
echo ""
echo "Checking for accidentally staged sensitive files..."

# Check for sensitive files in staging, excluding encrypted vault.yml
STAGED_SENSITIVE=$(git status --porcelain | grep -E '(\.vault_pass|password|secret|token|\.key$|\.pem$)' || true)

# Check for unencrypted vault.yml (should start with $ANSIBLE_VAULT if encrypted)
if git status --porcelain | grep -q 'vault\.yml$'; then
    for vault_file in $(find . -name "vault.yml" 2>/dev/null); do
        if [ -f "$vault_file" ]; then
            if ! head -1 "$vault_file" | grep -q '\$ANSIBLE_VAULT'; then
                STAGED_SENSITIVE="${STAGED_SENSITIVE}\nUnencrypted: $vault_file"
            fi
        fi
    done
fi

if [ -n "$STAGED_SENSITIVE" ]; then
    echo "⚠️  WARNING: Sensitive files detected!"
    echo "$STAGED_SENSITIVE"
    echo "Please review 'git status' and ensure files are encrypted or excluded."
else
    echo "✓ No sensitive files detected in git staging"
fi

echo ""
echo "=================================="
echo "Bootstrap Complete!"
echo "=================================="
echo ""
echo "Security Checklist:"
echo "✓ .vault_pass created (600 permissions)"
echo "✓ vault.yml encrypted (600 permissions)"
echo "✓ Sensitive files protected by .gitignore"
echo ""
echo "Next steps:"
echo "1. Review inventory/hosts.yml"
echo "2. Run: just bootstrap"
echo "3. Run: just run"
echo ""
echo "Security reminders:"
echo "- Never commit .vault_pass to git"
echo "- Only commit vault.yml.example (not vault.yml)"
echo "- Run 'just -f justfiles/security check-secrets' before pushing to git"
echo ""
