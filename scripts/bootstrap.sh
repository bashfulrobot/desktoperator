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
sudo apt-get install -y python3 python3-pip git curl

# Install Ansible and ansible-lint via pip
echo "Installing Ansible and ansible-lint..."
pip3 install --user ansible ansible-lint

# Ensure pip bin directory is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install 1Password CLI for vault password retrieval
echo "Installing 1Password CLI..."
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
sudo apt-get install -y 1password-cli restic

# Install autorestic
echo "Installing autorestic..."
wget -qO - https://raw.githubusercontent.com/cupcakearmy/autorestic/master/install.sh | bash
sudo mv ./autorestic /usr/local/bin/autorestic
sudo chmod +x /usr/local/bin/autorestic

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

# Retrieve vault password from 1Password
echo ""
echo "Retrieving vault password from 1Password..."
echo "You will need to authenticate to 1Password CLI."
echo ""

# Sign in to 1Password (user will be prompted)
eval $(op signin)

# Retrieve vault password and save to .vault_pass
echo "Retrieving vault password..."
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

# Create vault.yml if it doesn't exist
if [ ! -f "group_vars/all/vault.yml" ]; then
    echo ""
    echo "Creating initial vault file..."
    cp group_vars/all/vault.yml.example group_vars/all/vault.yml

    echo "Please edit group_vars/all/vault.yml with your actual secrets, then we'll encrypt it."
    read -p "Press Enter when you've added your secrets to vault.yml..."

    # Encrypt the vault file
    ansible-vault encrypt group_vars/all/vault.yml
    chmod 600 group_vars/all/vault.yml
    echo "✓ Vault file encrypted and secured (permissions: 600)"
else
    echo "✓ Vault file already exists"
fi

# Verify no sensitive files are staged for git
echo ""
echo "Checking for accidentally staged sensitive files..."
git status --porcelain | grep -E '(vault\.yml$|\.vault_pass|password|secret|token|\.key$|\.pem$)' && {
    echo "⚠️  WARNING: Sensitive files detected in git staging area!"
    echo "Please review 'git status' and unstage any sensitive files."
} || {
    echo "✓ No sensitive files detected in git staging"
}

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
